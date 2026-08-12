public with sharing class OpportunityAutoCloseService {

    private static final String LOG_PREFIX = 'OpportunityAutoClose: ';
    private static final String CLOSED_STAGE = 'Contract';

    private static final String OUTCOME_CLOSED =
        'Opportunity Closed';

    private static final String OUTCOME_NO_MATCH =
        'No Matching Opportunity';

    private static final String OUTCOME_ALREADY_CLOSED =
        'Opportunity Already Closed';


    public class PaidInvoiceInfo {
        public Id invoiceId;
        public Id paymentActivityId;
        public Id paymentId;
        public Datetime paymentDate;

        public PaidInvoiceInfo(
            Id invoiceId,
            Id paymentActivityId,
            Id paymentId,
            Datetime paymentDate
        ) {
            this.invoiceId = invoiceId;
            this.paymentActivityId = paymentActivityId;
            this.paymentId = paymentId;
            this.paymentDate = paymentDate;
        }
    }


    public static void processPaidInvoices(Set<Id> invoiceIds) {
        if (invoiceIds == null || invoiceIds.isEmpty()) {

            return;
        }

        System.debug(
            LoggingLevel.INFO,
            LOG_PREFIX +
            'Processing ' + invoiceIds.size() + ' paid invoice(s).'
        );

        Map<Id, PaidInvoiceInfo> paidInvoiceInfoByInvoiceId =
            new Map<Id, PaidInvoiceInfo>();

        /*
         * Find the most recently created Payment Activity
         * applied to each newly paid invoice.
         */
        for (fw1__Payment_Activity__c activity : [
            SELECT Id,
                   fw1__Invoice__c,
                   fw1__Payment__c,
                   fw1__Transaction_Date__c,
                   CreatedDate
            FROM fw1__Payment_Activity__c
            WHERE fw1__Invoice__c IN :invoiceIds
              AND fw1__Applied_To_Invoice__c = true
            ORDER BY CreatedDate DESC
        ]) {
            if (
                activity.fw1__Invoice__c == null ||
                activity.fw1__Transaction_Date__c == null
            ) {
                continue;
            }

            /*
             * Results are newest first, so keep only the first
             * Payment Activity encountered for each invoice.
             */
            if (!paidInvoiceInfoByInvoiceId.containsKey(
                activity.fw1__Invoice__c
            )) {
                PaidInvoiceInfo info = new PaidInvoiceInfo(
                    activity.fw1__Invoice__c,
                    activity.Id,
                    activity.fw1__Payment__c,
                    activity.fw1__Transaction_Date__c
                );

                paidInvoiceInfoByInvoiceId.put(
                    activity.fw1__Invoice__c,
                    info
                );


            }
        }

        if (paidInvoiceInfoByInvoiceId.isEmpty()) {

            return;
        }

        /*
         * Query all matching Opportunities, including already-closed
         * Opportunities, so every outcome can be audited.
         */
        List<Opportunity> matchingOpportunities = [
            SELECT Id,
                   Name,
                   StageName,
                   CloseDate,
                   IsClosed,
                   AgreementInvoice__c
            FROM Opportunity
            WHERE AgreementInvoice__c
                IN :paidInvoiceInfoByInvoiceId.keySet()
        ];


        Map<Id, List<Opportunity>> opportunitiesByInvoiceId =
            new Map<Id, List<Opportunity>>();

        for (Opportunity opportunity : matchingOpportunities) {
            Id invoiceId = opportunity.AgreementInvoice__c;

            if (!opportunitiesByInvoiceId.containsKey(invoiceId)) {
                opportunitiesByInvoiceId.put(
                    invoiceId,
                    new List<Opportunity>()
                );
            }

            opportunitiesByInvoiceId
                .get(invoiceId)
                .add(opportunity);
        }

        List<Opportunity> opportunitiesToClose =
            new List<Opportunity>();

        List<Opportunity_Auto_Close_Log__c> auditLogs =
            new List<Opportunity_Auto_Close_Log__c>();

        /*
         * Evaluate the outcome for every paid invoice.
         */
        for (Id invoiceId : paidInvoiceInfoByInvoiceId.keySet()) {
            PaidInvoiceInfo info =
                paidInvoiceInfoByInvoiceId.get(invoiceId);

            List<Opportunity> opportunities =
                opportunitiesByInvoiceId.get(invoiceId);

            /*
             * Paid invoice has no matching Opportunity.
             */
            if (opportunities == null || opportunities.isEmpty()) {
                auditLogs.add(
                    new Opportunity_Auto_Close_Log__c(
                        Invoice__c = invoiceId,
                        Payment_Activity__c = info.paymentActivityId,
                        Payment__c = info.paymentId,
                        Payment_Date__c = info.paymentDate,
                        Outcome__c = OUTCOME_NO_MATCH,
                        Result__c =
                            'No Opportunity found with AgreementInvoice__c ' +
                            'matching the paid invoice.'
                    )
                );

                continue;
            }

            /*
             * More than one Opportunity could theoretically reference
             * the same invoice, so evaluate each one independently.
             */
            for (Opportunity opportunity : opportunities) {

                /*
                 * Matching Opportunity already closed.
                 */
                if (opportunity.IsClosed) {
                    auditLogs.add(
                        new Opportunity_Auto_Close_Log__c(
                            Invoice__c = invoiceId,
                            Payment_Activity__c =
                                info.paymentActivityId,
                            Payment__c = info.paymentId,
                            Opportunity__c = opportunity.Id,
                            Payment_Date__c = info.paymentDate,
                            Outcome__c =
                                OUTCOME_ALREADY_CLOSED,
                            Previous_Stage__c =
                                opportunity.StageName,
                            Previous_Close_Date__c =
                                opportunity.CloseDate,
                            Result__c =
                                'Matching Opportunity was already closed.'
                        )
                    );


                    continue;
                }

                /*
                 * Matching open Opportunity will be closed.
                 */
                String previousStage =
                    opportunity.StageName;

                Date previousCloseDate =
                    opportunity.CloseDate;

                opportunity.StageName =
                    CLOSED_STAGE;

                opportunity.CloseDate =
                    info.paymentDate.date();

                opportunitiesToClose.add(opportunity);

                auditLogs.add(
                    new Opportunity_Auto_Close_Log__c(
                        Invoice__c = invoiceId,
                        Payment_Activity__c =
                            info.paymentActivityId,
                        Payment__c = info.paymentId,
                        Opportunity__c = opportunity.Id,
                        Payment_Date__c = info.paymentDate,
                        Outcome__c = OUTCOME_CLOSED,
                        Previous_Stage__c =
                            previousStage,
                        New_Stage__c =
                            CLOSED_STAGE,
                        Previous_Close_Date__c =
                            previousCloseDate,
                        New_Close_Date__c =
                            info.paymentDate.date(),
                        Result__c =
                            'Opportunity closed automatically when ' +
                            'agreement invoice was paid.'
                    )
                );

            }
        }

        /*
         * Perform one bulk Opportunity update.
         */
        if (!opportunitiesToClose.isEmpty()) {

            update opportunitiesToClose;
        }

        /*
         * Persist the audit trail.
         */
        if (!auditLogs.isEmpty()) {


            insert auditLogs;
        }

        System.debug(
            LoggingLevel.INFO,
            LOG_PREFIX +
            'Paid invoice processing completed.'
        );
    }
}
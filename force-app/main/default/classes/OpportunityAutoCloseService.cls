public with sharing class OpportunityAutoCloseService {

    private static final String LOG_PREFIX = 'OpportunityAutoClose: ';
    private static final String CLOSED_STAGE = 'Contract';


    public class PaidInvoiceInfo {
        public Id invoiceId;
        public Id paymentId;
        public Datetime paymentDate;

        public PaidInvoiceInfo(
            Id invoiceId,
            Id paymentId,
            Datetime paymentDate
        ) {
            this.invoiceId = invoiceId;
            this.paymentId = paymentId;
            this.paymentDate = paymentDate;
        }
    }


    public static void processPaidInvoices(Set<Id> invoiceIds) {
        if (invoiceIds == null || invoiceIds.isEmpty()) {
            System.debug(
                LoggingLevel.INFO,
                LOG_PREFIX + 'No paid invoice IDs supplied.'
            );
            return;
        }

        System.debug(
            LoggingLevel.INFO,
            LOG_PREFIX +
            'Processing ' + invoiceIds.size() + ' paid invoice(s).'
        );

        Map<Id, PaidInvoiceInfo> paidInvoiceInfoByInvoiceId =
            new Map<Id, PaidInvoiceInfo>();

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

            // Results are ordered newest first, so retain only
            // the first Payment Activity encountered for each invoice.
            if (!paidInvoiceInfoByInvoiceId.containsKey(
                activity.fw1__Invoice__c
            )) {
                PaidInvoiceInfo info = new PaidInvoiceInfo(
                    activity.fw1__Invoice__c,
                    activity.fw1__Payment__c,
                    activity.fw1__Transaction_Date__c
                );

                paidInvoiceInfoByInvoiceId.put(
                    activity.fw1__Invoice__c,
                    info
                );

                System.debug(
                    LoggingLevel.INFO,
                    LOG_PREFIX +
                    'Paid Invoice=' + info.invoiceId +
                    ', Payment=' + info.paymentId +
                    ', PaymentDate=' + info.paymentDate
                );
            }
        }

        if (paidInvoiceInfoByInvoiceId.isEmpty()) {
            System.debug(
                LoggingLevel.INFO,
                LOG_PREFIX +
                'No applied Payment Activity records found for paid invoices.'
            );
            return;
        }

        List<Opportunity> openOpportunities = [
            SELECT Id,
                   Name,
                   StageName,
                   CloseDate,
                   AgreementInvoice__c
            FROM Opportunity
            WHERE AgreementInvoice__c IN :paidInvoiceInfoByInvoiceId.keySet()
              AND IsClosed = false
        ];

        System.debug(
            LoggingLevel.INFO,
            LOG_PREFIX +
            'Open Opportunities found: ' + openOpportunities.size()
        );

        if (openOpportunities.isEmpty()) {
            return;
        }

        List<Opportunity> opportunitiesToClose =
            new List<Opportunity>();

        for (Opportunity opportunity : openOpportunities) {

            PaidInvoiceInfo paidInvoiceInfo =
                paidInvoiceInfoByInvoiceId.get(
                    opportunity.AgreementInvoice__c
                );

            if (paidInvoiceInfo == null) {
                System.debug(
                    LoggingLevel.INFO,
                    LOG_PREFIX +
                    'Skipping Opportunity=' + opportunity.Id +
                    ' because no payment information was found.'
                );
                continue;
            }

            System.debug(
                LoggingLevel.INFO,
                LOG_PREFIX +
                'Closing Opportunity=' + opportunity.Id +
                ', Name=' + opportunity.Name +
                ', CurrentStage=' + opportunity.StageName +
                ', CurrentCloseDate=' + opportunity.CloseDate +
                ', Invoice=' + opportunity.AgreementInvoice__c +
                ', NewStage=' + CLOSED_STAGE +
                ', NewCloseDate=' + paidInvoiceInfo.paymentDate.date()
            );

            opportunity.StageName = CLOSED_STAGE;
            opportunity.CloseDate =
                paidInvoiceInfo.paymentDate.date();

            opportunitiesToClose.add(opportunity);
        }

        if (opportunitiesToClose.isEmpty()) {
            System.debug(
                LoggingLevel.INFO,
                LOG_PREFIX +
                'No Opportunities require updating.'
            );
            return;
        }

        System.debug(
            LoggingLevel.INFO,
            LOG_PREFIX +
            'Updating ' +
            opportunitiesToClose.size() +
            ' Opportunity record(s).'
        );

        update opportunitiesToClose;

        System.debug(
            LoggingLevel.INFO,
            LOG_PREFIX +
            'Opportunity updates completed successfully.'
        );
    }
}
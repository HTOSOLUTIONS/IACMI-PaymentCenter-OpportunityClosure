public with sharing class OpportunityAutoCloseService {

    private static final String LOG_PREFIX = 'OpportunityAutoClose: ';

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

            // Because results are ordered newest first, keep the
            // first Payment Activity found for each invoice.
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

        // Next step:
        // find open Opportunities where
        // AgreementInvoice__c IN :paidInvoiceInfoByInvoiceId.keySet()
        // and set CloseDate from the corresponding paymentDate.
    }
}
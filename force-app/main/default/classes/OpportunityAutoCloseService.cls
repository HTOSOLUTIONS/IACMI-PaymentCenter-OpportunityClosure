
public with sharing class OpportunityAutoCloseService {

    public class PaymentInfo {
        public Id paymentId;
        public Id invoiceId;
        public Datetime paymentDate;

        public PaymentInfo(
            Id paymentId,
            Id invoiceId,
            Datetime paymentDate
        ) {
            this.paymentId = paymentId;
            this.invoiceId = invoiceId;
            this.paymentDate = paymentDate;
        }
    }


    public static void processPayments(Set<Id> paymentIds) {
        if (paymentIds == null || paymentIds.isEmpty()) {
            return;
        }

        List<PaymentInfo> paymentInfos = new List<PaymentInfo>();
        Set<Id> invoiceIds = new Set<Id>();

        for (fw1__Payment__c payment : [
            SELECT Id,
                   fw1__Invoice__c,
                   fw1__Payment_Date__c
            FROM fw1__Payment__c
            WHERE Id IN :paymentIds
        ]) {
            if (
                payment.fw1__Invoice__c != null &&
                payment.fw1__Payment_Date__c != null
            ) {
                paymentInfos.add(
                    new PaymentInfo(
                        payment.Id,
                        payment.fw1__Invoice__c,
                        payment.fw1__Payment_Date__c
                    )
                );

                invoiceIds.add(payment.fw1__Invoice__c);
            }
        }

        if (invoiceIds.isEmpty()) {
            return;
        }

        Set<Id> paidInvoiceIds = new Set<Id>();

        for (fw1__Invoice__c invoice : [
            SELECT Id,
                   fw1__Status_Sys__c,
                   fw1__Total_Paid_Amount__c
            FROM fw1__Invoice__c
            WHERE Id IN :invoiceIds
        ]) {
            if (invoice.fw1__Status_Sys__c == 'Paid') {
                paidInvoiceIds.add(invoice.Id);
            }
        }

        if (paidInvoiceIds.isEmpty()) {
            return;
        }

        // Next step:
        // find open Opportunities linked through AgreementInvoice__c.
    }
}


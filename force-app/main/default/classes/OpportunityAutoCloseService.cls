
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
            }
        }

        // Next step:
        // determine whether each related invoice is paid in full.
    }
}


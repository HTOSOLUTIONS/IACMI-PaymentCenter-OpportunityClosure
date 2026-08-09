
public with sharing class OpportunityAutoCloseTriggerHelper {

    public static void processPayments(
        List<fw1__Payment__c> payments,
        Map<Id, fw1__Payment__c> oldMap
    ) {
        Set<Id> paymentIds = new Set<Id>();

        if (payments == null) {
            return;
        }

        for (fw1__Payment__c payment : payments) {
            if (payment.Id != null) {
                paymentIds.add(payment.Id);
            }
        }

        if (!paymentIds.isEmpty()) {
            OpportunityAutoCloseService.processPayments(paymentIds);
        }
    }
}


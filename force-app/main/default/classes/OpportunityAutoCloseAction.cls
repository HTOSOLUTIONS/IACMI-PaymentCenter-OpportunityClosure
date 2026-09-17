public with sharing class OpportunityAutoCloseAction {

    @AuraEnabled
    public static void processPayment(Id paymentId) {
        if (paymentId == null) {
            throw new AuraHandledException(
                'A Payment record ID is required.'
            );
        }

        OpportunityAutoCloseService.processPayment(paymentId);
    }
}
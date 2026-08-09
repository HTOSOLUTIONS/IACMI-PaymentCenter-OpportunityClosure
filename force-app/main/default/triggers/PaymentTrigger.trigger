trigger PaymentTrigger on fw1__Payment__c (
    after insert,
    after update
) {
    OpportunityAutoCloseTriggerHelper.processPayments(
        Trigger.new,
        Trigger.oldMap
    );
}


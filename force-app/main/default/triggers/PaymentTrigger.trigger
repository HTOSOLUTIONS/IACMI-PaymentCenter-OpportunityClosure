trigger PaymentTrigger on fw1__Payment__c (
    after insert,
    after update
) {


    if (Trigger.isInsert) {
        System.debug(
            LoggingLevel.INFO,
            'OpportunityAutoClose: AFTER INSERT'
        );
    }

    if (Trigger.isUpdate) {
        System.debug(
            LoggingLevel.INFO,
            'OpportunityAutoClose: AFTER UPDATE'
        );
    }


}


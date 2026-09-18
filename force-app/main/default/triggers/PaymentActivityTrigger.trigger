trigger PaymentActivityTrigger on fw1__Payment_Activity__c
    (after insert, after update) {

    final String LOG_PREFIX = '[PaymentActivityTrigger] ';

    System.debug(
        LoggingLevel.INFO,
        LOG_PREFIX +
        'Started. Operation=' + Trigger.operationType +
        ', RecordCount=' + Trigger.new.size()
    );

    Set<Id> invoiceIds = new Set<Id>();

    for (fw1__Payment_Activity__c activity : Trigger.new) {

        if (Trigger.isInsert) {
            if (activity.fw1__Invoice__c != null) {
                invoiceIds.add(activity.fw1__Invoice__c);

                System.debug(
                    LoggingLevel.INFO,
                    LOG_PREFIX +
                    'Insert candidate. PaymentActivity=' + activity.Id +
                    ', Invoice=' + activity.fw1__Invoice__c +
                    ', AppliedToInvoice=' +
                    activity.fw1__Applied_To_Invoice__c
                );
            }

            continue;
        }

        fw1__Payment_Activity__c oldActivity =
            Trigger.oldMap.get(activity.Id);

        Boolean invoiceChanged =
            activity.fw1__Invoice__c != oldActivity.fw1__Invoice__c;

        Boolean appliedChanged =
            activity.fw1__Applied_To_Invoice__c !=
            oldActivity.fw1__Applied_To_Invoice__c;

        if (invoiceChanged || appliedChanged) {
            System.debug(
                LoggingLevel.INFO,
                LOG_PREFIX +
                'Update candidate. PaymentActivity=' + activity.Id +
                ', InvoiceChanged=' + invoiceChanged +
                ', AppliedChanged=' + appliedChanged +
                ', OldInvoice=' + oldActivity.fw1__Invoice__c +
                ', NewInvoice=' + activity.fw1__Invoice__c +
                ', OldApplied=' +
                oldActivity.fw1__Applied_To_Invoice__c +
                ', NewApplied=' +
                activity.fw1__Applied_To_Invoice__c
            );

            if (oldActivity.fw1__Invoice__c != null) {
                invoiceIds.add(oldActivity.fw1__Invoice__c);
            }

            if (activity.fw1__Invoice__c != null) {
                invoiceIds.add(activity.fw1__Invoice__c);
            }
        }
    }

    System.debug(
        LoggingLevel.INFO,
        LOG_PREFIX +
        'Invoice IDs collected=' + invoiceIds
    );

    if (!invoiceIds.isEmpty()) {
        System.debug(
            LoggingLevel.INFO,
            LOG_PREFIX +
            'Calling OpportunityAutoCloseService.processPaidInvoices().'
        );

        OpportunityAutoCloseService.processPaidInvoices(invoiceIds);
    } else {
        System.debug(
            LoggingLevel.INFO,
            LOG_PREFIX +
            'No qualifying invoice changes detected. Service not called.'
        );
    }

    System.debug(
        LoggingLevel.INFO,
        LOG_PREFIX + 'Completed.'
    );
}
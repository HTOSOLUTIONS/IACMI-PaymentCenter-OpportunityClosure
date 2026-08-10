trigger InvoiceTrigger on fw1__Invoice__c (
    after update
) {
    List<fw1__Invoice__c> paidInvoices = new List<fw1__Invoice__c>();

    for (fw1__Invoice__c invoice : Trigger.new) {
        fw1__Invoice__c oldInvoice = Trigger.oldMap.get(invoice.Id);

        if (
            oldInvoice.fw1__Status_Sys__c != 'Paid' &&
            invoice.fw1__Status_Sys__c == 'Paid'
        ) {
            paidInvoices.add(invoice);
        }
    }

    if (!paidInvoices.isEmpty()) {
        OpportunityAutoCloseTriggerHelper.processPaidInvoices(paidInvoices);
    }
}
public with sharing class OpportunityAutoCloseTriggerHelper {

    public static void processPaidInvoices(
        List<fw1__Invoice__c> invoices
    ) {
        Set<Id> invoiceIds = new Set<Id>();

        for (fw1__Invoice__c invoice : invoices) {
            invoiceIds.add(invoice.Id);
        }

        if (!invoiceIds.isEmpty()) {
            OpportunityAutoCloseService.processPaidInvoices(invoiceIds);
        }
    }
}
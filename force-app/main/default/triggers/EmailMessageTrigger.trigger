trigger EmailMessageTrigger on EmailMessage (
    after insert,
    after update,
    after delete,
    after undelete
) {
    Set<Id> oppIds = new Set<Id>();

    if (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete) {
        oppIds.addAll(ActivityRollupTriggerHelper.collectOpportunityIdsFromEmails(Trigger.new));
    }

    if (Trigger.isUpdate || Trigger.isDelete) {
        oppIds.addAll(ActivityRollupTriggerHelper.collectOpportunityIdsFromEmails(Trigger.old));
    }

    if (!oppIds.isEmpty()) {
        ActivityRollupService.recalculateForOpportunities(oppIds);
    }
}
trigger TaskTrigger on Task (
    after insert,
    after update,
    after delete,
    after undelete
) {
    Set<Id> oppIds = new Set<Id>();

    if (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete) {
        oppIds.addAll(ActivityRollupTriggerHelper.collectOpportunityIdsFromTasks(Trigger.new));
    }

    if (Trigger.isUpdate || Trigger.isDelete) {
        oppIds.addAll(ActivityRollupTriggerHelper.collectOpportunityIdsFromTasks(Trigger.old));
    }

    if (!oppIds.isEmpty()) {
        ActivityRollupService.recalculateForOpportunities(oppIds);
    }
}
public with sharing class ActivityRollupTriggerHelper {

    public static Set<Id> collectOpportunityIdsFromTasks(List<Task> tasks) {
        Set<Id> oppIds = new Set<Id>();

        if (tasks == null) {
            return oppIds;
        }

        for (Task t : tasks) {
            if (t.WhatId != null && String.valueOf(t.WhatId).startsWith('006')) {
                oppIds.add(t.WhatId);
            }
        }

        return oppIds;
    }

    public static Set<Id> collectOpportunityIdsFromEmails(List<EmailMessage> emails) {
        Set<Id> oppIds = new Set<Id>();

        if (emails == null) {
            return oppIds;
        }

        for (EmailMessage e : emails) {
            if (e.RelatedToId != null && String.valueOf(e.RelatedToId).startsWith('006')) {
                oppIds.add(e.RelatedToId);
            }
        }

        return oppIds;
    }
}
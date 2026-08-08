public with sharing class ActivityRollupService {

    public class ActivityCandidate {
        public Id opportunityId;
        public Id sourceId;
        public String activityType;
        public String subject;
        public String notes;
        public Datetime activityDateTime;
    }

    public static void recalculateForOpportunities(Set<Id> opportunityIds) {
        if (opportunityIds == null || opportunityIds.isEmpty()) {
            return;
        }

        Map<Id, ActivityCandidate> latestByOppId = new Map<Id, ActivityCandidate>();

        collectTasks(opportunityIds, latestByOppId);
        collectEmailMessages(opportunityIds, latestByOppId);

        List<Opportunity> updates = new List<Opportunity>();

        for (Id oppId : opportunityIds) {
            ActivityCandidate latest = latestByOppId.get(oppId);

            Opportunity opp = new Opportunity(Id = oppId);

            if (latest == null) {
                opp.Last_Activity_Type__c = null;
                opp.Last_Activity_Subject__c = null;
                opp.Last_Activity_Notes__c = null;
                opp.Last_Activity_DateTime__c = null;
            } else {
                opp.Last_Activity_Type__c = latest.activityType;
                opp.Last_Activity_Subject__c = truncateText(latest.subject, 255);
                opp.Last_Activity_Notes__c = latest.notes;
                opp.Last_Activity_DateTime__c = latest.activityDateTime;
            }

            updates.add(opp);
        }

        if (!updates.isEmpty()) {
            update updates;
        }
    }

    private static void collectTasks(
        Set<Id> opportunityIds,
        Map<Id, ActivityCandidate> latestByOppId
    ) {
        List<Task> tasks = [
            SELECT Id,
                   WhatId,
                   Subject,
                   Description,
                   TaskSubtype,
                   Status,
                   ActivityDate,
                   CompletedDateTime,
                   CreatedDate
            FROM Task
            WHERE WhatId IN :opportunityIds
            AND IsDeleted = false
            AND Status = 'Completed'
        ];

        for (Task t : tasks) {
            ActivityCandidate c = new ActivityCandidate();
            c.opportunityId = t.WhatId;
            c.sourceId = t.Id;
            c.activityType = normalizeTaskType(t);
            c.subject = t.Subject;
            c.notes = t.Description;
            c.activityDateTime = getTaskDateTime(t);

            considerCandidate(latestByOppId, c);
        }
    }

    private static void collectEmailMessages(
        Set<Id> opportunityIds,
        Map<Id, ActivityCandidate> latestByOppId
    ) {
        List<EmailMessage> emails = [
            SELECT Id,
                   RelatedToId,
                   Subject,
                   TextBody,
                   HtmlBody,
                   MessageDate,
                   CreatedDate
            FROM EmailMessage
            WHERE RelatedToId IN :opportunityIds
            AND IsDeleted = false
        ];

        for (EmailMessage e : emails) {
            ActivityCandidate c = new ActivityCandidate();
            c.opportunityId = e.RelatedToId;
            c.sourceId = e.Id;
            c.activityType = 'Email';
            c.subject = e.Subject;
            c.notes = String.isNotBlank(e.TextBody) ? e.TextBody : stripHtml(e.HtmlBody);
            c.activityDateTime = e.MessageDate != null ? e.MessageDate : e.CreatedDate;

            considerCandidate(latestByOppId, c);
        }
    }

    private static void considerCandidate(
        Map<Id, ActivityCandidate> latestByOppId,
        ActivityCandidate candidate
    ) {
        if (candidate == null || candidate.opportunityId == null || candidate.activityDateTime == null) {
            return;
        }

        ActivityCandidate existing = latestByOppId.get(candidate.opportunityId);

        if (existing == null || candidate.activityDateTime > existing.activityDateTime) {
            latestByOppId.put(candidate.opportunityId, candidate);
        }
    }

    private static Datetime getTaskDateTime(Task t) {
        if (t.CompletedDateTime != null) {
            return t.CompletedDateTime;
        }

        if (t.ActivityDate != null) {
            return Datetime.newInstance(t.ActivityDate, Time.newInstance(0, 0, 0, 0));
        }

        return t.CreatedDate;
    }

    private static String normalizeTaskType(Task t) {
        if (String.isNotBlank(t.TaskSubtype)) {
            return t.TaskSubtype;
        }

        if (t.Subject != null && t.Subject.toLowerCase().startsWith('email')) {
            return 'Email';
        }

        return 'Task';
    }

    private static String truncateText(String value, Integer maxLength) {
        if (value == null || value.length() <= maxLength) {
            return value;
        }

        return value.substring(0, maxLength);
    }

    private static String stripHtml(String html) {
        if (String.isBlank(html)) {
            return null;
        }

        return html.replaceAll('<[^>]+>', ' ').replaceAll('\\s+', ' ').trim();
    }
}
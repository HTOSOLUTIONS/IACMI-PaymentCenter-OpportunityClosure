@IsTest
public class ActivityRollupTestDataFactory {

    public class SeedResult {
        public Opportunity opportunity;
        public Task task;
        public EmailMessage email;
    }

    public static Opportunity createOpportunity() {
        Opportunity opp = new Opportunity(
            Name = 'Activity Rollup Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;
        return opp;
    }

    public static Task createCompletedTask(Id opportunityId) {
        Task t = new Task(
            WhatId = opportunityId,
            Subject = 'Completed follow-up',
            Description = 'Task created by ActivityRollupTestDataFactory',
            Status = 'Completed',
            ActivityDate = Date.today()
        );
        insert t;
        return t;
    }

    public static EmailMessage createEmailMessage(Id opportunityId) {
        EmailMessage email = new EmailMessage(
            RelatedToId = opportunityId,
            Subject = 'Activity rollup test email',
            TextBody = 'Email created by ActivityRollupTestDataFactory',
            FromAddress = 'from@example.com',
            ToAddress = 'to@example.com',
            Incoming = false,
            Status = '3',
            MessageDate = System.now()
        );
        insert email;
        return email;
    }

    public static SeedResult seedOpportunityWithTaskAndEmail() {
        SeedResult result = new SeedResult();
        result.opportunity = createOpportunity();
        result.task = createCompletedTask(result.opportunity.Id);
        result.email = createEmailMessage(result.opportunity.Id);
        return result;
    }
}
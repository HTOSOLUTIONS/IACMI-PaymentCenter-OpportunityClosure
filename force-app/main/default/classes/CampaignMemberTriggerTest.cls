@IsTest
private class CampaignMemberTriggerTest {

    @IsTest
    static void testAfterInsert_enqueuesQueueable() {

        // Seed data required for status->package->course mapping + session factory
        CanvasEnrollmentTestDataFactory.SeedResult seed = CanvasEnrollmentTestDataFactory.seed();

        // Mock all HTTP callouts used anywhere in the flow (OAuth/user/enroll)
        // Uses your existing mock factory class you pasted earlier in prior refactor chats.
        CanvasMockAPIResponseFactory mock = new CanvasMockAPIResponseFactory();
        mock.ExistingUser = true;
        mock.ExistingEnrollments = false;
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();

        CampaignMember cm = new CampaignMember(
            LeadId = seed.lead.Id,
            CampaignId = seed.campaign.Id,
            Status = 'Course Package 1'
        );
        insert cm;

        Test.stopTest();

        // Assert the Queueable ran (AsyncApexJob created and completed)
        // Note: During tests, stopTest() forces async jobs to complete.
        List<AsyncApexJob> jobs = [
            SELECT Id, Status, JobType, ApexClassId
            FROM AsyncApexJob
            WHERE JobType = 'Queueable'
            ORDER BY CreatedDate DESC
            LIMIT 5
        ];

        System.assert(!jobs.isEmpty(), 'Expected at least one Queueable job to be created.');

        // Optional: ensure at least one job completed successfully
        Boolean anyCompleted = false;
        for (AsyncApexJob j : jobs) {
            if (j.Status == 'Completed') {
                anyCompleted = true;
                break;
            }
        }
        System.assert(anyCompleted, 'Expected at least one Queueable job to complete.');
    }
}
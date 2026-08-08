@IsTest
private class CanvasEnrollmentQueueableTest {

    @IsTest
    static void testQueueable_runsEndToEnd() {

        CanvasEnrollmentTestDataFactory.SeedResult seed =
            CanvasEnrollmentTestDataFactory.seed();

        // Insert a CampaignMember (but we will enqueue manually, not rely on trigger)
        CampaignMember cm = new CampaignMember(
            LeadId = seed.lead.Id,
            CampaignId = seed.campaign.Id,
            Status = 'Course Package 1'
        );
        insert cm;

        // ------------------------------------------------------------
        // 🔍 ASSERT / VERIFY TEST INPUTS (CRITICAL)
        // ------------------------------------------------------------

        // 1) Make sure the package we expect actually exists
        System.assertEquals(
            1,
            [SELECT COUNT()
             FROM Canvas_Course_Package__c
             WHERE Package_Name__c = 'Course Package 1'],
            'Expected Canvas_Course_Package__c with Package_Name__c = Course Package 1'
        );

        // 2) Re-query the CampaignMember to see what Status was REALLY stored
        CampaignMember cmCheck = [
            SELECT Id, Status, LeadId
            FROM CampaignMember
            WHERE Id = :cm.Id
        ];

        System.debug(
            'TEST DEBUG: Stored CampaignMember.Status = [' + cmCheck.Status + ']'
        );

        System.assertEquals(
            'Course Package 1',
            cmCheck.Status,
            'CampaignMember.Status does not match expected value'
        );

        System.assertNotEquals(
            null,
            cmCheck.LeadId,
            'CampaignMember.LeadId should not be null'
        );

        // ------------------------------------------------------------
        // Mock HTTP callouts
        // ------------------------------------------------------------
        CanvasMockAPIResponseFactory mock = new CanvasMockAPIResponseFactory();
        mock.ExistingUser = true;
        mock.ExistingEnrollments = false;
        Test.setMock(HttpCalloutMock.class, mock);

        // ------------------------------------------------------------
        // Execute Queueable
        // ------------------------------------------------------------
        Test.startTest();

        System.enqueueJob(
            new CanvasEnrollmentQueueable(new List<Id>{ cm.Id })
        );

        Test.stopTest();

        // ------------------------------------------------------------
        // Validate the job exists and completed
        // ------------------------------------------------------------
        List<AsyncApexJob> jobs = [
            SELECT Id, Status, JobType
            FROM AsyncApexJob
            WHERE JobType = 'Queueable'
            ORDER BY CreatedDate DESC
            LIMIT 5
        ];

        System.assert(
            !jobs.isEmpty(),
            'Expected Queueable job to be created.'
        );

        System.assertEquals(
            'Completed',
            jobs[0].Status,
            'Expected most recent Queueable job to complete.'
        );
    }

    // ------------------------------------------------------------
    // Test handling of nonexistent Course Package
    // CanvasEnrollmentQueueable should handle this gracefully
    // ------------------------------------------------------------
    @IsTest
    static void testNoCoursePackage() {

        String packageName = 'Sent';

        CanvasEnrollmentTestDataFactory.SeedResult seed =
            CanvasEnrollmentTestDataFactory.seed();

        // Insert a CampaignMember (but we will enqueue manually, not rely on trigger)
        CampaignMember cm = new CampaignMember(
            LeadId = seed.lead.Id,
            CampaignId = seed.campaign.Id,
            Status = packageName
        );
        insert cm;

        // ------------------------------------------------------------
        // 🔍 ASSERT / VERIFY TEST INPUTS (CRITICAL)
        // ------------------------------------------------------------

        // 1) Make sure the package we expect actually exists
        System.assertEquals(
            0,
            [SELECT COUNT()
             FROM Canvas_Course_Package__c
             WHERE Package_Name__c = :packageName],
            'Expected Canvas_Course_Package__c with Package_Name__c = ' + packageName + ' to NOT exist'
        );

        // 2) Re-query the CampaignMember to see what Status was REALLY stored
        CampaignMember cmCheck = [
            SELECT Id, Status, LeadId
            FROM CampaignMember
            WHERE Id = :cm.Id
        ];

        System.debug(
            'TEST DEBUG: Stored CampaignMember.Status = [' + cmCheck.Status + ']'
        );

        System.assertEquals(
            packageName,
            cmCheck.Status,
            'CampaignMember.Status does not match expected value'
        );

        System.assertNotEquals(
            null,
            cmCheck.LeadId,
            'CampaignMember.LeadId should not be null'
        );

        // ------------------------------------------------------------
        // Mock HTTP callouts
        // ------------------------------------------------------------
        CanvasMockAPIResponseFactory mock = new CanvasMockAPIResponseFactory();
        mock.ExistingUser = true;
        mock.ExistingEnrollments = false;
        Test.setMock(HttpCalloutMock.class, mock);

        // ------------------------------------------------------------
        // Execute Queueable
        // ------------------------------------------------------------
        Test.startTest();

        System.enqueueJob(
            new CanvasEnrollmentQueueable(new List<Id>{ cm.Id })
        );

        Test.stopTest();

        // ------------------------------------------------------------
        // Validate the job exists and completed
        // ------------------------------------------------------------
        List<AsyncApexJob> jobs = [
            SELECT Id, Status, JobType
            FROM AsyncApexJob
            WHERE JobType = 'Queueable'
            ORDER BY CreatedDate DESC
            LIMIT 5
        ];

        System.assert(
            !jobs.isEmpty(),
            'Expected Queueable job to be created.'
        );

        System.assertEquals(
            'Completed',
            jobs[0].Status,
            'Expected most recent Queueable job to complete.'
        );
        
    }


}
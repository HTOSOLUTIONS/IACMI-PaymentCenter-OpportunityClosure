@IsTest

private class EnrollmentUtilityTest {

    @IsTest
    static void testExistingEnrollment() {

        CanvasEnrollmentTestDataFactory.SeedResult seed =
            CanvasEnrollmentTestDataFactory.seed();
        // ------------------------------------------------------------
        // Mock HTTP callouts
        // ------------------------------------------------------------
        CanvasMockAPIResponseFactory mock = new CanvasMockAPIResponseFactory();
        mock.ExistingUser = true;
        mock.ExistingEnrollments = true;
        Test.setMock(HttpCalloutMock.class, mock);

        // ------------------------------------------------------------
        // Execute Queueable
        // ------------------------------------------------------------
        Test.startTest();

        EnrollmentUtility enrollmentUtility = new EnrollmentUtility();

        Lead lead = [
            SELECT Id, Email, FirstName, LastName, Company, Name
            FROM Lead
            WHERE Id = :seed.lead.Id
        ];

        List<EnrollmentRequest> requests = new List<EnrollmentRequest>();
        EnrollmentRequest req = new EnrollmentRequest();
        req.LeadEnrolled = lead;
        requests.add(req);

        EnrollmentResults results = enrollmentUtility.EnrollLeads(seed.course, requests, 'Unit Test Existing Enrollment');

        System.assertNotEquals(null, results);
        System.assertEquals(1, results.ProcessedRequests.size());


        Test.stopTest();

    }
}
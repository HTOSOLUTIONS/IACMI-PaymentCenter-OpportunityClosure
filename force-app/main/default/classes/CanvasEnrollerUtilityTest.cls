@IsTest


private class CanvasEnrollerUtilityTest {

    @IsTest
    static void testNoExistingEnrollemnts() {

        CanvasEnrollmentTestDataFactory.SeedResult seed =
            CanvasEnrollmentTestDataFactory.seed();
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

        CanvasEnrollerUtility canvasEnrollerUtility = new CanvasEnrollerUtility();

        // string courseid, string loginemail, string username
        string courseid = seed.course.Canvas_ID__c;

        Lead lead = [
            SELECT Id, Email, FirstName, LastName, Company, Name
            FROM Lead
            WHERE Id = :seed.lead.Id
        ];

        string loginemail = lead.Email;
        string username = lead.Name;

        CanvasEnrollerResult result = canvasEnrollerUtility.EnrollUserinCourse(courseid, loginemail, username);

        System.assertNotEquals(null, result);
        System.assertEquals(courseid, result.CourseId);
        System.assertEquals(loginemail, result.LoginEmail);
        System.assertEquals(username, result.UserName);
        System.assertEquals(false, result.NewUser);

        Test.stopTest();

    }

    @IsTest
    static void testExistignEnrollent(){
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

        CanvasEnrollerUtility canvasEnrollerUtility = new CanvasEnrollerUtility();

        // string courseid, string loginemail, string username
        string courseid = seed.course.Canvas_ID__c;

        Lead lead = [
            SELECT Id, Email, FirstName, LastName, Company, Name
            FROM Lead
            WHERE Id = :seed.lead.Id
        ];

        string loginemail = lead.Email;
        string username = lead.Name;

        CanvasEnrollerResult result = canvasEnrollerUtility.EnrollUserinCourse(courseid, loginemail, username);

        System.assertNotEquals(null, result);
        System.assertEquals(courseid, result.CourseId);
        System.assertEquals(loginemail, result.LoginEmail);
        System.assertEquals(username, result.UserName);
        System.assertEquals(false, result.NewUser);

        Test.stopTest();
    }


    @IsTest
    static void testNewUser() {

        CanvasEnrollmentTestDataFactory.SeedResult seed =
            CanvasEnrollmentTestDataFactory.seed();
        // ------------------------------------------------------------
        // Mock HTTP callouts
        // ------------------------------------------------------------
        CanvasMockAPIResponseFactory mock = new CanvasMockAPIResponseFactory();
        mock.ExistingUser = false;
        mock.ExistingEnrollments = false;
        Test.setMock(HttpCalloutMock.class, mock);

        // ------------------------------------------------------------
        // Execute Queueable
        // ------------------------------------------------------------
        Test.startTest();

        CanvasEnrollerUtility canvasEnrollerUtility = new CanvasEnrollerUtility();

        // string courseid, string loginemail, string username
        string courseid = seed.course.Canvas_ID__c;

        Lead lead = [
            SELECT Id, Email, FirstName, LastName, Company, Name
            FROM Lead
            WHERE Id = :seed.lead.Id
        ];

        string loginemail = lead.Email;
        string username = lead.Name;

        CanvasEnrollerResult result = canvasEnrollerUtility.EnrollUserinCourse(courseid, loginemail, username);

        System.assertNotEquals(null, result);
        System.assertEquals(courseid, result.CourseId);
        System.assertEquals(loginemail, result.LoginEmail);
        System.assertEquals(username, result.UserName);
        System.assertEquals(true, result.NewUser);

        Test.stopTest();

    }

}
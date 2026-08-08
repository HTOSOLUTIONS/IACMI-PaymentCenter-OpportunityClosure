@isTest(seeAllData=false)
public class test_CanvasAPIUtility_Settings {

    @testSetup
    static void setup() {
        // Minimal settings record so constructor SOQL succeeds
        insert new Canvas_Settings__c(
            Canvas_Install_URL__c = 'https://example.instructure.com',
            API_Root_Endpoint__c  = '/api/v1',
            DefaultUserName__c    = 'testuser' // <-- your new field
        );

        // Minimal Canvas user so refreshCanvasUser() can pass its guards
        insert new Canvas_User__c(
            OwnerId   = UserInfo.getUserId(),
            Beta_Tag__c = 'TEST_REFRESH_TOKEN',
            Alpha_Tag__c = 'TEST_ACCESS_TOKEN'
        );
    }

    @isTest
    static void constructor_builds_root_endpoint_from_settings() {

        // Reuse your existing callout mocking approach
        CanvasMockAPIResponseFactory apiMock = new CanvasMockAPIResponseFactory();
        Test.setMock(HttpCalloutMock.class, apiMock);

        Test.startTest();
        CanvasAPIUtility api = new CanvasAPIUtility();
        Test.stopTest();

        System.assertNotEquals(
            null,
            api.rootEndPoint,
            'RootEndpoint should be populated from Canvas_Settings__c'
        );

        System.assert(
            api.rootEndPoint.contains('/api/v1'),
            'RootEndpoint should include API_Root_Endpoint__c'
        );
    }

    @isTest
    static void coverage_CanvasAPIUtility_methods() {

        // Use your mock so all callouts return 200 + JSON
        CanvasMockAPIResponseFactory apiMock = new CanvasMockAPIResponseFactory();
        apiMock.ExistingUser = true;
        apiMock.ExistingEnrollments = true;
        Test.setMock(HttpCalloutMock.class, apiMock);

        Test.startTest();

        CanvasAPIUtility api = new CanvasAPIUtility();

        // Cover simple getters/properties
        System.assertNotEquals(null, api.getRootEndPoint());
        System.assertEquals(api.getRootEndPoint(), api.rootEndPoint);
        System.assertEquals(api.getAPIToken(), api.accessToken);

        // Cover request builders
        HttpRequest r1 = api.getAuthorizedRequest();
        System.assertNotEquals(null, r1);

        System.assertNotEquals(null, api.getCoursesAPIRequest());
        System.assertNotEquals(null, api.getUserAPIRequest('test@example.com'));
        System.assertNotEquals(null, api.postCreateUserRequest('test@example.com', 'Test User'));
        System.assertNotEquals(null, api.getUserEnrollmentsRequest('123'));
        System.assertNotEquals(null, api.postEnrollUserRequest('456', '123'));

        // Cover callout methods (mock will respond)
        System.assertNotEquals(null, api.getCoursesJSON());
        System.assertNotEquals(null, api.getUserJSON('test@example.com'));
        System.assertNotEquals(null, api.getCreateUserJSON('test@example.com', 'Test User'));
        System.assertNotEquals(null, api.getUserEnrollmentsJSON('123'));
        System.assertNotEquals(null, api.getEnrollUserJSON('456', '123'));

        Test.stopTest();

        // (Optional) assert readiness if your constructor now sets both values
        // System.assert(api.IsReady, 'API utility should be ready when settings + token are available');
    }



}
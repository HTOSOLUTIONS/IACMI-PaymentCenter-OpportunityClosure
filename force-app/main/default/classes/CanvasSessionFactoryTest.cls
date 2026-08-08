@IsTest
private class CanvasSessionFactoryTest {

    private class OAuthRefreshMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);

            String body = '{'
                + '"access_token":"ACCESS_TOKEN_FROM_MOCK",'
                + '"refresh_token":"REFRESH_TOKEN_FROM_MOCK",'
                + '"token_type":"Bearer",'
                + '"expires_in":3600'
                + '}';

            res.setBody(body);
            return res;
        }
    }

    @testSetup
    static void setupData() {
 
        test_DataFactory.insertCanvasSettings();

    }

    private static void ensureCanvasUserTokenExists() {
        // Ensure we have a Canvas_User__c row owned by the running user with a refresh token
        Id uid = UserInfo.getUserId();
        List<Canvas_User__c> existing = [
            SELECT Id
            FROM Canvas_User__c
            WHERE OwnerId = :uid
            LIMIT 1
        ];

        
        if (existing.isEmpty()) {
            insert new Canvas_User__c(
                OwnerId     = uid,
                Alpha_Tag__c = 'old_access',
                Beta_Tag__c  = 'stored_refresh_token'
            );
        }
    }

    private static void deleteCanvasUserTokenIfExists() {
        Id uid = UserInfo.getUserId();
        List<Canvas_User__c> existing = [
            SELECT Id
            FROM Canvas_User__c
            WHERE OwnerId = :uid
        ];
        if (!existing.isEmpty()) {
            delete existing;
        }
    }


    @IsTest
    static void testCreateCanvasOAuthUtility() {

        //ensureCanvasUserTokenExists();
        Test.setMock(HttpCalloutMock.class, new OAuthRefreshMock());

       Test.startTest();
        CanvasOAuthUtility oauthUtil = new CanvasOAuthUtility();

        
        string ogetoAuthUrl = oauthUtil.getoAuthUrl();

        Canvas_User__c user = oauthUtil.createCanvasUser('testcode');
        Boolean userIsAuthorized = CanvasOAuthUtility.userIsAuthorized();
        Test.stopTest();
        //string url = oauthUtil.getoAuthUrl();
        //string accessTokenRequestJson = oauthUtil.getAccessTokenJSON('testcode');

    }
 
    @IsTest
    static void testCreateForUser_success() {
        ensureCanvasUserTokenExists();
        Test.setMock(HttpCalloutMock.class, new OAuthRefreshMock());

        Test.startTest();
        CanvasSession session2 = CanvasSessionFactory.createForCurrentUser();
        CanvasSession session = CanvasSessionFactory.createForUser(UserInfo.getUserId());
        Test.stopTest();

        System.assertNotEquals(null, session, 'Session should be created');
        System.assertEquals('https://example.instructure.com/api/v1', session.RootEndpoint);
        System.assertEquals('ACCESS_TOKEN_FROM_MOCK', session.AccessToken);
        System.assertEquals(true, session.isReady());
    }

    @IsTest
    static void testCreateForCurrentUser_success() {
        ensureCanvasUserTokenExists();
        Test.setMock(HttpCalloutMock.class, new OAuthRefreshMock());

        Test.startTest();
        CanvasSession session = CanvasSessionFactory.createForCurrentUser();
        CanvasSession session2 = CanvasSessionFactory.createFromDefault();
        Test.stopTest();

        System.assertNotEquals(null, session, 'Session should be created');
        System.assertEquals('https://example.instructure.com/api/v1', session.RootEndpoint);
        System.assertEquals('ACCESS_TOKEN_FROM_MOCK', session.AccessToken);
        System.assertEquals(true, session.isReady());
    }

    @IsTest
    static void testCreateForUser_missingUserToken_throws() {
        // settings exist from @testSetup
        deleteCanvasUserTokenIfExists();
        Test.setMock(HttpCalloutMock.class, new OAuthRefreshMock());

        Boolean threw = false;
        try {
            Test.startTest();
            CanvasSessionFactory.createForUser(UserInfo.getUserId());
            Test.stopTest();
        } catch (Exception e) {
            threw = true;
        }
        System.assertEquals(true, threw, 'Should throw when user refresh token record is missing');
    }

    @IsTest
    static void testCreateForUser_missingSettings_throws() {
        // Remove settings that @testSetup inserted (allowed in a test method)
        delete [SELECT Id FROM Canvas_Settings__c];

        ensureCanvasUserTokenExists();
        Test.setMock(HttpCalloutMock.class, new OAuthRefreshMock());

        Boolean threw = false;
        try {
            Test.startTest();
            CanvasSessionFactory.createForUser(UserInfo.getUserId());
            Test.stopTest();
        } catch (Exception e) {
            threw = true;
        }
        System.assertEquals(true, threw, 'Should throw when Canvas_Settings__c is missing');
    }
}
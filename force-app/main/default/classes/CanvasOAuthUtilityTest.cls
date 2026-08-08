@isTest(seeAllData=false)

public class CanvasOAuthUtilityTest {



    @isTest
    static void test_oauthutility () {
        // Ensure we have a Canvas_User__c row owned by the running user with a refresh token
        test_DataFactory.SeedSettingsResult settings = test_DataFactory.insertCanvasSettings();
        CanvasMockAPIResponseFactory apiMock = new CanvasMockAPIResponseFactory();
        Test.setMock(HttpCalloutMock.class, apiMock);

        Test.startTest();

        Id uid = UserInfo.getUserId();

        CanvasOAuthUtility oauthUtil = new CanvasOAuthUtility();
        CanvasToken token = oauthUtil.refreshCanvasUser();
        string oauthurl = oauthUtil.getoAuthUrl();
        CanvasToken tokeforspecifieduser = oauthUtil.refreshCanvasUserFor(uid);
        Canvas_User__c usertoken = oauthUtil.createCanvasUser('testcode');

        Test.stopTest();

        System.assertNotEquals(null, token, 'Token should not be null after refresh');
        System.assertNotEquals(null, token.access_token, 'Access token should not be null');
        System.assertNotEquals(null, token.refresh_token, 'Refresh token should not be null');
    }


}
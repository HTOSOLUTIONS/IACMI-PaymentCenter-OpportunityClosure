@isTest(seeAllData=false)

public class test_CanvasOAuthController {

    static testMethod void TestController() {
        
        //Necessary to avoid error 'System.CalloutException: You have uncommitted work pending. Please commit or rollback before calling out'
        test.startTest();
        Lead testLead = test_DataFactory.insertLead();
		test_DataFactory.insertCanvasSettings();

        test.stopTest();

        CanvasMockAPIResponseFactory apiMock = new CanvasMockAPIResponseFactory();
        Test.setMock(HttpCalloutMock.class, apiMock);
        
        Apexpages.StandardController sc = new Apexpages.StandardController(testLead);
		Apexpages.currentPage().getParameters().put('code','xxxxxxxxx');
        
        
		CanvasOAuthConfirmationController ctrlr = new CanvasOAuthConfirmationController(sc);        
        PageReference pageref0 = ctrlr.processToken();
        
        
        
    }
    
    
}
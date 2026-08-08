@isTest(seeAllData=false)
public class test_EnrollLeadsController {

    static testMethod void TestNoUser() {
		
        //Necessary to avoid error 'System.CalloutException: You have uncommitted work pending. Please commit or rollback before calling out'
        test.startTest();
        test_DataFactory.insertLead();
		test_DataFactory.insertCanvasSettings();
        test_DataFactory.insertCanvasUser();
        Canvas_Course__c testCourse = test_DataFactory.insertCanvasCourse();
		test.stopTest();
        
        CanvasMockAPIResponseFactory apiMock = new CanvasMockAPIResponseFactory();
        Test.setMock(HttpCalloutMock.class, apiMock);

        List<Lead> leadList = [SELECT Name FROM Lead Limit 1];
        Apexpages.StandardSetController ssc = new Apexpages.StandardSetController(leadList);
		ssc.setSelected(leadList);
        
        System.debug('Getting ready to create instance of EnrollLeadsCustomController()');
        EnrollLeadsCustomController ctrl = new EnrollLeadsCustomController(ssc);
        
        System.debug('Getting ready to call setupPage()');
        PageReference pageref0 = ctrl.setupPage();
        
        List<selectOption> list1 = ctrl.getCanvascourses();
		ctrl.selectedCourse = testCourse.Id;
        
        System.debug('Getting ready to call authenticateCanvas()');
        PageReference pageref1 = ctrl.authenticateCanvas();
       
        System.debug('Getting ready to call enrollSelect()');
        ctrl.enrollSelected();
        
        apiMock.ExistingUser = true;
        ctrl.enrollSelected();

        apiMock.ExistingEnrollments = true;
        ctrl.enrollSelected();

    }

    static testMethod void TestUserNoEnrollments() {
        
        //Necessary to avoid error 'System.CalloutException: You have uncommitted work pending. Please commit or rollback before calling out'
        test.startTest();
        test_DataFactory.insertLead();
		test_DataFactory.insertCanvasSettings();
        test_DataFactory.insertCanvasUser();
        Canvas_Course__c testCourse = test_DataFactory.insertCanvasCourse();
		test.stopTest();
        
        CanvasMockAPIResponseFactory apiMock = new CanvasMockAPIResponseFactory();
        Test.setMock(HttpCalloutMock.class, apiMock);

        List<Lead> leadList = [SELECT Name FROM Lead Limit 1];
        Apexpages.StandardSetController ssc = new Apexpages.StandardSetController(leadList);
		ssc.setSelected(leadList);
        
        System.debug('Getting ready to create instance of EnrollLeadsCustomController()');
        EnrollLeadsCustomController ctrl = new EnrollLeadsCustomController(ssc);
        
        System.debug('Getting ready to call setupPage()');
        PageReference pageref0 = ctrl.setupPage();
        
        List<selectOption> list1 = ctrl.getCanvascourses();
		ctrl.selectedCourse = testCourse.Id;
        
        System.debug('Getting ready to call authenticateCanvas()');
        PageReference pageref1 = ctrl.authenticateCanvas();
       
        apiMock.ExistingUser = true;

        System.debug('Getting ready to call enrollSelect()');
        
        ctrl.enrollSelected();
       
        
    }
    
    static testMethod void TestUserWithEnrollments() {
        
        //Necessary to avoid error 'System.CalloutException: You have uncommitted work pending. Please commit or rollback before calling out'
        test.startTest();
        test_DataFactory.insertLead();
		test_DataFactory.insertCanvasSettings();
        test_DataFactory.insertCanvasUser();
        Canvas_Course__c testCourse = test_DataFactory.insertCanvasCourse();
		test.stopTest();
        
        CanvasMockAPIResponseFactory apiMock = new CanvasMockAPIResponseFactory();
        Test.setMock(HttpCalloutMock.class, apiMock);

        List<Lead> leadList = [SELECT Name FROM Lead Limit 1];
        Apexpages.StandardSetController ssc = new Apexpages.StandardSetController(leadList);
		ssc.setSelected(leadList);
        
        System.debug('Getting ready to create instance of EnrollLeadsCustomController()');
        EnrollLeadsCustomController ctrl = new EnrollLeadsCustomController(ssc);
        
        System.debug('Getting ready to call setupPage()');
        PageReference pageref0 = ctrl.setupPage();
        
        List<selectOption> list1 = ctrl.getCanvascourses();
		ctrl.selectedCourse = testCourse.Id;
        
        System.debug('Getting ready to call authenticateCanvas()');
        PageReference pageref1 = ctrl.authenticateCanvas();
       
        apiMock.ExistingUser = true;
        apiMock.ExistingEnrollments = true;

        System.debug('Getting ready to call enrollSelect()');
        
        ctrl.enrollSelected();
        
        
    }
    
    
    
}
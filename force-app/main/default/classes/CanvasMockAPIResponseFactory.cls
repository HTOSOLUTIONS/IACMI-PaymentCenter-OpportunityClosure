@isTest

// Use Cases:
// 1. CanvasOAuthUtility.getAccessTokenJSON(string code)
// 2. CanvasOAuthUtility.getRefreshTokenJSON(string refreshtoken)
// 3. CanvasAPIUtility.getCoursesJSON()
// 4. CanvasAPIUtility.getUserJSON(string loginemail)
// 5. CanvasAPIUtility.getCreateUserJSON(string loginemail, string name)
// 6. CanvasAPIUtility.getUserEnrollmentsJSON(string userid)
// 7. CanvasAPIUtility.getEnrollUserJSON(string courseid, string userid)
global class CanvasMockAPIResponseFactory implements HttpCalloutMock {

    
    global boolean ExistingUser {get; set;}
    
    global boolean ExistingEnrollments {get; set;}
    
    global CanvasMockAPIResponseFactory() {
        ExistingUser = false;
        ExistingEnrollments = false;
    }
    
    global HTTPResponse respond(HTTPRequest req) {
        
        System.debug('Got a request...' + req.getEndpoint());
        
        string cBodyResponse = '';
        string cEndPoint = req.getEndpoint();
        string cMethod = req.getMethod();
        integer nStatusCode = 200;

        //Canvas_Settings__c settings = [SELECT Canvas_Install_URL__c, OAuth_URL__c, API_Client_ID__c, Redirect_URL__c FROM Canvas_Settings__c LIMIT 1];
        
        if (cEndpoint.contains('grant_type=authorization_code')) {
            //1. getCanvasTokenfromCode
            cBodyResponse = test_DataFactory.testAuthorization_Code();
        } else if (cEndpoint.contains('grant_type=refresh_token')) {
			//2. getRefreshTokenJSON
            cBodyResponse = test_DataFactory.testAuthorization_Code();
        } else if (cEndpoint.contains('/accounts/') && cEndpoint.contains('/courses')) {
			//3. getCoursesJSON
            cBodyResponse = test_DataFactory.getCoursesList();
        } else if (cMethod=='GET' && cEndpoint.contains('/accounts/') && cEndpoint.contains('/users')) {
            //4. getUserJSON
            if (ExistingUser) {
	            cBodyResponse = test_DataFactory.getTestUserListResponse();
            } else {
                cBodyResponse ='[]';
            }
        } else if (cMethod=='POST' && cEndpoint.contains('/accounts/') && cEndpoint.contains('/users')) {
            //5. getCreateUserJSON
            cBodyResponse = test_DataFactory.getTestUserResponse();
        } else if (cMethod=='GET' && cEndpoint.contains('/users/') && cEndpoint.contains('/enrollments')) {
            //6. getUserEnrollmentsJSON
            if (ExistingEnrollments) {
	            cBodyResponse = test_DataFactory.getTestUserEnrollmentsResponse();
            } else {
                cBodyResponse ='[]';
            }
        } else if (cMethod=='POST' && cEndpoint.contains('/courses/') && cEndpoint.contains('/enrollments')) {
            //7. getEnrollUserJSON
            cBodyResponse = test_DataFactory.getTestUserEnrollmentResponse();
        }

        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');

        res.setBody(cBodyResponse);
        res.setStatusCode(nStatusCode);

        System.debug(cBodyResponse);
        
        
        return res;
        
        
    }
    
    
}
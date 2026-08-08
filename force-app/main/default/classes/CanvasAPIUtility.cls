public class CanvasAPIUtility {

    
    private String root_endpoint;
    
    private String access_token;
    
    @TestVisible
    private String rootEndPoint {get {return root_endpoint;}}
    
    @TestVisible
    private String accessToken {get {return access_token;}}
    
    // Indicates whether the utility is properly initialized.
    public boolean IsReady {get {return String.isNotBlank(root_endpoint) && String.isNotBlank(access_token);}}
    
    public CanvasAPIUtility() {
        Canvas_Settings__c settings = null;
        try {
            settings = [SELECT Canvas_Install_URL__c, API_Root_Endpoint__c, DefaultUserName__c FROM Canvas_Settings__c LIMIT 1];
            root_endpoint = settings.Canvas_Install_URL__c + settings.API_Root_Endpoint__c;
        } catch (Exception o) {
        }
        try {
            CanvasOAuthUtility utility = new CanvasOAuthUtility();
            CanvasToken token = utility.refreshCanvasUser();
            access_token = token.access_token;
        } catch (Exception o) {
        }
        
    }
    
    public CanvasAPIUtility(CanvasSession session) {
        if (session == null) throw new ApplicationException('CanvasSession is required.');
        this.root_endpoint = session.RootEndpoint;   // or session.rootEndpoint
        this.access_token  = session.AccessToken;    // or session.accessToken
    }


    @TestVisible
    private string getAPIToken() {
        //return '19954~pK5II5fBEht3eXYRPjALcYZYRtwWp4qfAzDpTzCFMrjhKaaDcNW63lZyy7m8R66o';
        return access_token;
    }

    
    @TestVisible
    private string getRootEndPoint() {
        return root_endpoint;
		//return 'https://iacmi-ace.instructure.com/api/v1';        
    }


    @TestVisible
    private HttpRequest getAuthorizedRequest() {

        HttpRequest request = new HttpRequest();

        string tokenVal = this.getAPIToken() ;
        string tokenString = 'Bearer ' + tokenVal ;
        
        request.setHeader('Authorization', tokenString);
        
        return request;
        
    }
    

    @TestVisible
    private HttpRequest getCoursesAPIRequest() {
        HttpRequest request = this.getAuthorizedRequest();
        string rootendpoint = this.getRootEndPoint();
        request.setEndpoint(rootendpoint + '/accounts/1/courses');
        request.setMethod('GET');
        
        return request;
        
    }

    @TestVisible
    private HttpRequest getUserAPIRequest(string loginemail) {
        HttpRequest request = this.getAuthorizedRequest();
        string rootendpoint = this.getRootEndPoint();
        request.setEndpoint(rootendpoint + '/accounts/1/users?search_term=' + loginemail);
        request.setMethod('GET');
        
        return request;
        
    }

    @TestVisible
    private HttpRequest postCreateUserRequest(string loginemail, string name) {
        HttpRequest request = this.getAuthorizedRequest();
        string rootendpoint = this.getRootEndPoint();
        string encodedname = EncodingUtil.urlEncode(name, 'UTF-8');
        request.setEndpoint(rootendpoint + '/accounts/1/users?pseudonym[unique_id]='+ loginemail + '&user[name]=' + encodedname);
        request.setMethod('POST');
        return request;
    }
    

    @TestVisible
    private HttpRequest getUserEnrollmentsRequest(string userid) {
        HttpRequest request = this.getAuthorizedRequest();
        string rootendpoint = this.getRootEndPoint();
        request.setEndpoint(rootendpoint + '/users/' + userid + '/enrollments');
		request.setMethod('GET');       
        return request;
    }
    
    
    @TestVisible
    private HttpRequest postEnrollUserRequest(string courseid, string userid) {
        HttpRequest request = this.getAuthorizedRequest();
        string rootendpoint = this.getRootEndPoint();
        request.setEndpoint(rootendpoint + '/courses/' + courseid + '/enrollments?enrollment[user_id]=' + userid + '&enrollment[type]=StudentEnrollment&enrollment[notify]=true');
        request.setMethod('POST');
        
        return request;
        
    }
    

    // Not used.  Only for validating API.
    public string getCoursesJSON() {

        Http http = new Http();
        HttpRequest request = this.getCoursesAPIRequest();
        request.setTimeout(120000);
        HttpResponse response = http.send(request);
        if (response.getStatusCode() == 200) {
            string responseBody = response.getBody();
            System.debug(responseBody);
            return responseBody;
        } else {
            throw new applicationException(response.getStatus());
        }
    }
    
    // -------------------------------------------------------
    // Every enrollment needs a User record in Canvas.
    // Users in Canvas are identified by their login email.
    public string getUserJSON(string loginemail) {

        Http http = new Http();
        HttpRequest request = this.getUserAPIRequest(loginemail);
        request.setTimeout(120000);
        HttpResponse response = http.send(request);
        if (response.getStatusCode() == 200) {
            string responseBody = response.getBody();
            System.debug(responseBody);
            return responseBody;
        } else {
            throw new applicationException(response.getStatus());
        }
    }

    // Json returned when creating a user.
    public string getCreateUserJSON(string loginemail, string name) {
        Http http = new Http();
        HttpRequest request = this.postCreateUserRequest(loginemail, name);
        request.setTimeout(120000);
        HttpResponse response = http.send(request);
        if (response.getStatusCode() == 200) {
            string responseBody = response.getBody();
            System.debug(responseBody);
            return responseBody;
        } else {
            throw new applicationException(response.getStatus());
        }
        
    }

    // Json returned when getting user enrollments.
    public string getUserEnrollmentsJSON(string userid) {
        Http http = new Http();
        HttpRequest request = this.getUserEnrollmentsRequest(userid);
        request.setTimeout(120000);
        HttpResponse response = http.send(request);
        if (response.getStatusCode() == 200) {
            string responseBody = response.getBody();
            System.debug(responseBody);
            return responseBody;
        } else {
            throw new applicationException(response.getStatus());
        }
        
    }    
    
    // Json returned when enrolling a user in a course.
    public string getEnrollUserJSON(string courseid, string userid) {

        Http http = new Http();
        HttpRequest request = this.postEnrollUserRequest(courseid, userid);
        request.setTimeout(120000);
        HttpResponse response = http.send(request);
        if (response.getStatusCode() == 200) {
            string responseBody = response.getBody();
            System.debug(responseBody);
            return responseBody;
        } else {
            throw new applicationException(response.getStatus());
        }
    }


    
    
    
}
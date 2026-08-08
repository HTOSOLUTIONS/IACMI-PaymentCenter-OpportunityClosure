public class CanvasOAuthUtility {

    private string getBaseTokenUrl(){
        Canvas_Settings__c settings = [SELECT Canvas_Install_URL__c, 
                                       Token_URL__c, 
                                       Developer_Key__c, 
                                       API_Client_ID__c, 
                                       Redirect_URL__c FROM Canvas_Settings__c LIMIT 1];

        if (settings == null) {
           throw new applicationException('No Canvas settings found.'); 
        }

        string tokenUrl = null;
        tokenUrl = settings.Canvas_Install_URL__c 
            + settings.Token_URL__c 
            + '?client_id=' + settings.API_Client_ID__c 
            + '&client_secret=' + settings.Developer_Key__c
            + '&redirect_uri=' + settings.Redirect_URL__c ;

		return tokenUrl;        
        
    }
    
    //Direct the User Authorize access. A 'code' will be passed as parameter to the redirect_url
    public string getoAuthUrl(){
        string oAuthUrl = null;
        Canvas_Settings__c settings = [SELECT Canvas_Install_URL__c, OAuth_URL__c, API_Client_ID__c, Redirect_URL__c FROM Canvas_Settings__c LIMIT 1];
        if (settings == null) {
           throw new applicationException('No Canvas settings found.'); 
        }
        oAuthUrl = settings.Canvas_Install_URL__c + settings.OAuth_URL__c + '?client_id=' + settings.API_Client_ID__c + '&response_type=code&redirect_uri=' + settings.Redirect_URL__c ;
        
        return oAuthUrl;
    }

    //1. Returns the URL to send to Canvas
    private string getAccessTokenUrl(string code) {

		string baseToken = getBaseTokenUrl();
        baseToken = baseToken + '&grant_type=authorization_code' + '&code=' + code;
        return baseToken;
    }

    //Methods to getCanvasToken
    //2. Returns an HttpRequest for the token
    private HttpRequest getAccessTokenRequest(string code) {
        string tokenurl = getAccessTokenUrl(code);
        HttpRequest request = new HttpRequest();
        request.setEndpoint(tokenurl);
        request.setMethod('POST');
        return request;
    }
    
    //3. Uses an HTTPRequest to return the JSON form of the token
    private string getAccessTokenJSON(string code) {
        Http http = new Http();
        HttpRequest request = this.getAccessTokenRequest(code);
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
    
    //4. Returns a CanvasToken from the Refresh Token.
    private CanvasToken getCanvasTokenfromCode(string code) {
        string tokenjson = getAccessTokenJSON(code);
        System.debug(tokenjson);
        return CanvasObjectFactory.getCanvasToken(tokenjson);
    }
    
    //Methods to getCanvasToken from Refresh Token
    //1. Returns the URL to send to Canvas
    private string getRefreshTokenUrl(string refreshtoken) {

		string baseToken = getBaseTokenUrl();
        baseToken = baseToken + '&grant_type=refresh_token' + '&refresh_token=' + refreshtoken;
        return baseToken;
    }
    
    //2. Returns an HttpRequest for the token
    private HttpRequest getRefreshTokenRequest(string refreshtoken) {
        string tokenurl = getRefreshTokenUrl(refreshtoken);
        System.debug('Here is the token URL');
        System.debug(tokenurl);
        HttpRequest request = new HttpRequest();
        request.setEndpoint(tokenurl);
        request.setMethod('POST');
        return request;
    }
    
    //3. Uses an HTTPRequest to return the JSON form of the token
    private string getRefreshTokenJSON(string refreshtoken) {
        Http http = new Http();
        HttpRequest request = this.getRefreshTokenRequest(refreshtoken);
        request.setTimeout(120000);
        try {
	        HttpResponse response = http.send(request);
            if (response.getStatusCode() == 200) {
                string responseBody = response.getBody();
                System.debug(responseBody);
                return responseBody;
            } else {
                throw new applicationException(response.getStatus());
            }
        } catch (Exception o) {
			System.debug(o);
			throw o;            
        }
        
    }
    
    //4. Returns a CanvasToken from the Refresh Token.
    private CanvasToken getCanvasTokenfromRefresh(string refreshtoken) {
        string tokenjson = getRefreshTokenJSON(refreshtoken);
        CanvasToken oRefreshToken = CanvasObjectFactory.getCanvasToken(tokenjson);
        return oRefreshToken;
    }
    
    
    public static Canvas_User__c getCanvasUser() {

		Canvas_User__c usertoken = null;
        try {
            id userid = UserInfo.getUserId();
            System.debug('Userid=' + userid);
            usertoken = [SELECT Alpha_Tag__c, Beta_Tag__c, LastModifiedDate 
                                        FROM Canvas_User__c 
                                        WHERE OwnerId = :userid LIMIT 1];
        } catch(Exception o) {
            System.debug(o);
            //Let's see if anything is there...
            try {
                Canvas_User__c user = [SELECT Id, OwnerId, Alpha_Tag__c, Beta_Tag__c FROM Canvas_User__c LIMIT 1];
                System.debug(user);
            } catch (Exception oe) {
				System.debug(oe);                
            }
        }
        return usertoken;
    }
    
    public static boolean userIsAuthorized() {
        Canvas_User__c user = CanvasOAuthUtility.getCanvasUser();
        return user != null && String.isNotBlank(user.Beta_Tag__c);
    }
    
    
    public Canvas_User__c createCanvasUser(string code) {
        Canvas_User__c user = null;
        CanvasToken accesstoken = getCanvasTokenfromCode(code);
        if (accesstoken != null) {
            user = CanvasOAuthUtility.getCanvasUser();
            if (user == null) {
                user = new Canvas_User__c();
                user.Alpha_Tag__c = accesstoken.access_token;
                user.Beta_Tag__c = accesstoken.refresh_token;
				insert user;
            } else {
                user.Alpha_Tag__c = accesstoken.access_token;
                user.Beta_Tag__c = accesstoken.refresh_token;
                update user;
            }
        }
        return user;
    }
    
    public CanvasToken refreshCanvasUser() {
        CanvasToken token = null;
        Canvas_User__c user = CanvasOAuthUtility.getCanvasUser();
        if (user == null){
            throw new applicationException('No user refresh token has been stored.');
        }
        if (String.isBlank(user.Beta_Tag__c)) {
            throw new applicationException('User refresh token does not have a value.');
        }
        token = getCanvasTokenfromRefresh(user.Beta_Tag__c);

        //Probably cannot do this here because mixing DML 
        /*
        if (token != null) {
			user.Alpha_Tag__c = token.access_token;
            update user;
        }
		*/
        
        return token;
    }
    
    // Add this overload to query a Canvas_User__c by explicit owner (User Id)
    private static Canvas_User__c getCanvasUserFor(Id ownerUserId) {
        Canvas_User__c usertoken = null;
        try {
            usertoken = [
                SELECT Alpha_Tag__c, Beta_Tag__c, LastModifiedDate
                FROM Canvas_User__c
                WHERE OwnerId = :ownerUserId
                LIMIT 1
            ];
        } catch (Exception e) {
            System.debug(e);
        }
        return usertoken;
    }    
    
    // Add this overload so callers can refresh token for a specific user deterministically
    public CanvasToken refreshCanvasUserFor(Id ownerUserId) {
        CanvasToken token = null;
        Canvas_User__c user = CanvasOAuthUtility.getCanvasUserFor(ownerUserId);
        System.debug(LoggingLevel.INFO,
            'CanvasOAuthUtility.getCanvasUserFor returned => ' + JSON.serialize(user)
        );

        if (user == null) {
            throw new ApplicationException('No user refresh token has been stored.');
        }
        if (String.isBlank(user.Beta_Tag__c)) {
            throw new ApplicationException('User refresh token does not have a value.');
        }

        token = getCanvasTokenfromRefresh(user.Beta_Tag__c);
        return token;
    }


}
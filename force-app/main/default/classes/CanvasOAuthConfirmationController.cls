//This is the redirect_url for the Canvas oAuth process
public class CanvasOAuthConfirmationController {

    private string canvascode;
    private boolean is_authorized;
    public boolean SuccessFullAuthorized {get {return is_authorized;}}
   
    public CanvasOAuthConfirmationController(ApexPages.StandardController controller) {

        //Canvas oAuth sends the 'code' as a parameter to this redirect_url.
        //Extract the code from the parameter(s)
        try {
	        canvascode = Apexpages.currentPage().getParameters().get('code');
        }
        catch (Exception o) {
        }
    }
   
    //This is the action method for the VisualForce page.  If the code was found as a parameter to the page
    //then attempt to create and save a token for the user that can be reused for future calls to the API.
    public PageReference processToken() {

        if (String.isNotBlank(canvascode)) {
            CanvasOAuthUtility oauthutility = new CanvasOAuthUtility();
            System.debug('Adding a user...');
            System.debug(canvascode);
            Canvas_User__c  user = oauthutility.createCanvasUser(canvascode);
            is_authorized = CanvasOAuthUtility.userIsAuthorized();
            
        } else {
			is_authorized = false;            
        }

        return null;

    }
    
    
    
}
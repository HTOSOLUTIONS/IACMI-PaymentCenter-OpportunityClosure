public class EnrollLeadsCustomController {

    private ApexPages.StandardSetController standardController;
    
    private EnrollmentUtility enrollmentUtility ;

    public EnrollLeadsCustomController(ApexPages.StandardSetController controller) {

        this.standardController = controller;
        
        this.enrollmentResults = new EnrollmentResults();
        
        this.enrollmentRequests = new List<EnrollmentRequest>();

        //Canvas_User__c user = CanvasOAuthUtility.getCanvasUser();
        //UserHasToken = this.enrollmentUtility.IsReady;

        CanvasSession session = CanvasSessionFactory.createForCurrentUser();        
        this.enrollmentUtility = new EnrollmentUtility(session);
        UserHasToken = this.enrollmentUtility.IsReady;

    }

    public List<Lead> leadstoenroll {get; set;}
    
    public string selectedCourse {get; set;}
    
    public EnrollmentResults enrollmentResults {get; set;}
    
    public List<EnrollmentRequest> enrollmentRequests {get; set;}
    
    public boolean UserHasToken {get; set;}

    public PageReference setupPage() {
        
        leadstoenroll = [SELECT Id,
                         Name, 
                         Email
                        FROM Lead
                        WHERE Id IN :standardController.getSelected()];
        
        for(Lead lead : leadstoenroll) {
            EnrollmentRequest request = new EnrollmentRequest();
            request.LeadEnrolled = lead;
            enrollmentRequests.add(request);
        }
        

        
        return null;
    }
    
    public PageReference enrollSelected() {

        //, Canvas_ID__c
        Canvas_Course__c course = [SELECT Id, Name 
                                   FROM Canvas_Course__c
                                   WHERE Id = :selectedCourse
                                  ];
        
        enrollmentResults = enrollmentUtility.EnrollLeads(course, enrollmentRequests, 'Manual Enrollment');
        enrollmentRequests = enrollmentResults.ProcessedRequests;
        
        return null;

    }


    public List<selectOption> getCanvascourses(){
        List<selectOption> courses = new List<selectOption>();
        for(Canvas_Course__c course :[SELECT Id, Name FROM Canvas_Course__c]){
            courses.add(new SelectOption(course.Id,course.Name));
        }
        
        return courses;
    }
    

    public PageReference authenticateCanvas() {
        
        CanvasOAuthUtility utility = new CanvasOAuthUtility();
        string oAuthUrl = utility.getoAuthUrl();
        //PageReference canvasauth = new PageReference('https://iacmi-ace.instructure.com/login/oauth2/auth?client_id=199540000000000002&response_type=code&redirect_uri=https://htosolutionsllc2-dev-ed--c.develop.vf.force.com/apex/EnrollmentConfirmation');
		PageReference canvasauth = new PageReference(oAuthUrl);
        
        return canvasauth;
        
    }
    
    
    
}
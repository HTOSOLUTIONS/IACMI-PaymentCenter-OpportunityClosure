public class EnrollmentRequest {
    
    //This is the lead enrolled.
    public Lead LeadEnrolled {get; set;}
    
    public Canvas_Course__c Course {get; set;}

	//This is the object stored in Salesforce    
    public Canvas_Enrollment__c Canvas_Enrollment {get; set;}

    //This is the object on the Canvas side from the API
    public CanvasUserEnrollment CanvasEnrollment {get; set;}
    
    //This is any message returned by the enroller
    public string Message {get; set;}
    
}
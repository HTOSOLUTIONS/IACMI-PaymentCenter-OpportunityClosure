public class CanvasEnrollerResult {

    public string CourseId {get; set;}
    
    public string LoginEmail {get; set;}
    
    public string UserName {get; set;}
    
    public CanvasUserEnrollment CanvasUserEnrollment {get; set;}

    public string[] Messages {get; set;}
    
    public string[] Errors {get; set;}
    
    public boolean NewUser {get; set;}
    
    public boolean FoundExisting {get; set;}
    
    
}
public class CanvasObjectFactory {

    public static CanvasToken getCanvasToken(string jsonStr) {
        CanvasToken canvastoken = null;
        JSONParser parser = JSON.createParser(jsonStr);
        try {
            canvastoken = (CanvasToken)parser.readValueAs(CanvasToken.class);
        } catch(Exception e){
            throw e;
        }
        return canvastoken;
        
    }
    
    public static CanvasUser getCanvasUserFromList(string jsonStr) {
        CanvasUser user = null;
        JSONParser parser = JSON.createParser(jsonStr);
        List<CanvasUser> users = new List<CanvasUser>();
        try {
            users = (List<CanvasUser>)parser.readValueAs(List<CanvasUser>.class);
            if(users.size()==1){
	            user = users[0];
            } else if(users.size() > 1) {
                throw new applicationException('More than one Canvas user found');
            }
        } catch(Exception e){
            throw e;
        }
        return user;
    }
    
    public static CanvasUser getCanvasUser(string jsonStr) {
        CanvasUser user = null;
        JSONParser parser = JSON.createParser(jsonStr);
        try {
            user = (CanvasUser)parser.readValueAs(CanvasUser.class);
        } catch(Exception e){
            throw e;
        }
        return user;
    }
    

    public static List<CanvasUserEnrollment> getCanvasUserEnrollments(string jsonStr){
        List<CanvasUserEnrollment> enrollments = new List<CanvasUserEnrollment>();
        JSONParser parser = JSON.createParser(jsonStr);
        try {
            enrollments = (List<CanvasUserEnrollment>)parser.readValueAs(List<CanvasUserEnrollment>.class);
            System.debug(enrollments);
        } catch(Exception e){
            throw e;
        }
        return enrollments;
    }
    
    public static CanvasUserEnrollment getCanvasUserEnrollment(string jsonStr) {
        CanvasUserEnrollment enrollment = null;
        JSONParser parser = JSON.createParser(jsonStr);
        try {
            enrollment = (CanvasUserEnrollment)parser.readValueAs(CanvasUserEnrollment.class);
            System.debug(enrollment);
        } catch(Exception e){
            throw e;
        }
        return enrollment;
        
    }
    
}
// TEST: deployed from local VS Code on 2025-12-12

public class CanvasEnrollerUtility {
    
    public CanvasEnrollerUtility() {
        canvas_api_utility = new CanvasAPIUtility();
        
    }
    
    public CanvasEnrollerUtility(CanvasSession session) {
        canvas_api_utility = new CanvasAPIUtility(session);
        
    }


    private CanvasAPIUtility canvas_api_utility;

    public boolean IsReady {get {return canvas_api_utility.IsReady;}}
    
    public CanvasEnrollerResult EnrollUserinCourse(string courseid, string loginemail, string username) {

        System.debug(LoggingLevel.DEBUG,'Starting CanvasEnrollerUtility.EnrollUserinCourse...'
        );

        CanvasUserEnrollment enrollment = null;
        CanvasEnrollerResult result = new CanvasEnrollerResult();
        result.CourseId = courseid;
        result.LoginEmail = loginemail;
        result.UserName = username;
        
        boolean newuser = false;
        string getuserjson = canvas_api_utility.getUserJSON(loginemail);
        if (getuserjson == null) {
            throw new applicationException('Failed API Call to look for an existing user.');
        }
		CanvasUser user = CanvasObjectFactory.getCanvasUserFromList(getuserjson);
        if (user == null) {
            System.debug('A new user will need to be created.');
            //getuserjson = canvas_api_utility.getCreateUserJSON('jhrhilltop@gmail.com','Jon Russell');
            getuserjson = canvas_api_utility.getCreateUserJSON(loginemail,username);
            user = CanvasObjectFactory.getCanvasUser(getuserjson);
            System.debug('Created a new user. Id=' + user.id);
            System.debug(user);
            newuser = true;
        }

        if (user != null) {
			System.debug('Enrolling user. Id=' + user.id);
            if (!newuser) {
	            string userenrollmentsjson = canvas_api_utility.getUserEnrollmentsJSON(user.id);
                if (userenrollmentsjson != null) {
                    List<CanvasUserEnrollment> enrollments = CanvasObjectFactory.getCanvasUserEnrollments(userenrollmentsjson);
                    if (enrollments.size() > 0) {
                        System.debug('Found ' + enrollments.size() + ' existing enrollments.');
                        for (CanvasUserEnrollment existingenrollment : enrollments) {
                            if (existingenrollment.course_id == courseid) {
                                System.debug('Found existing enrollment for courseid ' + courseid + '. Enrollment id: ' + existingenrollment.id);
                                enrollment = existingenrollment;
                                result.FoundExisting = true;
                                break;
                            }
                        }
                    } 
                    
                } else {
                   System.debug('Could not get existing enrollments for user.');
                }
            }
            if (enrollment == null) {
                System.debug('No existing enrollments found. Will create a new one.');
                string newenrollmentjson = canvas_api_utility.getEnrollUserJSON(courseid,user.id);
                enrollment = CanvasObjectFactory.getCanvasUserEnrollment(newenrollmentjson);
				System.debug('Created a new enrollment for courseid ' + courseid + '. Enrollment id: ' + enrollment.id);
            }
            System.debug(enrollment);
        } else {
            throw new applicationException('Could not find or create a user.');
        }
        
        result.NewUser = newuser;
        result.CanvasUserEnrollment = enrollment;
        
        return result;
        
    }
    
    
}
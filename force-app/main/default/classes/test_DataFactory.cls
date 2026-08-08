@isTest

global class test_DataFactory {

    public class SeedSettingsResult {
        public Canvas_Settings__c settings;
        public Canvas_User__c canvasUser;
    }

    global static void inserCanvasCoursePackage() {
        // --- Package ---
        Canvas_Course_Package__c pkg = new Canvas_Course_Package__c(
            Package_Name__c = 'Course Package 1'
        );

        try {
            insert pkg;
        } catch (DmlException e) {
            System.debug(LoggingLevel.ERROR, 'FAILED inserting Canvas_Course_Package__c: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, e.getDmlMessage(0));
            System.debug(LoggingLevel.ERROR, e.getStackTraceString());
            System.assert(false, 'Insert Canvas_Course_Package__c failed: ' + e.getDmlMessage(0));
        }

    }       


    global static void ensureCanvasUserTokenExists() {
        // Ensure we have a Canvas_User__c row owned by the running user with a refresh token
        Id uid = UserInfo.getUserId();
        List<Canvas_User__c> existing = [
            SELECT Id
            FROM Canvas_User__c
            WHERE OwnerId = :uid
            LIMIT 1
        ];

        if (existing.isEmpty()) {
            insert new Canvas_User__c(
                OwnerId     = uid,
                Alpha_Tag__c = 'old_access_token',
                Beta_Tag__c  = 'stored_refresh_token'
            );
        }
    }

    //// Inserts necessary Canvas settings and a default Canvas user mapping
    public static SeedSettingsResult insertCanvasSettings() {
        

        // --- Canvas Settings ---
        // Adjust field API names if yours differ (these are from your earlier refactor context)
        Canvas_Settings__c settings = new Canvas_Settings__c(
            Name = 'Default',
            API_Client_ID__c = '00000000000000000',
            API_Root_Endpoint__c = '/api/v1',
            Canvas_Install_URL__c = 'https://example.instructure.com',
            Developer_Key__c = '00000000000000000',
            Token_URL__c = '/login/oauth2/token',
            OAuth_URL__c = '/login/oauth2/auth',
            Redirect_URL__c = ''
        );
        
        insert settings;

        // --- Default Canvas User mapping ---
        // This record is used by CanvasSessionFactory.createFromDefault()
        Canvas_User__c defaultUser = new Canvas_User__c(
            OwnerId = UserInfo.getUserId(),
            Alpha_Tag__c = 'old_access_token',
            Beta_Tag__c  = 'stored_refresh_token'
        );
        insert defaultUser;

        // Re-query to get auto-number Name populated
        defaultUser = [
            SELECT Id, Name, OwnerId, Alpha_Tag__c, Beta_Tag__c
            FROM Canvas_User__c
            WHERE Id = :defaultUser.Id
        ];        

        // Now set settings.DefaultUserName__c to the auto-generated Name value
        settings.DefaultUserName__c = defaultUser.Name;
        update settings;


        SeedSettingsResult result = new SeedSettingsResult();
        result.settings = settings;
        result.canvasUser = defaultUser;
        return result;
        
    }
    
    global static Lead insertLead() {
     
        Lead testlead = new Lead();
        testLead.FirstName = 'Test';
        testLead.LastName = 'User';
        testLead.Email = 'testuser@mail.com';
        testLead.Company = 'Test Company';
        
        insert testLead;
        
        return testLead;
        
    }
    
    global static Canvas_Course__c insertCanvasCourse() {
        Canvas_Course__c course = new Canvas_Course__c();
        course.Name = 'Test Course';
        course.Canvas_ID__c = '6';
        
        insert course;
        
        return course;
        
        
    }

    // Kept for backwards compatibility
    global static void insertCanvasUser() {
        
        ensureCanvasUserTokenExists();
        
    }

    
    global static string testAuthorization_Code() {
        return '{"access_token":"19954~kfg97TD96EedODUoiQGAv5WqNPZ6v7QMNkJ2gRuztq7bTwYOd4KdweYsH5GYXfDB","token_type":"Bearer","user":{"id":1550,"name":"jonathan.russell@htosolutions.com","global_id":"199540000000001550","effective_locale":"en"},"canvas_region":"us-west-2","refresh_token":"19954~B6OnLD1niUUcXEMlMU0Vdm2W6zN8Bzhls70HayZalSeYjwS1D9NQFxEiHRbeQElm","expires_in":3600}';
    }
    
    
    public static string getTestUserListResponse() {
		string cTestCreateResponse = '[{"id":1695,"name":"Jon Russell","created_at":"2022-10-18T09:44:39-04:00","sortable_name":"Russell, Jon","short_name":"Jon Russell","sis_user_id":null,"integration_id":null,"sis_import_id":null,"login_id":"jhrhilltop@gmail.com"}]';
        return cTestCreateResponse;
    }

    public static string getTestUserResponse() {
		string cTestCreateResponse = '{"id":1695,"name":"Jon Russell","created_at":"2022-10-18T09:44:39-04:00","sortable_name":"Russell, Jon","short_name":"Jon Russell","sis_user_id":null,"integration_id":null,"sis_import_id":null,"login_id":"jhrhilltop@gmail.com"}';
        return cTestCreateResponse;
    }
    
    //Single enrollment
    public static string getTestUserEnrollmentResponse() {
        string testresponse = '{"id":1691,"user_id":1695,"course_id":6,"type":"StudentEnrollment","created_at":"2022-10-18T13:58:57Z","updated_at":"2022-10-18T14:09:18Z","associated_user_id":null,"start_at":null,"end_at":null,"course_section_id":2,"root_account_id":1,"limit_privileges_to_course_section":false,"enrollment_state":"invited","role":"StudentEnrollment","role_id":3,"last_activity_at":null,"last_attended_at":null,"total_activity_time":0,"sis_import_id":null,"grades":{"html_url":"https://iacmi-ace.instructure.com/courses/6/grades/1695","current_grade":null,"current_score":null,"final_grade":null,"final_score":null,"unposted_current_score":null,"unposted_current_grade":null,"unposted_final_score":null,"unposted_final_grade":null},"sis_account_id":null,"sis_course_id":null,"course_integration_id":null,"sis_section_id":null,"section_integration_id":null,"sis_user_id":null,"html_url":"https://iacmi-ace.instructure.com/courses/6/users/1695","user":{"id":1695,"name":"Jon Russell","created_at":"2022-10-18T09:44:39-04:00","sortable_name":"Russell, Jon","short_name":"Jon Russell","sis_user_id":null,"integration_id":null,"sis_import_id":null,"login_id":"jhrhilltop@gmail.com"}}';
		return testresponse;
    }    
    
    //List of enrollments
    public static string getTestUserEnrollmentsResponse() {
        string testresponse = '[{"id":1691,"user_id":1695,"course_id":6,"type":"StudentEnrollment","created_at":"2022-10-18T13:58:57Z","updated_at":"2022-10-18T14:09:18Z","associated_user_id":null,"start_at":null,"end_at":null,"course_section_id":2,"root_account_id":1,"limit_privileges_to_course_section":false,"enrollment_state":"invited","role":"StudentEnrollment","role_id":3,"last_activity_at":null,"last_attended_at":null,"total_activity_time":0,"sis_import_id":null,"grades":{"html_url":"https://iacmi-ace.instructure.com/courses/6/grades/1695","current_grade":null,"current_score":null,"final_grade":null,"final_score":null,"unposted_current_score":null,"unposted_current_grade":null,"unposted_final_score":null,"unposted_final_grade":null},"sis_account_id":null,"sis_course_id":null,"course_integration_id":null,"sis_section_id":null,"section_integration_id":null,"sis_user_id":null,"html_url":"https://iacmi-ace.instructure.com/courses/6/users/1695","user":{"id":1695,"name":"Jon Russell","created_at":"2022-10-18T09:44:39-04:00","sortable_name":"Russell, Jon","short_name":"Jon Russell","sis_user_id":null,"integration_id":null,"sis_import_id":null,"login_id":"jhrhilltop@gmail.com"}}]';
		return testresponse;
    }    
    


    public static string getCoursesList() {
        string testresponse ='[{"id":1,"name":"Growing With Canvas (Teacher Training)","account_id":1,"uuid":"jaBdesuxP7uQ2E1qbJUoLp5PuoA2cruozN2KjOm5","start_at":null,"grading_standard_id":null,"is_public":false,"created_at":"2021-03-23T15:46:10Z","course_code":"Growing With Canvas","default_view":"wiki","root_account_id":1,"enrollment_term_id":1,"license":"cc_by_nc_sa","grade_passback_setting":null,"end_at":null,"public_syllabus":false,"public_syllabus_to_auth":false,"storage_quota_mb":500,"is_public_to_auth_users":false,"homeroom_course":false,"course_color":null,"friendly_name":null,"apply_assignment_group_weights":true,"calendar":{"ics":"https://iacmi-ace.instructure.com/feeds/calendars/course_jaBdesuxP7uQ2E1qbJUoLp5PuoA2cruozN2KjOm5.ics"},"time_zone":"America/Denver","blueprint":false,"template":false,"sis_course_id":null,"sis_import_id":null,"integration_id":null,"hide_final_grades":false,"workflow_state":"unpublished","restrict_enrollments_to_course_dates":false,"overridden_course_visibility":""},{"id":2,"name":"Be the Hero (Canvas Admin Training))","account_id":1,"uuid":"aLS16YbKO1YpFNpEaP3NSKg55WdWB12s07cdMD6V","start_at":"2021-12-08T18:23:23Z","grading_standard_id":null,"is_public":false,"created_at":"2021-03-23T15:46:26Z","course_code":"Be the Hero","default_view":"wiki","root_account_id":1,"enrollment_term_id":1,"license":"private","grade_passback_setting":null,"end_at":null,"public_syllabus":false,"public_syllabus_to_auth":false,"storage_quota_mb":5000,"is_public_to_auth_users":false,"homeroom_course":false,"course_color":null,"friendly_name":null,"apply_assignment_group_weights":false,"calendar":{"ics":"https://iacmi-ace.instructure.com/feeds/calendars/course_aLS16YbKO1YpFNpEaP3NSKg55WdWB12s07cdMD6V.ics"},"time_zone":"America/Denver","blueprint":false,"template":false,"sis_course_id":null,"sis_import_id":null,"integration_id":null,"hide_final_grades":false,"workflow_state":"available","restrict_enrollments_to_course_dates":false,"overridden_course_visibility":""}]';
		return testresponse;
    }
    
}
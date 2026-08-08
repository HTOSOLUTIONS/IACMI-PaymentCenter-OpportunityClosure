public class CanvasUserEnrollment {

    public string id {get; set;}
    public string user_id {get; set;}
    public string course_id {get; set;}
    public string type {get; set;}    
    public datetime created_at {get; set;}
    public string updated_at {get; set;}    
    public string associated_user_id {get; set;}    
    public string start_at {get; set;}
    public string end_at {get; set;}
    public string course_section_id {get; set;}
    public string root_account_id {get; set;}
    public string limit_privileges_to_course_section {get; set;}
    public string enrollment_state {get; set;}
    public string role {get; set;}
    public string role_id {get; set;}
    public string last_activity_at {get; set;}
    public string last_attended_at {get; set;}
    public string total_activity_time {get; set;}
    public string sis_import_id {get; set;}
    public class grades {
        //public string html_url {get; set;}
        //public string current_grade {get; set;}
        //public string current_score {get; set;}
        //public string final_grade {get; set;}
        //public string final_score {get; set;}
        //public string unposted_current_score {get; set;}
        //public string unposted_current_grade {get; set;}
        //public string unposted_final_score {get; set;}
        //public string unposted_final_grade {get; set;}
    }
    public string sis_account_id {get; set;}
    public string sis_course_id {get; set;}
    public string course_integration_id {get; set;}
    public string sis_section_id {get; set;}
    public string section_integration_id {get; set;}
    public string sis_user_id {get; set;}
    public string html_url {get; set;}
    public class user {
        //public string id {get; set;}
        //public string name {get; set;}
        //public string created_at {get; set;}
        //public string sortable_name {get; set;}
        //public string short_name {get; set;}
        //public string sis_user_id {get; set;}
        //public string integration_id {get; set;}
        //public string sis_import_id {get; set;}
        //public string login_id {get; set;}
    }

    
}
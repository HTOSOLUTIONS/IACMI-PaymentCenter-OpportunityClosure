@isTest(seeAllData=false)
public class test_Apex_Classes_Basic {

    static testMethod void TestClasses() {
        
        CanvasMockAPIResponseFactory apiMock = new CanvasMockAPIResponseFactory();
        Test.setMock(HttpCalloutMock.class, apiMock);

        CanvasToken token1 = new CanvasToken() ;
		token1.access_token = '19954~kfg97TD96EedODUoiQGAv5WqNPZ6v7QMNkJ2gRuztq7bTwYOd4KdweYsH5GYXfDB';
        token1.token_type = 'Bearer';
        token1.canvas_region = '';
        token1.refresh_token = '';
        token1.expires_in = 3600;
        
        CanvasUser user1 = new CanvasUser();
        user1.created_at = '';
        user1.id = '';
        user1.integration_id = '';
        user1.login_id = '';
        user1.name = '';
        user1.short_name = '';
        user1.sis_import_id = '';
        user1.sis_user_id = '';
        user1.sortable_name = '';
        
        CanvasAPIUtility apiUtility = new CanvasAPIUtility();
        
        CanvasUserEnrollment ue1 = new CanvasUserEnrollment();
        ue1.id = '';
        ue1.user_id = '';
        ue1.course_id = '';
        ue1.type = '';    
        ue1.updated_at = '';    
        ue1.associated_user_id = '';    
        ue1.start_at = '';
        ue1.end_at = '';
        ue1.course_section_id = '';
        ue1.root_account_id = '';
        ue1.limit_privileges_to_course_section = '';
        ue1.enrollment_state = '';
        ue1.role = '';
        ue1.role_id = '';
        ue1.last_activity_at = '';
        ue1.last_attended_at = '';
        ue1.total_activity_time = '';
        ue1.sis_import_id = '';
        ue1.sis_account_id = '';
        ue1.sis_course_id = '';
        ue1.course_integration_id = '';
        ue1.sis_section_id = '';
        ue1.section_integration_id = '';
        ue1.sis_user_id = '';
        ue1.html_url = '';
        
        //Test Object Factory
        //string tokenJson = '{"access_token":"19954~kfg97TD96EedODUoiQGAv5WqNPZ6v7QMNkJ2gRuztq7bTwYOd4KdweYsH5GYXfDB","token_type":"Bearer","user":{"id":1550,"name":"jonathan.russell@htosolutions.com","global_id":"199540000000001550","effective_locale":"en"},"canvas_region":"us-west-2","refresh_token":"19954~B6OnLD1niUUcXEMlMU0Vdm2W6zN8Bzhls70HayZalSeYjwS1D9NQFxEiHRbeQElm","expires_in":3600}';
        //CanvasToken token2 = CanvasObjectFactory.getCanvasToken(tokenJson);

       
        try { 
	        CanvasToken token3 = CanvasObjectFactory.getCanvasToken('ajosieuf0wu');
        } catch (Exception o){
        }
        
        try { 
	        CanvasUser user4 = CanvasObjectFactory.getCanvasUser('ouou09us099eaoi0');
        } catch (Exception o){
        }
        
        try { 
	        CanvasUser user5 = CanvasObjectFactory.getCanvasUserFromList('08-8 ==ae');
        } catch (Exception o){
        }
        
        try { 
        } catch (Exception o){
        }
        

        
        
        
    }
    
}
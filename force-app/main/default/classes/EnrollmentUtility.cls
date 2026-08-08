public class EnrollmentUtility {

    public EnrollmentUtility() {
        canvas_Enroller_Utility = new CanvasEnrollerUtility();
    }
    
   
    public EnrollmentUtility(CanvasSession session) {
        canvas_Enroller_Utility = new CanvasEnrollerUtility(session);
    }


    public Boolean IsReady {get {return canvas_Enroller_Utility.IsReady;}}

    private CanvasEnrollerUtility canvas_Enroller_Utility;
    
    public EnrollmentResults EnrollLeads(Canvas_Course__c courseparm, List<EnrollmentRequest> requestsreceived, String creationProcess) {

        EnrollmentResults results = new EnrollmentResults();
        Map<id,CanvasEnrollerResult> CanvasEnrollments = new Map<id,CanvasEnrollerResult>();
        
        if (requestsreceived.size() > 0) {
            
            DateTime enrolldt = System.now();
            List<Canvas_Enrollment__c> newenrollments = new List<Canvas_Enrollment__c>();
            Map<Id,EnrollmentRequest> processedRequests = new Map<Id,EnrollmentRequest>();
            
            Canvas_Course__c canvas_course = [SELECT Id, Name, Canvas_ID__c, Lead_Field__c FROM Canvas_Course__c WHERE Id = :courseparm.Id];
            
            //First Iteration - through each Request and try to create/get an enrollment from Canvas and populate the CanvasEnrollments collection
            for(EnrollmentRequest requestreceived : requestsreceived) {
            	CanvasEnrollerResult enrollerresult = null;
                try {

                    System.debug(LoggingLevel.DEBUG,'EnrollmentUtility Enrolling : ' + JSON.serialize(requestreceived));

                    enrollerresult = canvas_Enroller_Utility.EnrollUserinCourse(canvas_course.Canvas_ID__c, requestreceived.LeadEnrolled.Email, requestreceived.LeadEnrolled.Name);
                    CanvasEnrollments.put(requestreceived.LeadEnrolled.Id,enrollerresult);
                } catch (Exception e) {

                    System.debug(LoggingLevel.ERROR,'EnrollmentUtility Exception: ' + e.getMessage());

                    requestreceived.Message = e.getMessage();
                }
                
            }            
            
            Canvas_Enrollment_Batch__c newbatch = new Canvas_Enrollment_Batch__c();
            newbatch.Canvas_Course__c = courseparm.Id ;
            newbatch.Enrolled_Date__c = enrolldt;
            newbatch.CreationProcess__c = creationProcess;
            
            System.debug('Setting a SavePoint...');
            Savepoint sp = Database.setSavepoint();

            try {

                //insert newbatch;

                //Second Iteration - through each request and update Salesforce records with the enrollments processed in the first iteration
                for(EnrollmentRequest requestreceived : requestsreceived) {

                    //Use cases:
                    CanvasEnrollerResult enrollerresult = null;
                    
                    enrollerresult = CanvasEnrollments.get(requestreceived.LeadEnrolled.Id);
                    
                    //Test without using the API Calls...
                    //enrollerresult = new CanvasEnrollerResult();
                    //enrollerresult.FoundExisting = false;
                    //string jsonStr = CanvasObjectFactory.getTestUserEnrollmentResponse();
                    //List<CanvasUserEnrollment> testenrollments = CanvasObjectFactory.getCanvasUserEnrollments(jsonStr);
                    //enrollerresult.CanvasUserEnrollment = testenrollments[0];

                    if (enrollerresult != null) {
                        if (enrollerresult.CanvasUserEnrollment != null) {
                            Canvas_Enrollment__c oldenrollment = null;
                           //Use case 1 - Existing enrollment in Canvas.  Check to see if it is also in Salesforce.
                           	System.debug(enrollerresult);
                            if (enrollerresult.FoundExisting != null && enrollerresult.FoundExisting) {
								requestreceived.Message = 'Already in Canvas';
                                try {
                                    oldenrollment = [SELECT Id, Name, Canvas_Enrollment_Batch__c, Enrolled_Date__c, Lead__c
                                                     FROM Canvas_Enrollment__c 
                                                     WHERE Canvas_ID__c = :enrollerresult.CanvasUserEnrollment.id];
                                    
                                } catch (Exception o) {
                                    
                                }
                            }
                            if (oldenrollment == null) {
                                //Creating a new enrollment record.
                                Canvas_Enrollment__c newenrollment = new Canvas_Enrollment__c(
                                    Canvas_Course__c = courseparm.Id,
                                    Canvas_Id__c = enrollerresult.CanvasUserEnrollment.id,
                                    Enrolled_Date__c = enrollerresult.CanvasUserEnrollment.created_at,
                                    Lead__c = requestreceived.LeadEnrolled.Id,
                                    Lead__r = requestreceived.LeadEnrolled
                                );
		                        newenrollments.add(newenrollment);
                            } else {
                                requestreceived.Canvas_Enrollment = oldenrollment;
								requestreceived.Message = 'Already Enrolled in Salesforce';                 
                            }

                            //if (canvas_course.Canvas_ID__c == '6') {
	                        //    requestreceived.LeadEnrolled.Machine_Training__c = enrollerresult.CanvasUserEnrollment.created_at;
                            //}
                            if (String.isNotEmpty(canvas_course.Lead_Field__c)) {
                                try {
	                                requestreceived.LeadEnrolled.put(canvas_course.Lead_Field__c,enrollerresult.CanvasUserEnrollment.created_at);
                                } catch(Exception e) {
                                    
                                }
                            }
                            
                            requestreceived.LeadEnrolled.Canvas_Id__c = enrollerresult.CanvasUserEnrollment.user_id;
                            update requestreceived.LeadEnrolled ;
                        
                        } else {
							requestreceived.Message = 'Could not get a CanvasUserEnrollment.';                 
                        }
                    }
                    
                    processedRequests.put(requestreceived.LeadEnrolled.Id,requestreceived);

                }
                
                insert newbatch;
                for (Canvas_Enrollment__c enrollment : newenrollments) {
                    enrollment.Canvas_Enrollment_Batch__c = newbatch.Id;
                }
                
                
                insert newenrollments;
                results.Message = 'Finished';
                results.Enrollment_Batch = newbatch;

				//Get the Saved Enrollments to Return
                List<Canvas_Enrollment__c> savedenrollments = [SELECT Id, 
                                                            Name,
                                                            Lead__c
                                                            FROM Canvas_Enrollment__c
                                                            WHERE Canvas_Enrollment_Batch__c = :newbatch.Id ];

                for (Canvas_Enrollment__c savedenrollment : savedenrollments) {
                    EnrollmentRequest request = processedRequests.get(savedenrollment.Lead__c);
                    request.Canvas_Enrollment = savedenrollment;
                    request.Course = courseparm;
                    if (!String.isNotEmpty(request.Message)){
	                    request.Message = 'New Enrollment';
                    }
                }
                
                results.ProcessedRequests = processedRequests.values();
                
                

            } catch(Exception o) {

				System.debug(o);
                Database.rollback(sp);
                results.Message = o.getMessage();
                
            }
            
        } else {
            results.Message = 'No Leads to enroll';
        }
        
        return results;
        
    }
    
    
    
}
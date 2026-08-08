public class CanvasEnrollmentQueueable implements Queueable, Database.AllowsCallouts {

    private List<Id> campaignMemberIds;

    public CanvasEnrollmentQueueable(List<Id> campaignMemberIds) {
        this.campaignMemberIds = (campaignMemberIds == null) ? new List<Id>() : campaignMemberIds;
    }

    public void execute(QueueableContext context) {

        System.debug(LoggingLevel.DEBUG,
            'CanvasEnrollmentQueueable: START jobId=' + context.getJobId() +
            ' | campaignMemberIds=' + campaignMemberIds.size()
        );

        if (campaignMemberIds.isEmpty()) {
            System.debug(LoggingLevel.DEBUG, 'CanvasEnrollmentQueueable: No CM ids provided. Exiting.');
            return;
        }

        //
        // Step 1: Load CampaignMembers (LeadId + Status are the key inputs)
        //
        List<CampaignMember> cms = [
            SELECT Id, LeadId, Status
            FROM CampaignMember
            WHERE Id IN :campaignMemberIds
        ];

        System.debug(LoggingLevel.DEBUG,
            'CanvasEnrollmentQueueable: Loaded CampaignMembers=' + cms.size()
        );

        // Collect unique trimmed statuses + lead ids
        Set<String> statuses = new Set<String>();
        Set<Id> leadIds = new Set<Id>();

        // Also keep a list of "work items" we intend to process
        // (only those with both LeadId and non-blank Status)
        List<CampaignMember> eligibleCms = new List<CampaignMember>();

        for (CampaignMember cm : cms) {
            if (cm.LeadId == null || String.isBlank(cm.Status)) {
                continue;
            }

            String statusKey = cm.Status.trim();
            if (statusKey.length() == 0) {
                continue;
            }

            eligibleCms.add(cm);
            statuses.add(statusKey);
            leadIds.add(cm.LeadId);
        }

        System.debug(LoggingLevel.DEBUG,
            'CanvasEnrollmentQueueable: Eligible CampaignMembers=' + eligibleCms.size() +
            ' | Unique statuses=' + statuses.size() +
            ' | Unique leads=' + leadIds.size()
        );

        if (eligibleCms.isEmpty()) {
            System.debug(LoggingLevel.DEBUG, 'CanvasEnrollmentQueueable: No eligible campaign members. Exiting.');
            return;
        }

        //
        // Step 2: Status -> Canvas_Course_Package__c (via Package_Name__c)
        //

        System.debug('Queueable statuses being queried: ' + statuses);


        List<Canvas_Course_Package__c> packages = [
            SELECT Id, Package_Name__c
            FROM Canvas_Course_Package__c
            WHERE Package_Name__c IN :statuses
        ];

        Map<String, Canvas_Course_Package__c> packageByName = new Map<String, Canvas_Course_Package__c>();
        Set<Id> packageIds = new Set<Id>();

        for (Canvas_Course_Package__c p : packages) {
            if (String.isBlank(p.Package_Name__c)) continue;
            String key = p.Package_Name__c.trim();
            if (key.length() == 0) continue;

            packageByName.put(key, p);
            packageIds.add(p.Id);
        }

        System.debug(LoggingLevel.DEBUG,
            'CanvasEnrollmentQueueable: Packages matched=' + packages.size() +
            ' | Package ids=' + packageIds.size()
        );

        if (packageIds.isEmpty()) {
            System.debug(LoggingLevel.WARN,
                'CanvasEnrollmentQueueable: No Canvas_Course_Package__c records matched statuses. Exiting.'
            );
            return;
        }

        //
        // Step 3: Package -> Courses via junction Course_Package_Course__c
        //
        List<Course_Package_Course__c> links = [
            SELECT Id,
                   Canvas_Course_Package__c,
                   Canvas_Course__c,
                   Canvas_Course__r.Name,
                   Canvas_Course__r.Canvas_ID__c,
                   Canvas_Course__r.Lead_Field__c
            FROM Course_Package_Course__c
            WHERE Canvas_Course_Package__c IN :packageIds
        ];

        System.debug(LoggingLevel.DEBUG,
            'CanvasEnrollmentQueueable: Junction links loaded=' + links.size()
        );

        // Map packageId -> list of Canvas_Course__c (SObjects) for that package
        Map<Id, List<Canvas_Course__c>> coursesByPackageId = new Map<Id, List<Canvas_Course__c>>();

        // Also build a unique set of course ids to query full objects later (optional)
        // but since we already have Canvas_Course__r fields via relationship,
        // we can materialize minimal Canvas_Course__c objects directly from those.
        for (Course_Package_Course__c link : links) {
            if (link.Canvas_Course_Package__c == null || link.Canvas_Course__c == null) continue;

            if (!coursesByPackageId.containsKey(link.Canvas_Course_Package__c)) {
                coursesByPackageId.put(link.Canvas_Course_Package__c, new List<Canvas_Course__c>());
            }

            // Build a lightweight Canvas_Course__c to pass to EnrollmentUtility
            Canvas_Course__c course = new Canvas_Course__c(
                Id = link.Canvas_Course__c,
                Name = link.Canvas_Course__r != null ? link.Canvas_Course__r.Name : null,
                Canvas_ID__c = link.Canvas_Course__r != null ? link.Canvas_Course__r.Canvas_ID__c : null,
                Lead_Field__c = link.Canvas_Course__r != null ? link.Canvas_Course__r.Lead_Field__c : null
            );

            coursesByPackageId.get(link.Canvas_Course_Package__c).add(course);
        }

        //
        // Step 4: DataSet1 (Lead Enrollment Package)
        //         leadId -> list of courses (derived from that lead's status -> package -> courses)
        //
        Map<Id, List<Canvas_Course__c>> coursesByLeadId = new Map<Id, List<Canvas_Course__c>>();

        Integer missingPackageCount = 0;
        Integer noCoursesCount = 0;

        for (CampaignMember cm : eligibleCms) {
            String statusKey = cm.Status.trim();
            Canvas_Course_Package__c pkg = packageByName.get(statusKey);

            if (pkg == null) {
                missingPackageCount++;
                continue;
            }

            List<Canvas_Course__c> pkgCourses = coursesByPackageId.get(pkg.Id);
            if (pkgCourses == null || pkgCourses.isEmpty()) {
                noCoursesCount++;
                continue;
            }

            if (!coursesByLeadId.containsKey(cm.LeadId)) {
                coursesByLeadId.put(cm.LeadId, new List<Canvas_Course__c>());
            }

            // Add courses (note: may include duplicates across multiple CMs for same lead)
            coursesByLeadId.get(cm.LeadId).addAll(pkgCourses);
        }

        System.debug(LoggingLevel.DEBUG,
            'CanvasEnrollmentQueueable: DataSet1 coursesByLeadId leads=' + coursesByLeadId.size() +
            ' | missingPackageCount=' + missingPackageCount +
            ' | noCoursesCount=' + noCoursesCount
        );

        if (coursesByLeadId.isEmpty()) {
            System.debug(LoggingLevel.WARN,
                'CanvasEnrollmentQueueable: No lead->course work items were produced. Exiting.'
            );
            return;
        }

        //
        // Step 5: DataSet2 (Course Enrollment Package)
        //         courseId -> set of leadIds
        //
        Map<Id, Set<Id>> leadIdsByCourseId = new Map<Id, Set<Id>>();

        // Also keep one canonical course object per courseId to pass into EnrollLeads(...)
        Map<Id, Canvas_Course__c> courseById = new Map<Id, Canvas_Course__c>();

        for (Id leadId : coursesByLeadId.keySet()) {
            for (Canvas_Course__c course : coursesByLeadId.get(leadId)) {
                if (course == null || course.Id == null) continue;

                if (!leadIdsByCourseId.containsKey(course.Id)) {
                    leadIdsByCourseId.put(course.Id, new Set<Id>());
                }
                leadIdsByCourseId.get(course.Id).add(leadId);

                // Save one instance as the canonical course payload
                if (!courseById.containsKey(course.Id)) {
                    courseById.put(course.Id, course);
                }
            }
        }

        System.debug(LoggingLevel.DEBUG,
            'CanvasEnrollmentQueueable: DataSet2 unique courses=' + leadIdsByCourseId.size()
        );

        //
        // Step 6: Query Leads once (so EnrollmentRequest.LeadEnrolled can be a real Lead)
        //
        Map<Id, Lead> leadsById = new Map<Id, Lead>([
            SELECT Id, Email, FirstName, LastName, Company, Name
            FROM Lead
            WHERE Id IN :leadIds
        ]);

        System.debug(LoggingLevel.DEBUG,
            'CanvasEnrollmentQueueable: Loaded Leads=' + leadsById.size()
        );

        //
        // Step 7: Create session + EnrollmentUtility
        //
        CanvasSession session;
        try {
            session = CanvasSessionFactory.createFromDefault();
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'CanvasEnrollmentQueueable: Failed to create CanvasSession. ' + e.getMessage()
            );
            System.debug(LoggingLevel.ERROR, e.getStackTraceString());
            return;
        }

        if (session == null || !session.isReady()) {
            System.debug(LoggingLevel.ERROR,
                'CanvasEnrollmentQueueable: CanvasSession is null or not ready. Exiting.'
            );
            return;
        }

        EnrollmentUtility util;
        try {
            util = new EnrollmentUtility(session);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'CanvasEnrollmentQueueable: Failed to construct EnrollmentUtility. ' + e.getMessage()
            );
            System.debug(LoggingLevel.ERROR, e.getStackTraceString());
            return;
        }

        //
        // Step 8: For each course, create EnrollmentRequests and call EnrollLeads(...)
        //
        Integer enrollCallCount = 0;

        for (Id courseId : leadIdsByCourseId.keySet()) {

            Canvas_Course__c course = courseById.get(courseId);
            if (course == null) {
                continue;
            }

            Set<Id> leadsForCourse = leadIdsByCourseId.get(courseId);
            if (leadsForCourse == null || leadsForCourse.isEmpty()) {
                continue;
            }

            List<EnrollmentRequest> requests = new List<EnrollmentRequest>();

            for (Id leadId : leadsForCourse) {
                Lead l = leadsById.get(leadId);
                if (l == null) {
                    // Lead not found (deleted?) - skip
                    continue;
                }

                EnrollmentRequest req = new EnrollmentRequest();
                req.LeadEnrolled = l;
                requests.add(req);
            }

            if (requests.isEmpty()) {
                System.debug(LoggingLevel.WARN,
                    'CanvasEnrollmentQueueable: No enrollment requests created for courseId=' + courseId
                );
                continue;
            }

            System.debug(LoggingLevel.DEBUG,
                'CanvasEnrollmentQueueable: Enrolling leads for courseId=' + courseId +
                ' | courseName="' + course.Name + '"' +
                ' | Canvas_ID__c=' + course.Canvas_ID__c +
                ' | requestCount=' + requests.size()
            );

            try {
                util.EnrollLeads(course, requests, 'CampaignMember Queueable');
                enrollCallCount++;
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR,
                    'CanvasEnrollmentQueueable: Enrollment call failed for courseId=' + courseId +
                    ' | ' + e.getMessage()
                );
                System.debug(LoggingLevel.ERROR, e.getStackTraceString());
                // Continue processing other courses
            }
        }

        System.debug(LoggingLevel.DEBUG,
            'CanvasEnrollmentQueueable: END. EnrollLeads calls=' + enrollCallCount
        );
    }
}
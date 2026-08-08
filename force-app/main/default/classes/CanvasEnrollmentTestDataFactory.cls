@IsTest
public class CanvasEnrollmentTestDataFactory {

    public class SeedResult {
        public Lead lead;
        public Campaign campaign;
        public Canvas_Course_Package__c pkg;
        public Canvas_Course__c course;
        public Course_Package_Course__c link;
    }

    /**
     * Seeds the minimum graph needed for:
     * - CanvasSessionFactory.createFromDefault() (Canvas_Settings__c + Canvas_User__c)
     * - Status -> Package -> Junction -> Course resolution
     */
    public static SeedResult seed() {

        // --- Canvas Settings ---
        // Make it unique-ish to avoid collisions across tests
        String defaultName = 'Default Canvas User - ' + String.valueOf(DateTime.now().getTime());

        // --- Canvas Settings ---
        // Adjust field API names if yours differ (these are from your earlier refactor context)
        Canvas_Settings__c settings = new Canvas_Settings__c(
            Canvas_Install_URL__c = 'https://canvas.example.edu',
            API_Root_Endpoint__c  = '/api/v1'
        );
        insert settings;

        // --- Default Canvas User mapping ---
        // This record is used by CanvasSessionFactory.createFromDefault()
        Canvas_User__c defaultUser = new Canvas_User__c(
            OwnerId = UserInfo.getUserId(),
            Alpha_Tag__c = 'DEFAULT_ACCESS_TOKEN',
            Beta_Tag__c  = 'DEFAULT_REFRESH_TOKEN'
        );
        insert defaultUser;

        // Re-query to get auto-number Name populated
        defaultUser = [
            SELECT Id, Name, OwnerId, Alpha_Tag__c, Beta_Tag__c
            FROM Canvas_User__c
            WHERE Id = :defaultUser.Id
        ];        

        System.debug(LoggingLevel.INFO,
            'Created a default User Canvas_User__c =' + JSON.serialize(defaultUser)
        );

        // Now set settings.DefaultUserName__c to the auto-generated Name value
        settings.DefaultUserName__c = defaultUser.Name;
        update settings;


        // --- Lead ---
        Lead l = new Lead(
            LastName = 'QueueableTest',
            Company  = 'TestCo',
            Email    = 'test+cm@sandbox.example'
        );
        insert l;

        // --- Campaign ---
        Campaign c = new Campaign(
            Name = 'Test Canvas Enrollment',
            IsActive = true
        );
        insert c;

        System.debug('DEBUG: Statuses immediately after Campaign insert: ' +
            [SELECT Id, Label, IsDefault, SortOrder
            FROM CampaignMemberStatus
            WHERE CampaignId = :c.Id
            ORDER BY SortOrder]
        );


        // --- Campaign Member Status ---
        // Ensure the status exists for this Campaign (avoid DUPLICATE_VALUE)
        List<CampaignMemberStatus> existing = [
            SELECT Id, Label, HasResponded, SortOrder, IsDefault
            FROM CampaignMemberStatus
            WHERE CampaignId = :c.Id
            AND Label = 'Course Package 1'
            LIMIT 1
        ];

        if (existing.isEmpty()) {

            System.debug('DEBUG: Inserting CampaignMemberStatus for Campaign Id=' + c.Id);

            CampaignMemberStatus cms = new CampaignMemberStatus(
                CampaignId   = c.Id,
                Label        = 'Course Package 1',
                HasResponded = true,
                SortOrder    = 99
                // Do NOT set IsDefault unless you need it
            );
            insert cms;
        } else {
            System.debug('DEBUG: CampaignMemberStatus already exists for Campaign Id=' + c.Id);
        }



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

        // Hard assertion that we actually got an Id
        System.assertNotEquals(null, pkg.Id, 'Expected pkg.Id after insert');

        // Re-query to confirm what got stored
        Canvas_Course_Package__c pkgCheck = [
            SELECT Id, Package_Name__c
            FROM Canvas_Course_Package__c
            WHERE Id = :pkg.Id
            LIMIT 1
        ];

        System.debug('TEST DEBUG: Inserted Package.Id=' + pkgCheck.Id + ' Package_Name__c=[' + pkgCheck.Package_Name__c + ']');


        // --- Course ---
        Canvas_Course__c course = new Canvas_Course__c(
            Name = 'Course 101',
            Canvas_ID__c = '12345',
            Lead_Field__c = 'Email'
        );
        insert course;

        String unique255 =
            (UserInfo.getUserId() + Datetime.now().getTime())
                .repeat(10)
                .substring(0, 255);

        // --- Junction ---
        Course_Package_Course__c link = new Course_Package_Course__c(
            Canvas_Course_Package__c = pkg.Id,
            Canvas_Course__c = course.Id,
            Unique_Key__c = unique255
        );
        insert link;

        SeedResult r = new SeedResult();
        r.lead = l;
        r.campaign = c;
        r.pkg = pkg;
        r.course = course;
        r.link = link;
        return r;
    }
}
public class CanvasSessionFactory {

    /**
     * Creates a session using the "default" Canvas user configured in Canvas_Settings__c.DefaultUserName__c.
     * Performs:
     *  - SOQL for Canvas_Settings__c (once)
     *  - SOQL for Canvas_User__c (default user lookup)
     *  - HTTP callout via OAuth refresh to obtain access token
     */
    public static CanvasSession createFromDefault() {
        Canvas_Settings__c settings = getSettingsOrThrow();

        System.debug(LoggingLevel.INFO,
            'Canvas_Settings__c =' + JSON.serialize(settings)
        );

        if (String.isBlank(settings.DefaultUserName__c)) {
            throw new ApplicationException('DefaultUserName__c is blank on Canvas_Settings__c.');
        }

        List<Canvas_User__c> users = [
            SELECT OwnerId, Name
            FROM Canvas_User__c
            WHERE Name = :settings.DefaultUserName__c
            LIMIT 1
        ];

        if (users.isEmpty() || users[0].OwnerId == null) {
            throw new ApplicationException(
                'No Canvas user found for default user name: ' + settings.DefaultUserName__c
            );
        }

        return createForUser(settings, users[0].OwnerId);
    }

    /**
     * Creates a session for the current running user.
     * Performs:
     *  - SOQL for Canvas_Settings__c (once)
     *  - HTTP callout via OAuth refresh to obtain access token
     */
    public static CanvasSession createForCurrentUser() {
        return createForUser(UserInfo.getUserId());
    }

    /**
     * Creates a session for a specified Salesforce User Id.
     * This is useful for Queueable jobs and unit tests.
     * Performs:
     *  - SOQL for Canvas_Settings__c (once)
     *  - HTTP callout via OAuth refresh to obtain access token
     */
    public static CanvasSession createForUser(Id userId) {
        Canvas_Settings__c settings = getSettingsOrThrow();
        return createForUser(settings, userId);
    }

    // -------------------------
    // Private helpers
    // -------------------------

    /**
     * Core builder that avoids re-querying settings.
     */
    private static CanvasSession createForUser(Canvas_Settings__c settings, Id userId) {
        String rootEndpoint =
            (settings.Canvas_Install_URL__c == null ? '' : settings.Canvas_Install_URL__c) +
            (settings.API_Root_Endpoint__c == null ? '' : settings.API_Root_Endpoint__c);

        if (String.isBlank(rootEndpoint)) {
            throw new ApplicationException('Canvas root endpoint is blank. Check Canvas_Settings__c.');
        }

        CanvasOAuthUtility oauth = new CanvasOAuthUtility();

        System.debug(LoggingLevel.INFO,
            'Calling oauth.refreshCanvasUserFor with userId =' + JSON.serialize(userId)
        );

        CanvasToken token = oauth.refreshCanvasUserFor(userId);

        if (token == null || String.isBlank(token.access_token)) {
            throw new ApplicationException('Canvas access token refresh returned no access_token.');
        }

        return new CanvasSession(rootEndpoint, token.access_token, userId);
    }

    /**
     * Retrieves the single org-wide settings record.
     * Uses List query to avoid QueryException when no rows exist.
     */
    private static Canvas_Settings__c getSettingsOrThrow() {
        List<Canvas_Settings__c> rows = [
            SELECT Canvas_Install_URL__c, API_Root_Endpoint__c, DefaultUserName__c
            FROM Canvas_Settings__c
            LIMIT 1
        ];

        if (rows.isEmpty()) {
            throw new ApplicationException('No Canvas settings found.');
        }

        return rows[0];
    }
}
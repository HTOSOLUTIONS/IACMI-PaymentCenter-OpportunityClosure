@isTest
public class CanvasSessionTest {

    @isTest
    static void test_constructor_and_isReady_true() {

        // Arrange
        String endpoint = 'https://example.instructure.com/api/v1';
        String token    = 'TEST_ACCESS_TOKEN';
        Id userId       = UserInfo.getUserId();

        // Act
        CanvasSession session = new CanvasSession(endpoint, token, userId);

        // Assert - constructor assignments
        System.assertEquals(endpoint, session.RootEndpoint, 'RootEndpoint should be set');
        System.assertEquals(token, session.AccessToken, 'AccessToken should be set');
        System.assertEquals(userId, session.UserId, 'UserId should be set');

        // Assert - method logic
        System.assertEquals(true, session.isReady(), 'Session should be ready when endpoint and token are present');
    }

    @isTest
    static void test_isReady_false_when_values_blank() {

        Id userId = UserInfo.getUserId();

        // Blank endpoint
        CanvasSession blankEndpoint = new CanvasSession('', 'TOKEN', userId);
        System.assertEquals(false, blankEndpoint.isReady(), 'Blank endpoint should not be ready');

        // Blank token
        CanvasSession blankToken = new CanvasSession('https://example.instructure.com/api/v1', '', userId);
        System.assertEquals(false, blankToken.isReady(), 'Blank token should not be ready');

        // Both blank
        CanvasSession bothBlank = new CanvasSession('', '', userId);
        System.assertEquals(false, bothBlank.isReady(), 'Blank endpoint and token should not be ready');
    }
}
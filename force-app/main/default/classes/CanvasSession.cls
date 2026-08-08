// Utility class to manage Canvas session information
public class CanvasSession {
    public String RootEndpoint { get; private set; }
    public String AccessToken  { get; private set; }
    public Id    UserId        { get; private set; }

    public CanvasSession(String rootEndpoint, String accessToken, Id userId) {
        this.RootEndpoint = rootEndpoint;
        this.AccessToken  = accessToken;
        this.UserId       = userId;
    }

    public Boolean isReady() {
        return String.isNotBlank(RootEndpoint) && String.isNotBlank(AccessToken);
    }
}
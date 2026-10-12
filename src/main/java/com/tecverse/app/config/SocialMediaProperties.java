package com.tecverse.app.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * Credentials and identifiers for the official TECVERSE social media accounts polled
 * by the Media Coverage feature. Bound from {@code tecverse.social.*} properties.
 */
@Component
@ConfigurationProperties(prefix = "tecverse.social")
public class SocialMediaProperties {

    private YouTube youtube = new YouTube();
    private Instagram instagram = new Instagram();
    private Facebook facebook = new Facebook();
    private String metaGraphApiVersion = "v19.0";

    public YouTube getYoutube() {
        return youtube;
    }

    public void setYoutube(YouTube youtube) {
        this.youtube = youtube;
    }

    public Instagram getInstagram() {
        return instagram;
    }

    public void setInstagram(Instagram instagram) {
        this.instagram = instagram;
    }

    public Facebook getFacebook() {
        return facebook;
    }

    public void setFacebook(Facebook facebook) {
        this.facebook = facebook;
    }

    public String getMetaGraphApiVersion() {
        return metaGraphApiVersion;
    }

    public void setMetaGraphApiVersion(String metaGraphApiVersion) {
        this.metaGraphApiVersion = metaGraphApiVersion;
    }

    public static class Instagram {
        private boolean enabled = false;
        private String accessToken;
        private String accountId;
        private String accountName;
        private String userId;

        public boolean isEnabled() {
            return enabled;
        }

        public void setEnabled(boolean enabled) {
            this.enabled = enabled;
        }

        public String getAccessToken() {
            return accessToken;
        }

        public void setAccessToken(String accessToken) {
            this.accessToken = accessToken;
        }

        public String getUserId() {
            return userId;
        }

        public void setUserId(String userId) {
            this.userId = userId;
        }

        public String getAccountId() {
            return accountId == null || accountId.isBlank() ? userId : accountId;
        }

        public void setAccountId(String accountId) {
            this.accountId = accountId;
        }

        public String getAccountName() {
            return accountName;
        }

        public void setAccountName(String accountName) {
            this.accountName = accountName;
        }
    }

    public static class Facebook {
        private boolean enabled = false;
        private String accessToken;
        private String pageId;
        private String pageName;

        public boolean isEnabled() {
            return enabled;
        }

        public void setEnabled(boolean enabled) {
            this.enabled = enabled;
        }

        public String getAccessToken() {
            return accessToken;
        }

        public void setAccessToken(String accessToken) {
            this.accessToken = accessToken;
        }

        public String getPageId() {
            return pageId;
        }

        public void setPageId(String pageId) {
            this.pageId = pageId;
        }

        public String getPageName() {
            return pageName;
        }

        public void setPageName(String pageName) {
            this.pageName = pageName;
        }
    }

    public static class YouTube {
        private boolean enabled = false;
        private String apiKey;
        private String channelId;
        private String channelName;

        public boolean isEnabled() {
            return enabled;
        }

        public void setEnabled(boolean enabled) {
            this.enabled = enabled;
        }

        public String getApiKey() {
            return apiKey;
        }

        public void setApiKey(String apiKey) {
            this.apiKey = apiKey;
        }

        public String getChannelId() {
            return channelId;
        }

        public void setChannelId(String channelId) {
            this.channelId = channelId;
        }

        public String getChannelName() {
            return channelName;
        }

        public void setChannelName(String channelName) {
            this.channelName = channelName;
        }
    }

}

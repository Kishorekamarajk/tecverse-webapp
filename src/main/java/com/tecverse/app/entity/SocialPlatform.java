package com.tecverse.app.entity;

/**
 * Official TECVERSE social media channels that back the Media Coverage section.
 */
public enum SocialPlatform {

    YOUTUBE("YouTube"),
    INSTAGRAM("Instagram"),
    FACEBOOK("Facebook");

    private final String displayName;

    SocialPlatform(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}

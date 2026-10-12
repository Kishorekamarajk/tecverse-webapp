package com.tecverse.app.service;

import java.util.List;

import com.tecverse.app.entity.MediaCoverage;

public interface MediaCoverageService {

    /**
     * The latest stored media coverage posts, newest first, for display on the site.
     * Always served from PostgreSQL so the section stays populated even if every
     * social platform is temporarily unreachable.
     */
    List<MediaCoverage> getLatestMediaCoverage();


    /**
     * Polls every configured {@link com.tecverse.app.fetcher.SocialMediaFetcher} and
     * persists any posts that are not already stored.
     */
    void refreshFromSocialMedia();
}

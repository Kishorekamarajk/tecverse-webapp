package com.tecverse.app.fetcher;

import java.util.List;

import com.tecverse.app.dto.social.SocialPostDto;
import com.tecverse.app.entity.SocialPlatform;

/**
 * Retrieves the latest official TECVERSE posts from a single social media platform.
 * Implementations must never throw - on any failure (auth, network, rate limiting,
 * malformed response) they log the problem and return an empty list so the rest of the
 * Media Coverage refresh can continue uninterrupted.
 */
public interface SocialMediaFetcher {

    SocialPlatform getPlatform();

    List<SocialPostDto> fetchLatestPosts();
}

package com.tecverse.app.dto.social;

import java.time.LocalDateTime;

import com.tecverse.app.entity.SocialPlatform;

/**
 * Normalized representation of a social media post, produced by a
 * {@link com.tecverse.app.fetcher.SocialMediaFetcher} regardless of the source platform's
 * raw response shape.
 */
public record SocialPostDto(
        SocialPlatform platform,
        String postId,
        String sourceName,
        String mediaType,
        String title,
        String description,
        String imageUrl,
        String postUrl,
        LocalDateTime publishedDate
) {
}

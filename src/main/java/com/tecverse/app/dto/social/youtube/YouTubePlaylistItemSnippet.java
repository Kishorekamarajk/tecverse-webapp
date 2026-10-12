package com.tecverse.app.dto.social.youtube;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

@JsonIgnoreProperties(ignoreUnknown = true)
public record YouTubePlaylistItemSnippet(
        String publishedAt,
        String channelTitle,
        String title,
        String description,
        YouTubeThumbnails thumbnails,
        YouTubeResourceId resourceId
) {
}

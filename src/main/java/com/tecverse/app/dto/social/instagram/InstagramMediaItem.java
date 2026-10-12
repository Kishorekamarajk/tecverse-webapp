package com.tecverse.app.dto.social.instagram;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

/**
 * A single item from the Instagram Graph API {@code /{ig-user-id}/media} endpoint.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public record InstagramMediaItem(
        String id,
        String caption,
        @JsonProperty("media_type") String mediaType,
        @JsonProperty("media_url") String mediaUrl,
        @JsonProperty("thumbnail_url") String thumbnailUrl,
        String permalink,
        String timestamp
) {
}

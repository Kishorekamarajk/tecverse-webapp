package com.tecverse.app.dto.social.facebook;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

/**
 * A single item from the Facebook Graph API {@code /{page-id}/posts} endpoint.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public record FacebookPostItem(
        String id,
        String message,
        @JsonProperty("full_picture") String fullPicture,
        @JsonProperty("permalink_url") String permalinkUrl,
        @JsonProperty("created_time") String createdTime
) {
}

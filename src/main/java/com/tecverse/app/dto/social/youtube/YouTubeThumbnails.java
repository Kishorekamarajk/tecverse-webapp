package com.tecverse.app.dto.social.youtube;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

@JsonIgnoreProperties(ignoreUnknown = true)
public record YouTubeThumbnails(
        YouTubeThumbnail medium,
        YouTubeThumbnail high,
        YouTubeThumbnail standard,
        YouTubeThumbnail maxres,
        @JsonProperty("default")
        YouTubeThumbnail defaultThumbnail
) {
}

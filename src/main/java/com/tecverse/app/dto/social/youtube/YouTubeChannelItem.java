package com.tecverse.app.dto.social.youtube;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

@JsonIgnoreProperties(ignoreUnknown = true)
public record YouTubeChannelItem(
        YouTubeChannelContentDetails contentDetails
) {
}

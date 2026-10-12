package com.tecverse.app.dto.social.youtube;

import java.util.List;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

@JsonIgnoreProperties(ignoreUnknown = true)
public record YouTubePlaylistItemsResponse(
        List<YouTubePlaylistItem> items
) {
}

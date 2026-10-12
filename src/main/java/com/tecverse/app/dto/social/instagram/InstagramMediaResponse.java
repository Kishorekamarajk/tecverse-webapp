package com.tecverse.app.dto.social.instagram;

import java.util.List;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

/**
 * Root response of the Instagram Graph API {@code /{ig-user-id}/media} endpoint.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public record InstagramMediaResponse(List<InstagramMediaItem> data) {
}

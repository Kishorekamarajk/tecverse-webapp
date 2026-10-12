package com.tecverse.app.dto.social.facebook;

import java.util.List;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

/**
 * Root response of the Facebook Graph API {@code /{page-id}/posts} endpoint.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public record FacebookPostResponse(List<FacebookPostItem> data) {
}

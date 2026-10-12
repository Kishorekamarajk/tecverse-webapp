package com.tecverse.app.fetcher;

import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Collections;
import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientResponseException;

import com.tecverse.app.config.SocialMediaProperties;
import com.tecverse.app.dto.social.SocialPostDto;
import com.tecverse.app.dto.social.facebook.FacebookPostItem;
import com.tecverse.app.dto.social.facebook.FacebookPostResponse;
import com.tecverse.app.entity.SocialPlatform;

/**
 * Retrieves the latest TECVERSE posts from the Facebook Graph API for a given Page.
 */
@Component
public class FacebookPostFetcher implements SocialMediaFetcher {

    private static final Logger log = LoggerFactory.getLogger(FacebookPostFetcher.class);
    private static final String GRAPH_API_HOST = "https://graph.facebook.com/";
    private static final int MAX_TITLE_LENGTH = 180;

    private final RestClient restClient;
    private final SocialMediaProperties.Facebook config;
    private final String graphApiBaseUrl;

    public FacebookPostFetcher(RestClient socialMediaRestClient, SocialMediaProperties socialMediaProperties) {
        this.restClient = socialMediaRestClient;
        this.config = socialMediaProperties.getFacebook();
        this.graphApiBaseUrl = GRAPH_API_HOST + defaultIfBlank(socialMediaProperties.getMetaGraphApiVersion(), "v19.0");
    }

    @Override
    public SocialPlatform getPlatform() {
        return SocialPlatform.FACEBOOK;
    }

    @Override
    public List<SocialPostDto> fetchLatestPosts() {
        if (!config.isEnabled() || isBlank(config.getAccessToken()) || isBlank(config.getPageId())) {
            log.debug("Facebook fetcher is disabled or not configured; skipping.");
            return Collections.emptyList();
        }

        try {
            FacebookPostResponse response = restClient.get()
                    .uri(graphApiBaseUrl
                                    + "/{pageId}/posts?fields=id,message,full_picture,permalink_url,created_time&limit=10&access_token={accessToken}",
                            config.getPageId(), config.getAccessToken())
                    .retrieve()
                    .body(FacebookPostResponse.class);

            if (response == null || response.data() == null) {
                return Collections.emptyList();
            }

            return response.data().stream()
                    .filter(item -> !isBlank(item.permalinkUrl()))
                    .map(this::toSocialPost)
                    .toList();
        } catch (RestClientResponseException ex) {
            logApiError(ex);
            return Collections.emptyList();
        } catch (ResourceAccessException ex) {
            log.error("Facebook API network interruption: {}", ex.getMessage());
            return Collections.emptyList();
        } catch (Exception ex) {
            log.error("Unexpected error fetching Facebook posts: {}", ex.getMessage(), ex);
            return Collections.emptyList();
        }
    }

    private SocialPostDto toSocialPost(FacebookPostItem item) {
        String message = item.message() == null ? "" : item.message().trim();
        String title = message.isBlank() ? "Facebook Update" : truncate(firstLine(message), MAX_TITLE_LENGTH);
        String description = message.isBlank() ? "View this update on Facebook." : message;

        return new SocialPostDto(
                SocialPlatform.FACEBOOK,
                item.id(),
                defaultIfBlank(config.getPageName(), "Facebook"),
                "POST",
                title,
                description,
                item.fullPicture(),
                item.permalinkUrl(),
                parseTimestamp(item.createdTime())
        );
    }

    private LocalDateTime parseTimestamp(String timestamp) {
        if (isBlank(timestamp)) {
            return LocalDateTime.now();
        }
        try {
            return OffsetDateTime.parse(timestamp, DateTimeFormatter.ISO_OFFSET_DATE_TIME).toLocalDateTime();
        } catch (Exception ex) {
            log.warn("Could not parse Facebook timestamp '{}', defaulting to now.", timestamp);
            return LocalDateTime.now();
        }
    }

    private void logApiError(RestClientResponseException ex) {
        int statusCode = ex.getStatusCode().value();
        if (statusCode == 429) {
            log.warn("Facebook API rate limit exceeded: {}", ex.getMessage());
        } else if (statusCode == 401 || statusCode == 403) {
            log.error("Facebook API authentication failed: {}", ex.getMessage());
        } else {
            log.error("Facebook API returned an error (status {}): {}", statusCode, ex.getMessage());
        }
    }

    private static boolean isBlank(String value) {
        return value == null || value.isBlank();
    }

    private static String firstLine(String text) {
        int newlineIndex = text.indexOf('\n');
        return newlineIndex > 0 ? text.substring(0, newlineIndex) : text;
    }

    private static String truncate(String text, int maxLength) {
        if (text.length() <= maxLength) {
            return text;
        }
        return text.substring(0, maxLength).trim() + "...";
    }

    private static String defaultIfBlank(String value, String fallback) {
        return isBlank(value) ? fallback : value.trim();
    }
}

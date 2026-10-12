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
import com.tecverse.app.dto.social.instagram.InstagramMediaItem;
import com.tecverse.app.dto.social.instagram.InstagramMediaResponse;
import com.tecverse.app.entity.SocialPlatform;

/**
 * Retrieves the latest TECVERSE posts from the Instagram Graph API.
 * Requires a professional (Business/Creator) Instagram account linked to a Facebook Page.
 */
@Component
public class InstagramMediaFetcher implements SocialMediaFetcher {

    private static final Logger log = LoggerFactory.getLogger(InstagramMediaFetcher.class);
    private static final String GRAPH_API_HOST = "https://graph.facebook.com/";
    private static final int MAX_TITLE_LENGTH = 180;

    private final RestClient restClient;
    private final SocialMediaProperties.Instagram config;
    private final String graphApiBaseUrl;

    public InstagramMediaFetcher(RestClient socialMediaRestClient, SocialMediaProperties socialMediaProperties) {
        this.restClient = socialMediaRestClient;
        this.config = socialMediaProperties.getInstagram();
        this.graphApiBaseUrl = GRAPH_API_HOST + defaultIfBlank(socialMediaProperties.getMetaGraphApiVersion(), "v19.0");
    }

    @Override
    public SocialPlatform getPlatform() {
        return SocialPlatform.INSTAGRAM;
    }

    @Override
    public List<SocialPostDto> fetchLatestPosts() {
        if (!config.isEnabled() || isBlank(config.getAccessToken()) || isBlank(config.getAccountId())) {
            log.debug("Instagram fetcher is disabled or not configured; skipping.");
            return Collections.emptyList();
        }

        try {
            InstagramMediaResponse response = restClient.get()
                    .uri(graphApiBaseUrl
                                    + "/{userId}/media?fields=id,caption,media_type,media_url,thumbnail_url,permalink,timestamp&limit=10&access_token={accessToken}",
                            config.getAccountId(), config.getAccessToken())
                    .retrieve()
                    .body(InstagramMediaResponse.class);

            if (response == null || response.data() == null) {
                return Collections.emptyList();
            }

            return response.data().stream()
                    .filter(item -> !isBlank(item.permalink()))
                    .map(this::toSocialPost)
                    .toList();
        } catch (RestClientResponseException ex) {
            logApiError(ex);
            return Collections.emptyList();
        } catch (ResourceAccessException ex) {
            log.error("Instagram API network interruption: {}", ex.getMessage());
            return Collections.emptyList();
        } catch (Exception ex) {
            log.error("Unexpected error fetching Instagram media: {}", ex.getMessage(), ex);
            return Collections.emptyList();
        }
    }

    private SocialPostDto toSocialPost(InstagramMediaItem item) {
        String caption = item.caption() == null ? "" : item.caption().trim();
        String title = caption.isBlank() ? "Instagram Update" : truncate(firstLine(caption), MAX_TITLE_LENGTH);
        String description = caption.isBlank() ? "View this update on Instagram." : caption;
        String imageUrl = !isBlank(item.mediaUrl()) ? item.mediaUrl() : item.thumbnailUrl();

        return new SocialPostDto(
                SocialPlatform.INSTAGRAM,
                item.id(),
                defaultIfBlank(config.getAccountName(), "Instagram"),
                defaultIfBlank(item.mediaType(), "MEDIA"),
                title,
                description,
                imageUrl,
                item.permalink(),
                parseTimestamp(item.timestamp())
        );
    }

    private LocalDateTime parseTimestamp(String timestamp) {
        if (isBlank(timestamp)) {
            return LocalDateTime.now();
        }
        try {
            return OffsetDateTime.parse(timestamp, DateTimeFormatter.ISO_OFFSET_DATE_TIME).toLocalDateTime();
        } catch (Exception ex) {
            log.warn("Could not parse Instagram timestamp '{}', defaulting to now.", timestamp);
            return LocalDateTime.now();
        }
    }

    private void logApiError(RestClientResponseException ex) {
        int statusCode = ex.getStatusCode().value();
        if (statusCode == 429) {
            log.warn("Instagram API rate limit exceeded: {}", ex.getMessage());
        } else if (statusCode == 401 || statusCode == 403) {
            log.error("Instagram API authentication failed: {}", ex.getMessage());
        } else {
            log.error("Instagram API returned an error (status {}): {}", statusCode, ex.getMessage());
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

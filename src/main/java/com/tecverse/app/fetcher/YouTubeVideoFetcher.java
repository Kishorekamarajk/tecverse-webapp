package com.tecverse.app.fetcher;

import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.Collections;
import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientResponseException;
import org.springframework.web.util.HtmlUtils;

import com.tecverse.app.config.SocialMediaProperties;
import com.tecverse.app.dto.social.SocialPostDto;
import com.tecverse.app.dto.social.youtube.YouTubeChannelItem;
import com.tecverse.app.dto.social.youtube.YouTubeChannelsResponse;
import com.tecverse.app.dto.social.youtube.YouTubePlaylistItem;
import com.tecverse.app.dto.social.youtube.YouTubePlaylistItemSnippet;
import com.tecverse.app.dto.social.youtube.YouTubePlaylistItemsResponse;
import com.tecverse.app.dto.social.youtube.YouTubeThumbnail;
import com.tecverse.app.dto.social.youtube.YouTubeThumbnails;
import com.tecverse.app.entity.SocialPlatform;

/**
 * Retrieves the latest official Tec-verse videos from the YouTube Data API.
 */
@Component
public class YouTubeVideoFetcher implements SocialMediaFetcher {

    private static final Logger log = LoggerFactory.getLogger(YouTubeVideoFetcher.class);
    private static final String YOUTUBE_API_BASE_URL = "https://www.googleapis.com/youtube/v3";
    private static final int MAX_TITLE_LENGTH = 180;

    private final RestClient restClient;
    private final SocialMediaProperties.YouTube config;

    public YouTubeVideoFetcher(RestClient socialMediaRestClient, SocialMediaProperties socialMediaProperties) {
        this.restClient = socialMediaRestClient;
        this.config = socialMediaProperties.getYoutube();
    }

    @Override
    public SocialPlatform getPlatform() {
        return SocialPlatform.YOUTUBE;
    }

    @Override
    public List<SocialPostDto> fetchLatestPosts() {
        if (!config.isEnabled() || isBlank(config.getApiKey()) || isBlank(config.getChannelId())) {
            log.debug("YouTube fetcher is disabled or not configured; skipping.");
            return Collections.emptyList();
        }

        try {
            String uploadsPlaylistId = fetchUploadsPlaylistId();
            if (isBlank(uploadsPlaylistId)) {
                log.warn("YouTube uploads playlist could not be resolved for channel {}", config.getChannelId());
                return Collections.emptyList();
            }

            YouTubePlaylistItemsResponse response = restClient.get()
                    .uri(YOUTUBE_API_BASE_URL
                                    + "/playlistItems?part=snippet&playlistId={playlistId}&maxResults=10&key={apiKey}",
                            uploadsPlaylistId, config.getApiKey())
                    .retrieve()
                    .body(YouTubePlaylistItemsResponse.class);

            if (response == null || response.items() == null) {
                return Collections.emptyList();
            }

            return response.items().stream()
                    .filter(item -> item.snippet() != null
                            && item.snippet().resourceId() != null
                            && !isBlank(item.snippet().resourceId().videoId()))
                    .map(this::toSocialPost)
                    .toList();
        } catch (RestClientResponseException ex) {
            logApiError(ex);
            return Collections.emptyList();
        } catch (ResourceAccessException ex) {
            log.error("YouTube API network interruption: {}", ex.getMessage());
            return Collections.emptyList();
        } catch (Exception ex) {
            log.error("Unexpected error fetching YouTube videos: {}", ex.getMessage(), ex);
            return Collections.emptyList();
        }
    }

    private String fetchUploadsPlaylistId() {
        YouTubeChannelsResponse response = restClient.get()
                .uri(YOUTUBE_API_BASE_URL + "/channels?part=contentDetails&id={channelId}&key={apiKey}",
                        config.getChannelId(), config.getApiKey())
                .retrieve()
                .body(YouTubeChannelsResponse.class);

        if (response == null || response.items() == null || response.items().isEmpty()) {
            return null;
        }

        YouTubeChannelItem channel = response.items().get(0);
        if (channel.contentDetails() == null || channel.contentDetails().relatedPlaylists() == null) {
            return null;
        }
        return channel.contentDetails().relatedPlaylists().uploads();
    }

    private SocialPostDto toSocialPost(YouTubePlaylistItem item) {
        YouTubePlaylistItemSnippet snippet = item.snippet();
        String videoId = snippet.resourceId().videoId();
        String title = isBlank(snippet.title())
                ? "YouTube Video"
                : truncate(HtmlUtils.htmlUnescape(snippet.title()).trim(), MAX_TITLE_LENGTH);
        String description = isBlank(snippet.description())
                ? "Watch this video on the official Tec-verse YouTube channel."
                : HtmlUtils.htmlUnescape(snippet.description()).trim();
        String sourceName = defaultIfBlank(config.getChannelName(), snippet.channelTitle());

        return new SocialPostDto(
                SocialPlatform.YOUTUBE,
                videoId,
                defaultIfBlank(sourceName, "YouTube"),
                "VIDEO",
                title,
                description,
                thumbnailUrl(snippet.thumbnails()),
                "https://www.youtube.com/watch?v=" + videoId,
                parseTimestamp(snippet.publishedAt())
        );
    }

    private LocalDateTime parseTimestamp(String publishedAt) {
        if (isBlank(publishedAt)) {
            return LocalDateTime.now();
        }
        try {
            return LocalDateTime.ofInstant(Instant.parse(publishedAt), ZoneOffset.UTC);
        } catch (Exception ex) {
            log.warn("Could not parse YouTube timestamp '{}', defaulting to now.", publishedAt);
            return LocalDateTime.now();
        }
    }

    private String thumbnailUrl(YouTubeThumbnails thumbnails) {
        if (thumbnails == null) {
            return null;
        }
        return firstUrl(
                thumbnails.maxres(),
                thumbnails.standard(),
                thumbnails.high(),
                thumbnails.medium(),
                thumbnails.defaultThumbnail()
        );
    }

    private String firstUrl(YouTubeThumbnail... thumbnails) {
        for (YouTubeThumbnail thumbnail : thumbnails) {
            if (thumbnail != null && !isBlank(thumbnail.url())) {
                return thumbnail.url();
            }
        }
        return null;
    }

    private void logApiError(RestClientResponseException ex) {
        int statusCode = ex.getStatusCode().value();
        if (statusCode == 429) {
            log.warn("YouTube API rate limit exceeded: {}", ex.getMessage());
        } else if (statusCode == 400 || statusCode == 401 || statusCode == 403) {
            log.error("YouTube API authentication or configuration failed: {}", ex.getMessage());
        } else {
            log.error("YouTube API returned an error (status {}): {}", statusCode, ex.getMessage());
        }
    }

    private static boolean isBlank(String value) {
        return value == null || value.isBlank();
    }

    private static String defaultIfBlank(String value, String fallback) {
        return isBlank(value) ? fallback : value.trim();
    }

    private static String truncate(String text, int maxLength) {
        if (text.length() <= maxLength) {
            return text;
        }
        return text.substring(0, maxLength).trim() + "...";
    }
}

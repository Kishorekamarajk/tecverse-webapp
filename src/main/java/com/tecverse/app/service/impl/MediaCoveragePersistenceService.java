package com.tecverse.app.service.impl;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import com.tecverse.app.dto.social.SocialPostDto;
import com.tecverse.app.entity.MediaCoverage;
import com.tecverse.app.entity.SocialPlatform;
import com.tecverse.app.repository.MediaCoverageRepository;

@Service
public class MediaCoveragePersistenceService {

    private static final Logger log = LoggerFactory.getLogger(MediaCoveragePersistenceService.class);
    private static final int TITLE_MAX_LENGTH = 255;
    private static final int POST_ID_MAX_LENGTH = 160;
    private static final int SOURCE_NAME_MAX_LENGTH = 160;
    private static final int MEDIA_TYPE_MAX_LENGTH = 60;
    private static final int URL_MAX_LENGTH = 500;
    private static final List<SocialPlatform> PUBLIC_PLATFORMS =
            List.of(SocialPlatform.YOUTUBE, SocialPlatform.INSTAGRAM, SocialPlatform.FACEBOOK);

    private final MediaCoverageRepository mediaCoverageRepository;

    public MediaCoveragePersistenceService(MediaCoverageRepository mediaCoverageRepository) {
        this.mediaCoverageRepository = mediaCoverageRepository;
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public int savePosts(List<SocialPostDto> posts) {
        if (posts == null || posts.isEmpty()) {
            return 0;
        }

        int changedCount = 0;
        for (SocialPostDto post : posts) {
            if (!isPublishable(post)) {
                continue;
            }

            MediaCoverage entity = findExisting(post).orElseGet(() -> MediaCoverage.builder()
                    .platform(post.platform())
                    .postId(trimToLength(post.postId(), POST_ID_MAX_LENGTH))
                    .build());

            applyPost(entity, post);
            mediaCoverageRepository.save(entity);
            changedCount++;
        }

        if (changedCount > 0) {
            log.info("Saved or updated {} media coverage post(s)", changedCount);
        }
        return changedCount;
    }

    private Optional<MediaCoverage> findExisting(SocialPostDto post) {
        String postId = trimToLength(post.postId(), POST_ID_MAX_LENGTH);
        if (!isBlank(postId)) {
            Optional<MediaCoverage> byPlatformPostId =
                    mediaCoverageRepository.findByPlatformAndPostId(post.platform(), postId);
            if (byPlatformPostId.isPresent()) {
                return byPlatformPostId;
            }
        }
        return mediaCoverageRepository.findByPostUrl(trimToLength(post.postUrl(), URL_MAX_LENGTH));
    }

    private void applyPost(MediaCoverage entity, SocialPostDto dto) {
        entity.setPlatform(dto.platform());
        entity.setPostId(trimToLength(dto.postId(), POST_ID_MAX_LENGTH));
        entity.setSourceName(trimToLength(dto.sourceName(), SOURCE_NAME_MAX_LENGTH));
        entity.setMediaType(trimToLength(dto.mediaType(), MEDIA_TYPE_MAX_LENGTH));
        entity.setTitle(defaultIfBlank(trimToLength(dto.title(), TITLE_MAX_LENGTH), dto.platform().getDisplayName() + " Update"));
        entity.setDescription(clean(dto.description()));
        entity.setImageUrl(trimToLength(dto.imageUrl(), URL_MAX_LENGTH));
        entity.setPostUrl(trimToLength(dto.postUrl(), URL_MAX_LENGTH));
        entity.setPublishedDate(dto.publishedDate() == null ? LocalDateTime.now() : dto.publishedDate());
        entity.setActive(true);
    }

    private boolean isPublishable(SocialPostDto post) {
        return post != null
                && PUBLIC_PLATFORMS.contains(post.platform())
                && !isBlank(post.postUrl());
    }

    private static String clean(String value) {
        return value == null ? null : value.trim();
    }

    private static String defaultIfBlank(String value, String fallback) {
        return isBlank(value) ? fallback : value;
    }

    private static String trimToLength(String value, int maxLength) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        if (trimmed.length() <= maxLength) {
            return trimmed;
        }
        return trimmed.substring(0, maxLength - 3).trim() + "...";
    }

    private static boolean isBlank(String value) {
        return value == null || value.isBlank();
    }
}

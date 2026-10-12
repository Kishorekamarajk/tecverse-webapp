package com.tecverse.app.service.impl;

import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.tecverse.app.dto.social.SocialPostDto;
import com.tecverse.app.entity.MediaCoverage;
import com.tecverse.app.entity.SocialPlatform;
import com.tecverse.app.fetcher.SocialMediaFetcher;
import com.tecverse.app.repository.MediaCoverageRepository;
import com.tecverse.app.service.MediaCoverageService;

@Service
public class MediaCoverageServiceImpl implements MediaCoverageService {

    private static final Logger log = LoggerFactory.getLogger(MediaCoverageServiceImpl.class);
    private static final List<SocialPlatform> PUBLIC_PLATFORMS =
            List.of(SocialPlatform.YOUTUBE, SocialPlatform.INSTAGRAM, SocialPlatform.FACEBOOK);

    private final MediaCoverageRepository mediaCoverageRepository;
    private final MediaCoveragePersistenceService mediaCoveragePersistenceService;
    private final List<SocialMediaFetcher> fetchers;

    public MediaCoverageServiceImpl(MediaCoverageRepository mediaCoverageRepository,
                                    MediaCoveragePersistenceService mediaCoveragePersistenceService,
                                    List<SocialMediaFetcher> fetchers) {
        this.mediaCoverageRepository = mediaCoverageRepository;
        this.mediaCoveragePersistenceService = mediaCoveragePersistenceService;
        this.fetchers = fetchers;
    }

    @Override
    @Transactional(readOnly = true)
    public List<MediaCoverage> getLatestMediaCoverage() {
        return mediaCoverageRepository.findTop20ByActiveTrueAndPlatformInOrderByPublishedDateDesc(PUBLIC_PLATFORMS);
    }

    @Override
    public void refreshFromSocialMedia() {
        for (SocialMediaFetcher fetcher : fetchers) {
            try {
                List<SocialPostDto> posts = fetcher.fetchLatestPosts();
                int savedCount = mediaCoveragePersistenceService.savePosts(posts);
                log.debug("Media coverage refresh finished for {} with {} saved/updated post(s)",
                        fetcher.getPlatform(), savedCount);
            } catch (Exception ex) {
                log.error("Failed to refresh media coverage from {}: {}", fetcher.getPlatform(), ex.getMessage(), ex);
            }
        }
    }
}

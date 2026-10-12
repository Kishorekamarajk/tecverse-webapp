package com.tecverse.app.scheduler;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import com.tecverse.app.service.MediaCoverageService;

/**
 * Keeps the Media Coverage section fresh by polling the official TECVERSE social
 * media accounts every 15 minutes, plus once right after startup so the section isn't
 * empty while waiting for the first scheduled run.
 */
@Component
public class MediaCoverageScheduler {

    private static final Logger log = LoggerFactory.getLogger(MediaCoverageScheduler.class);

    private final MediaCoverageService mediaCoverageService;

    public MediaCoverageScheduler(MediaCoverageService mediaCoverageService) {
        this.mediaCoverageService = mediaCoverageService;
    }

    @EventListener(ApplicationReadyEvent.class)
    public void refreshOnStartup() {
        log.info("Running initial media coverage refresh on startup");
        runSafely("startup");
    }

    @Scheduled(fixedRateString = "${tecverse.social.refresh-rate-ms:900000}")
    public void refreshOnSchedule() {
        log.info("Running scheduled media coverage refresh");
        runSafely("scheduled");
    }

    private void runSafely(String trigger) {
        try {
            mediaCoverageService.refreshFromSocialMedia();
        } catch (Exception ex) {
            log.error("Media coverage {} refresh failed without stopping the application: {}",
                    trigger, ex.getMessage(), ex);
        }
    }
}

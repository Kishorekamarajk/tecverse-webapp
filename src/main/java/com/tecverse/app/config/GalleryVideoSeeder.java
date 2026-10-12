package com.tecverse.app.config;

import java.util.ArrayList;
import java.util.List;

import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;

import com.tecverse.app.entity.GalleryVideo;
import com.tecverse.app.repository.GalleryVideoRepository;

@Component
public class GalleryVideoSeeder implements ApplicationRunner {

    private final GalleryVideoRepository galleryVideoRepository;

    public GalleryVideoSeeder(GalleryVideoRepository galleryVideoRepository) {
        this.galleryVideoRepository = galleryVideoRepository;
    }

    @Override
    public void run(ApplicationArguments args) {
        List<GalleryVideo> videos = new ArrayList<>();

        addIfMissing(videos, "Tec-verse Previous Edition Recap",
                "Highlights from the previous Tec-verse edition.", "vid.mp4", "event1.jpg", 10);
        addIfMissing(videos, "Tec-verse Innovation Showcase",
                "Moments from demos, exhibits, and delegate interactions.", "mov.mp4", "event4.jpg", 20);

        if (!videos.isEmpty()) {
            galleryVideoRepository.saveAll(videos);
        }
    }

    private void addIfMissing(List<GalleryVideo> videos, String title, String description, String videoFile,
                              String thumbnailFile, int displayOrder) {
        if (galleryVideoRepository.existsByTitleIgnoreCase(title) || !mediaExists(videoFile)) {
            return;
        }

        GalleryVideo video = new GalleryVideo();
        video.setTitle(title);
        video.setDescription(description);
        video.setVideoUrl("/images/" + videoFile);
        video.setThumbnailUrl(mediaExists(thumbnailFile) ? "/images/" + thumbnailFile : null);
        video.setDisplayOrder(displayOrder);
        video.setActive(true);
        videos.add(video);
    }

    private static boolean mediaExists(String fileName) {
        return new ClassPathResource("static/images/" + fileName).exists();
    }
}

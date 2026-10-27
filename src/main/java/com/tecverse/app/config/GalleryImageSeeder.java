package com.tecverse.app.config;

import java.util.ArrayList;
import java.util.List;

import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import com.tecverse.app.entity.GalleryImage;
import com.tecverse.app.repository.GalleryImageRepository;

@Component
public class GalleryImageSeeder implements ApplicationRunner {

    private final GalleryImageRepository galleryImageRepository;

    public GalleryImageSeeder(GalleryImageRepository galleryImageRepository) {
        this.galleryImageRepository = galleryImageRepository;
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        List<GalleryImage> images = new ArrayList<>();
        List<GalleryImage> existing = galleryImageRepository.findAllByOrderByDisplayOrderAscIdAsc();
        List<String> sampleTitles = List.of("Tec-Verse Previous Edition Highlights", "Inaugural Address",
                "Startup Pavilion", "Tech Demo Zone", "Delegate Meetup");

        for (int number = 1; number <= 26; number++) {
            String fileName = "img" + number + (number <= 3 ? ".jfif" : ".png");
            String imageUrl = "/images/" + fileName;
            String title = "Tec-Verse Gallery Photo " + number;
            if (!imageExists(fileName)) {
                throw new IllegalStateException("Missing gallery photo: " + fileName);
            }
            // Stable titles prevent re-importing photos edited or hidden in the admin UI.
            if (existing.stream().anyMatch(image -> imageUrl.equals(image.getImageUrl())
                    || title.equalsIgnoreCase(image.getTitle()))) {
                continue;
            }
            final int index = number;
            GalleryImage image = existing.stream()
                    .filter(candidate -> index <= sampleTitles.size()
                            && sampleTitles.get(index - 1).equals(candidate.getTitle())
                            && ("/images/event" + index + ".jpg").equals(candidate.getImageUrl()))
                    .findFirst().orElseGet(GalleryImage::new);
            image.setTitle(title);
            image.setCategory("About the Event");
            image.setImageUrl(imageUrl);
            image.setDisplayOrder(number * 10);
            images.add(image);
        }

        if (!images.isEmpty()) {
            galleryImageRepository.saveAll(images);
        }
    }

    private static boolean imageExists(String fileName) {
        return new ClassPathResource("static/images/" + fileName).exists();
    }
}

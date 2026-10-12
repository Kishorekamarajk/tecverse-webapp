package com.tecverse.app.dto;

import java.util.List;

public record GalleryContentResponse(
        List<ImageItem> images,
        List<VideoItem> videos,
        List<SpeakerItem> speakers
) {
    public record ImageItem(Long id, String title, String category, String imageUrl, int displayOrder) {
    }

    public record VideoItem(Long id, String title, String description, String videoUrl, String thumbnailUrl,
                            int displayOrder) {
    }

    public record SpeakerItem(Long id, String name, String designation, String sessionTiming, String organization,
                              String profileImageUrl, int displayOrder) {
    }
}

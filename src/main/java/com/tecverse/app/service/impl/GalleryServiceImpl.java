package com.tecverse.app.service.impl;

import java.util.List;

import org.springframework.stereotype.Service;

import com.tecverse.app.dto.GalleryContentResponse;
import com.tecverse.app.dto.GalleryContentResponse.ImageItem;
import com.tecverse.app.dto.GalleryContentResponse.VideoItem;
import com.tecverse.app.entity.GalleryImage;
import com.tecverse.app.entity.GalleryVideo;
import com.tecverse.app.repository.GalleryImageRepository;
import com.tecverse.app.repository.GalleryVideoRepository;
import com.tecverse.app.service.GalleryService;

@Service
public class GalleryServiceImpl implements GalleryService {

    private final GalleryImageRepository galleryImageRepository;
    private final GalleryVideoRepository galleryVideoRepository;

    public GalleryServiceImpl(GalleryImageRepository galleryImageRepository,
                              GalleryVideoRepository galleryVideoRepository) {
        this.galleryImageRepository = galleryImageRepository;
        this.galleryVideoRepository = galleryVideoRepository;
    }

    @Override
    public GalleryContentResponse getActiveGalleryContent() {
        return new GalleryContentResponse(
                galleryImageRepository.findByActiveTrueOrderByDisplayOrderAscIdAsc()
                        .stream()
                        .map(GalleryServiceImpl::imageItem)
                        .toList(),
                galleryVideoRepository.findByActiveTrueOrderByDisplayOrderAscIdAsc()
                        .stream()
                        .map(GalleryServiceImpl::videoItem)
                        .toList(),
                List.of()
        );
    }

    private static ImageItem imageItem(GalleryImage image) {
        return new ImageItem(image.getId(), image.getTitle(), image.getCategory(), image.getImageUrl(),
                image.getDisplayOrder());
    }

    private static VideoItem videoItem(GalleryVideo video) {
        return new VideoItem(video.getId(), video.getTitle(), video.getDescription(), video.getVideoUrl(),
                video.getThumbnailUrl(), video.getDisplayOrder());
    }

}

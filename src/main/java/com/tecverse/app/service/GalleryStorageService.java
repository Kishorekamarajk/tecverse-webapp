package com.tecverse.app.service;

import org.springframework.web.multipart.MultipartFile;
import java.util.List;

public interface GalleryStorageService {

    String uploadImage(MultipartFile file, String folder);
    List<String> uploadImages(List<MultipartFile> files, String folder);
    List<String> uploadVideos(List<MultipartFile> files, String folder);

    String uploadVideo(MultipartFile file, String folder);

    void deleteStoredMedia(String mediaUrl);
}

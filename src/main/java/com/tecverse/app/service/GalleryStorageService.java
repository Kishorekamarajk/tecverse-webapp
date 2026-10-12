package com.tecverse.app.service;

import org.springframework.web.multipart.MultipartFile;

public interface GalleryStorageService {

    String uploadImage(MultipartFile file, String folder);

    String uploadVideo(MultipartFile file, String folder);
}

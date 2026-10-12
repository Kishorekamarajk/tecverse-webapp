package com.tecverse.app.service.impl;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Locale;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import com.tecverse.app.service.GalleryStorageService;

@Service
public class GalleryStorageServiceImpl implements GalleryStorageService {

    private static final long MAX_IMAGE_SIZE_BYTES = 1024L * 1024L;
    private static final long MAX_VIDEO_SIZE_BYTES = 1024L * 1024L;

    private final Path storageDirectory;
    private final LocalBackgroundRemovalService backgroundRemovalService;

    public GalleryStorageServiceImpl(
            @Value("${tecverse.storage.gallery-dir:uploads/gallery}") String storageDirectory,
            LocalBackgroundRemovalService backgroundRemovalService) {
        this.storageDirectory = Paths.get(storageDirectory).toAbsolutePath().normalize();
        this.backgroundRemovalService = backgroundRemovalService;
    }

    @Override
    public String uploadImage(MultipartFile file, String folder) {
        return upload(file, folder, true);
    }

    @Override
    public String uploadVideo(MultipartFile file, String folder) {
        return upload(file, folder, false);
    }

    private String upload(MultipartFile file, String folder, boolean image) {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("Please choose a file to upload.");
        }
        if (image && file.getSize() > MAX_IMAGE_SIZE_BYTES) {
            throw new IllegalArgumentException("Image must be 1 MB or smaller.");
        }
        if (!image && file.getSize() > MAX_VIDEO_SIZE_BYTES) {
            throw new IllegalArgumentException("Video must be 1 MB or smaller.");
        }
        if (!isSupportedFile(file.getContentType(), file.getOriginalFilename(), image)) {
            throw new IllegalArgumentException(image
                    ? "Choose a JPG, PNG, WEBP, or GIF image."
                    : "Choose an MP4, WEBM, OGG, or MOV video.");
        }

        String safeFolder = folder == null ? "media" : folder.replaceAll("[^A-Za-z0-9_-]", "_");
        Path targetDirectory = storageDirectory.resolve(safeFolder).normalize();
        if (!targetDirectory.startsWith(storageDirectory)) {
            throw new IllegalArgumentException("Invalid upload folder.");
        }

        try {
            Files.createDirectories(targetDirectory);
            byte[] content = file.getBytes();
            String outputExtension = extension(file.getOriginalFilename(), image);
            if (image && ("speakers".equals(safeFolder) || "chief-guests".equals(safeFolder))) {
                content = backgroundRemovalService.removeBackgroundAndApplyBrandColor(content);
                outputExtension = ".png";
            }

            String fileName = UUID.randomUUID() + outputExtension;
            Path target = targetDirectory.resolve(fileName).normalize();
            Files.write(target, content);
            return "/uploads/gallery/" + safeFolder + "/" + fileName;
        } catch (IOException ex) {
            throw new IllegalStateException("Unable to save uploaded media.", ex);
        }
    }

    private static String extension(String fileName, boolean image) {
        String fallback = image ? ".jpg" : ".mp4";
        if (fileName == null) {
            return fallback;
        }
        int dotIndex = fileName.lastIndexOf('.');
        if (dotIndex < 0 || dotIndex == fileName.length() - 1) {
            return fallback;
        }
        String extension = fileName.substring(dotIndex).toLowerCase(Locale.ENGLISH);
        if (image) {
            return extension.matches("\\.(jpg|jpeg|png|webp|gif)") ? extension : fallback;
        }
        return extension.matches("\\.(mp4|webm|ogg|mov)") ? extension : fallback;
    }

    private static boolean isSupportedFile(String contentType, String fileName, boolean image) {
        if (contentType == null || fileName == null) return false;
        int dot = fileName.lastIndexOf('.');
        if (dot < 0 || dot == fileName.length() - 1) return false;
        String mime = contentType.toLowerCase(Locale.ENGLISH);
        String ext = fileName.substring(dot).toLowerCase(Locale.ENGLISH);
        if (image) {
            return switch (ext) {
                case ".jpg", ".jpeg" -> mime.equals("image/jpeg") || mime.equals("image/jpg");
                case ".png" -> mime.equals("image/png");
                case ".webp" -> mime.equals("image/webp");
                case ".gif" -> mime.equals("image/gif");
                default -> false;
            };
        }
        return switch (ext) {
            case ".mp4" -> mime.equals("video/mp4");
            case ".webm" -> mime.equals("video/webm");
            case ".ogg" -> mime.equals("video/ogg");
            case ".mov" -> mime.equals("video/quicktime");
            default -> false;
        };
    }
}

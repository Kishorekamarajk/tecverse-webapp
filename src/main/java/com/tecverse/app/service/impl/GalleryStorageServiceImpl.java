package com.tecverse.app.service.impl;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Locale;
import java.util.ArrayList;
import java.util.List;
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
    public List<String> uploadImages(List<MultipartFile> files, String folder) {
        return uploadMany(files, folder, true);
    }

    @Override
    public List<String> uploadVideos(List<MultipartFile> files, String folder) {
        return uploadMany(files, folder, false);
    }

    private List<String> uploadMany(List<MultipartFile> files, String folder, boolean image) {
        List<MultipartFile> selected = files == null ? List.of()
                : files.stream().filter(file -> file != null && !file.isEmpty()).toList();
        String media = image ? "image" : "video";
        if (selected.isEmpty()) throw new IllegalArgumentException("Choose at least one " + media + " to upload.");
        if (selected.size() > 20) throw new IllegalArgumentException("Upload no more than 20 " + media + "s at a time.");
        for (MultipartFile file : selected) {
            long maxSize = image ? MAX_IMAGE_SIZE_BYTES : MAX_VIDEO_SIZE_BYTES;
            if (file.getSize() > maxSize) throw new IllegalArgumentException("Each " + media + " must be 1 MB or smaller.");
            if (!isSupportedFile(file.getContentType(), file.getOriginalFilename(), image)) {
                throw new IllegalArgumentException(image
                        ? "Choose JPG, PNG, WEBP, or GIF images only."
                        : "Choose MP4, WEBM, OGG, or MOV videos only.");
            }
        }

        List<String> uploaded = new ArrayList<>(selected.size());
        try {
            for (MultipartFile file : selected) uploaded.add(image ? uploadImage(file, folder) : uploadVideo(file, folder));
            return uploaded;
        } catch (RuntimeException ex) {
            for (String url : uploaded) {
                try {
                    Path storedFile = storageDirectory.resolve(url.substring("/uploads/gallery/".length())).normalize();
                    if (storedFile.startsWith(storageDirectory)) Files.deleteIfExists(storedFile);
                } catch (IOException | RuntimeException ignored) {
                    // Keep the original upload failure as the useful error for the admin.
                }
            }
            throw ex;
        }
    }

    @Override
    public String uploadVideo(MultipartFile file, String folder) {
        return upload(file, folder, false);
    }

    @Override
    public void deleteStoredMedia(String mediaUrl) {
        String prefix = "/uploads/gallery/";
        if (mediaUrl == null || !mediaUrl.startsWith(prefix)) return;

        String relativePath = mediaUrl.substring(prefix.length());
        Path storedFile = storageDirectory.resolve(relativePath).normalize();
        if (!storedFile.startsWith(storageDirectory)) {
            throw new IllegalArgumentException("Invalid stored media path.");
        }

        try {
            Files.deleteIfExists(storedFile);
        } catch (IOException ex) {
            throw new IllegalStateException("Unable to remove uploaded media file.", ex);
        }
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

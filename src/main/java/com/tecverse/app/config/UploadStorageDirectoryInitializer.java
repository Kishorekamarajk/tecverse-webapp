package com.tecverse.app.config;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

@Component
public class UploadStorageDirectoryInitializer implements ApplicationRunner {

    private final Path uploadsDirectory;
    private final Path galleryDirectory;
    private final Path documentsDirectory;
    private final Path backgroundModelDirectory;

    public UploadStorageDirectoryInitializer(
            @Value("${tecverse.storage.uploads-dir:uploads}") String uploadsDirectory,
            @Value("${tecverse.storage.gallery-dir:uploads/gallery}") String galleryDirectory,
            @Value("${tecverse.storage.documents-dir:uploads/exhibitor-documents}") String documentsDirectory,
            @Value("${tecverse.images.background-model-path:${UPLOADS_DIR:C:/tecverse/uploads}/models/u2netp.onnx}")
            String backgroundModelPath) {
        this.uploadsDirectory = Paths.get(uploadsDirectory).toAbsolutePath().normalize();
        this.galleryDirectory = Paths.get(galleryDirectory).toAbsolutePath().normalize();
        this.documentsDirectory = Paths.get(documentsDirectory).toAbsolutePath().normalize();
        Path modelPath = Paths.get(backgroundModelPath).toAbsolutePath().normalize();
        this.backgroundModelDirectory = modelPath.getParent();
    }

    @Override
    public void run(ApplicationArguments args) {
        createDirectory(uploadsDirectory);
        createDirectory(galleryDirectory);
        createDirectory(documentsDirectory);
        if (backgroundModelDirectory != null) {
            createDirectory(backgroundModelDirectory);
        }
    }

    private static void createDirectory(Path directory) {
        try {
            Files.createDirectories(directory);
        } catch (IOException ex) {
            throw new IllegalStateException("Unable to create upload storage directory: " + directory, ex);
        }
    }
}

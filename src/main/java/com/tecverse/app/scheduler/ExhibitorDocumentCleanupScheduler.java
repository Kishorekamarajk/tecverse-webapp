package com.tecverse.app.scheduler;

import java.io.IOException;
import java.nio.file.Path;
import java.time.Duration;
import java.time.Instant;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tecverse.app.entity.Exhibitor;
import com.tecverse.app.entity.TecverseRegistration;
import com.tecverse.app.repository.ExhibitorRepository;
import com.tecverse.app.repository.TecverseRegistrationRepository;
import com.tecverse.app.service.impl.ExhibitorStorageServiceImpl;

@Component
public class ExhibitorDocumentCleanupScheduler {
    private static final Logger log = LoggerFactory.getLogger(ExhibitorDocumentCleanupScheduler.class);
    private static final String PUBLIC_DOCUMENT_PREFIX = "/uploads/documents/";

    private final ExhibitorStorageServiceImpl storage;
    private final ExhibitorRepository exhibitors;
    private final TecverseRegistrationRepository registrations;
    private final ObjectMapper objectMapper;
    private final Path storageDirectory;
    private final long graceHours;

    public ExhibitorDocumentCleanupScheduler(
            ExhibitorStorageServiceImpl storage,
            ExhibitorRepository exhibitors,
            TecverseRegistrationRepository registrations,
            ObjectMapper objectMapper,
            @Value("${tecverse.storage.documents-dir:uploads/exhibitor-documents}") String storageDirectory,
            @Value("${tecverse.storage.documents-orphan-grace-hours:24}") long graceHours) {
        this.storage = storage;
        this.exhibitors = exhibitors;
        this.registrations = registrations;
        this.objectMapper = objectMapper;
        this.storageDirectory = Path.of(storageDirectory).toAbsolutePath().normalize();
        if (graceHours < 1) throw new IllegalArgumentException("Document orphan grace period must be at least one hour.");
        this.graceHours = graceHours;
    }

    @Scheduled(cron = "${tecverse.storage.documents-cleanup-cron:0 0 2 * * *}")
    public void cleanupOrphanedDocuments() {
        try {
            Set<Path> retained = referencedFiles();
            long removedBytes = storage.cleanupOrphanedFiles(retained,
                    Instant.now().minus(Duration.ofHours(graceHours)));
            log.info("Exhibitor document cleanup removed {} bytes; {} referenced files were retained.",
                    removedBytes, retained.size());
        } catch (Exception failure) {
            // If database references cannot be read, retain files and try again on the next run.
            log.error("Exhibitor document cleanup failed; no cleanup should be considered complete.", failure);
        }
    }

    private Set<Path> referencedFiles() throws IOException {
        Set<Path> retained = new HashSet<>();
        for (Exhibitor exhibitor : exhibitors.findAll()) {
            addPath(retained, exhibitor.getCompanyLogoPath());
            addPath(retained, exhibitor.getDocumentOnePath());
            addPath(retained, exhibitor.getDocumentTwoPath());
            addJsonPaths(retained, exhibitor.getDocumentUrls());
        }
        for (TecverseRegistration registration : registrations.findAll()) {
            addPath(retained, registration.getCompanyLogoUrl());
            addJsonPaths(retained, registration.getDocumentUrls());
        }
        return retained;
    }

    private void addJsonPaths(Set<Path> retained, String serializedPaths) throws IOException {
        if (serializedPaths == null || serializedPaths.isBlank() || "null".equals(serializedPaths)) return;
        List<String> paths = objectMapper.readValue(serializedPaths, new TypeReference<>() {});
        paths.forEach(path -> addPath(retained, path));
    }

    private void addPath(Set<Path> retained, String value) {
        if (value == null) return;
        int prefix = value.indexOf(PUBLIC_DOCUMENT_PREFIX);
        if (prefix < 0) return;
        String relativePath = value.substring(prefix + PUBLIC_DOCUMENT_PREFIX.length());
        Path resolved = storageDirectory.resolve(relativePath).normalize();
        if (resolved.startsWith(storageDirectory)) retained.add(resolved);
    }
}

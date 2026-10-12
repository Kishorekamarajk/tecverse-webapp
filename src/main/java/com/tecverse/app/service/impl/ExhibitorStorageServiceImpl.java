package com.tecverse.app.service.impl;

import java.io.IOException;
import java.io.InputStream;
import java.nio.channels.FileChannel;
import java.nio.channels.FileLock;
import java.nio.file.AtomicMoveNotSupportedException;
import java.nio.file.Files;
import java.nio.file.LinkOption;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.nio.file.StandardOpenOption;
import java.time.Instant;
import java.util.Comparator;
import java.util.Set;
import java.util.UUID;
import java.util.regex.Pattern;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import com.tecverse.app.service.ExhibitorStorageService;

@Service
public class ExhibitorStorageServiceImpl implements ExhibitorStorageService {
	private static final Logger log = LoggerFactory.getLogger(ExhibitorStorageServiceImpl.class);
	private static final long MAX_FILE_SIZE_BYTES = 1024L * 1024L;
	private static final byte[] PDF_SIGNATURE = "%PDF-".getBytes(java.nio.charset.StandardCharsets.US_ASCII);
	private static final Pattern MANAGED_DOCUMENT = Pattern.compile(
			"^(?:[a-f0-9]{8}-(?:[a-f0-9]{4}-){3}[a-f0-9]{12}-.+\\.pdf|\\.upload-[a-f0-9-]{36}\\.part)$",
			Pattern.CASE_INSENSITIVE);
	private final Path storageDirectory;
	private final Path quotaLockFile;
	private final long maxStorageBytes;

	public ExhibitorStorageServiceImpl(
			@Value("${tecverse.storage.documents-dir:uploads/exhibitor-documents}") String storageDirectory,
			@Value("${tecverse.storage.documents-max-bytes:1073741824}") long maxStorageBytes,
			@Value("${tecverse.storage.documents-quota-lock-file:}") String quotaLockFile) {
		this.storageDirectory = Paths.get(storageDirectory).toAbsolutePath().normalize();
		if (maxStorageBytes < MAX_FILE_SIZE_BYTES) {
			throw new IllegalArgumentException("Exhibitor document storage quota must be at least 1 MB.");
		}
		this.maxStorageBytes = maxStorageBytes;
		this.quotaLockFile = quotaLockFile == null || quotaLockFile.isBlank()
				? Paths.get(System.getProperty("java.io.tmpdir"), "tecverse-exhibitor-documents-quota.lock").toAbsolutePath().normalize()
				: Paths.get(quotaLockFile).toAbsolutePath().normalize();
		if (this.quotaLockFile.startsWith(this.storageDirectory)) {
			throw new IllegalArgumentException("The document quota lock file must be outside the public upload directory.");
		}
	}

	@Override
	public synchronized String upload(MultipartFile file, String reference) {
		if (file == null || file.isEmpty()) {
			throw new IllegalArgumentException("Choose a PDF document to upload.");
		}
		if (file.getSize() > MAX_FILE_SIZE_BYTES) {
			throw new IllegalArgumentException("Each PDF must be 1 MB or smaller.");
		}
		String originalName = file.getOriginalFilename();
		if (originalName == null || !originalName.toLowerCase(java.util.Locale.ROOT).endsWith(".pdf")) {
			throw new IllegalArgumentException("Upload PDF files only.");
		}
		try {
			byte[] header = file.getBytes();
			if (header.length < PDF_SIGNATURE.length
					|| !java.util.Arrays.equals(java.util.Arrays.copyOf(header, PDF_SIGNATURE.length), PDF_SIGNATURE)) {
				throw new IllegalArgumentException("The uploaded file is not a valid PDF.");
			}
		} catch (IOException ex) {
			throw new IllegalStateException("Unable to read uploaded document.", ex);
		}

		String safeReference = reference == null
				? "pending"
				: reference.replaceAll("[^A-Za-z0-9_-]", "_");
		String safeName = originalName.replaceAll("[^A-Za-z0-9._-]", "_");
		Path registrationDirectory = storageDirectory.resolve(safeReference).normalize();

		if (!registrationDirectory.startsWith(storageDirectory)) {
			throw new IllegalArgumentException("Invalid document reference");
		}

		try {
			Files.createDirectories(registrationDirectory);
			String fileName = UUID.randomUUID() + "-" + safeName;
			Path destination = registrationDirectory.resolve(fileName);
			Path temporary = storageDirectory.resolve(".upload-" + UUID.randomUUID() + ".part");
			try {
				withQuotaLock(() -> {
					long usedBytes = currentStorageBytes();
					if (file.getSize() > maxStorageBytes - usedBytes) {
						log.warn("Exhibitor document upload rejected because the configured storage quota is full ({} of {} bytes used).",
								usedBytes, maxStorageBytes);
						throw new ResponseStatusException(HttpStatus.INSUFFICIENT_STORAGE,
								"Exhibitor document storage is full. Please try again later.");
					}
					try (InputStream input = file.getInputStream()) {
						Files.copy(input, temporary, StandardCopyOption.REPLACE_EXISTING);
					}
					try {
						Files.move(temporary, destination, StandardCopyOption.ATOMIC_MOVE);
					} catch (AtomicMoveNotSupportedException unsupported) {
						Files.move(temporary, destination);
					}
					return null;
				});
			} finally {
				Files.deleteIfExists(temporary);
			}
			return "/uploads/documents/" + safeReference + "/" + fileName;
		} catch (IOException | IllegalStateException ex) {
			throw new IllegalStateException("Unable to save document", ex);
		}
	}

	/** Deletes only old files that are not referenced by a saved registration. */
	public synchronized long cleanupOrphanedFiles(Set<Path> retainedFiles, Instant olderThan) throws IOException {
		if (!Files.isDirectory(storageDirectory)) return 0;
		return withQuotaLock(() -> {
			long deletedBytes = 0;
			try (var paths = Files.walk(storageDirectory)) {
				for (Path path : paths.filter(p -> Files.isRegularFile(p, LinkOption.NOFOLLOW_LINKS)
						&& isManagedDocument(p)).toList()) {
					Path normalized = path.toAbsolutePath().normalize();
					if (retainedFiles.contains(normalized)
							|| Files.getLastModifiedTime(normalized, LinkOption.NOFOLLOW_LINKS).toInstant().isAfter(olderThan)) {
						continue;
					}
					long size = Files.size(normalized);
					Files.deleteIfExists(normalized);
					deletedBytes += size;
				}
			}
			try (var paths = Files.walk(storageDirectory)) {
				for (Path directory : paths.filter(Files::isDirectory)
						.sorted(Comparator.reverseOrder()).toList()) {
					if (!directory.equals(storageDirectory)) {
						try (var children = Files.list(directory)) {
							if (children.findAny().isEmpty()) Files.deleteIfExists(directory);
						}
					}
				}
			}
			return deletedBytes;
		});
	}

	private long currentStorageBytes() throws IOException {
		try (var paths = Files.walk(storageDirectory)) {
			long total = 0;
			for (Path path : paths.filter(p -> Files.isRegularFile(p, LinkOption.NOFOLLOW_LINKS)
					&& isManagedDocument(p) && p.getFileName().toString().toLowerCase(java.util.Locale.ROOT).endsWith(".pdf")).toList()) {
				total = Math.addExact(total, Files.size(path));
			}
			return total;
		} catch (ArithmeticException overflow) {
			return Long.MAX_VALUE;
		}
	}

	private static boolean isManagedDocument(Path path) {
		return MANAGED_DOCUMENT.matcher(path.getFileName().toString()).matches();
	}

	private <T> T withQuotaLock(LockedOperation<T> operation) throws IOException {
		Path parent = quotaLockFile.getParent();
		if (parent != null) Files.createDirectories(parent);
		try (FileChannel channel = FileChannel.open(quotaLockFile,
				StandardOpenOption.CREATE, StandardOpenOption.WRITE);
			 FileLock ignored = channel.lock()) {
			return operation.run();
		}
	}

	@FunctionalInterface
	private interface LockedOperation<T> {
		T run() throws IOException;
	}
}

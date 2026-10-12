package com.tecverse.app.controller;

import java.net.URI;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.Locale;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import static org.springframework.http.HttpStatus.NOT_FOUND;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import com.tecverse.app.dto.GalleryImageForm;
import com.tecverse.app.dto.GalleryVideoForm;
import com.tecverse.app.dto.SpeakerForm;
import com.tecverse.app.entity.GalleryImage;
import com.tecverse.app.entity.GalleryVideo;
import com.tecverse.app.entity.Speaker;
import com.tecverse.app.repository.GalleryImageRepository;
import com.tecverse.app.repository.GalleryVideoRepository;
import com.tecverse.app.repository.SpeakerRepository;
import com.tecverse.app.service.GalleryStorageService;

import jakarta.validation.Valid;

@Controller
public class AdminGalleryController {

    private static final long MAX_VIDEO_THUMBNAIL_SIZE_BYTES = 1024L * 1024L;
    private static final Pattern SESSION_TIME_PATTERN = Pattern.compile("(?i)(\\d{1,2}:\\d{2}\\s*(?:AM|PM)?)");
    private static final DateTimeFormatter TWELVE_HOUR_TIME =
            DateTimeFormatter.ofPattern("h:mm a", Locale.ENGLISH);
    private static final DateTimeFormatter TWENTY_FOUR_HOUR_TIME =
            DateTimeFormatter.ofPattern("H:mm", Locale.ENGLISH);
    private static final DateTimeFormatter TIME_INPUT_FORMAT =
            DateTimeFormatter.ofPattern("h:mm a", Locale.ENGLISH);
    private static final DateTimeFormatter SPEAKER_DATE_FORMAT =
            DateTimeFormatter.ofPattern("d MMM yyyy", Locale.ENGLISH);

    private final GalleryImageRepository galleryImageRepository;
    private final GalleryVideoRepository galleryVideoRepository;
    private final SpeakerRepository speakerRepository;
    private final GalleryStorageService galleryStorageService;

    public AdminGalleryController(GalleryImageRepository galleryImageRepository,
                                  GalleryVideoRepository galleryVideoRepository,
                                  SpeakerRepository speakerRepository,
                                  GalleryStorageService galleryStorageService) {
        this.galleryImageRepository = galleryImageRepository;
        this.galleryVideoRepository = galleryVideoRepository;
        this.speakerRepository = speakerRepository;
        this.galleryStorageService = galleryStorageService;
    }

    @GetMapping("/admin/gallery")
    public String gallery(@RequestParam(value = "tab", defaultValue = "images") String tab, Model model) {
        model.addAttribute("activeTab", cleanTab(tab));
        model.addAttribute("images", galleryImageRepository.findAllByOrderByDisplayOrderAscIdAsc());
        model.addAttribute("videos", galleryVideoRepository.findAllByOrderByDisplayOrderAscIdAsc());
        model.addAttribute("speakers", speakerRepository.findAllByOrderByDisplayOrderAscIdAsc());
        return "admin/gallery";
    }

    @GetMapping("/admin/speaker-update")
    public String speakerUpdate(Model model) {
        return gallery("speakers", model);
    }

    @GetMapping("/admin/gallery/images/new")
    public String newImage(Model model) {
        model.addAttribute("galleryImageForm", new GalleryImageForm());
        model.addAttribute("mode", "new");
        return "admin/gallery-image-form";
    }

    @GetMapping("/admin/gallery/images/{id}/edit")
    public String editImage(@PathVariable Long id, Model model) {
        GalleryImage image = image(id);
        model.addAttribute("galleryImageForm", imageForm(image));
        model.addAttribute("imageId", id);
        model.addAttribute("mode", "edit");
        model.addAttribute("currentImageUrl", image.getImageUrl());
        return "admin/gallery-image-form";
    }

    @PostMapping("/admin/gallery/images")
    public String saveImage(@Valid @ModelAttribute("galleryImageForm") GalleryImageForm form,
                            BindingResult bindingResult,
                            @RequestParam(value = "imageFile", required = false) MultipartFile imageFile,
                            RedirectAttributes redirectAttributes) {
        if (bindingResult.hasErrors()) {
            return "admin/gallery-image-form";
        }

        String imageUrl;
        try {
            imageUrl = galleryStorageService.uploadImage(imageFile, "images");
        } catch (IllegalArgumentException | IllegalStateException ex) {
            bindingResult.reject("gallery.image.invalid", ex.getMessage());
            return "admin/gallery-image-form";
        }

        GalleryImage image = new GalleryImage();
        applyImage(form, image, imageUrl);
        galleryImageRepository.save(image);
        redirectAttributes.addFlashAttribute("successMessage", "Gallery image saved successfully.");
        return "redirect:/admin/gallery?tab=images";
    }

    @PostMapping("/admin/gallery/images/{id}")
    public String updateImage(@PathVariable Long id,
                              @Valid @ModelAttribute("galleryImageForm") GalleryImageForm form,
                              BindingResult bindingResult,
                              @RequestParam(value = "imageFile", required = false) MultipartFile imageFile,
                              RedirectAttributes redirectAttributes,
                              Model model) {
        if (bindingResult.hasErrors()) {
            model.addAttribute("imageId", id);
            model.addAttribute("mode", "edit");
            model.addAttribute("currentImageUrl", image(id).getImageUrl());
            return "admin/gallery-image-form";
        }

        GalleryImage image = image(id);
        String imageUrl;
        try {
            imageUrl = imageFile == null || imageFile.isEmpty()
                    ? image.getImageUrl()
                    : galleryStorageService.uploadImage(imageFile, "images");
            if (imageUrl == null || imageUrl.isBlank()) {
                throw new IllegalArgumentException("Please choose a gallery image.");
            }
        } catch (IllegalArgumentException | IllegalStateException ex) {
            bindingResult.reject("gallery.image.invalid", ex.getMessage());
            model.addAttribute("imageId", id);
            model.addAttribute("mode", "edit");
            model.addAttribute("currentImageUrl", image.getImageUrl());
            return "admin/gallery-image-form";
        }

        applyImage(form, image, imageUrl);
        galleryImageRepository.save(image);
        redirectAttributes.addFlashAttribute("successMessage", "Gallery image updated successfully.");
        return "redirect:/admin/gallery?tab=images";
    }

    @PostMapping("/admin/gallery/images/{id}/delete")
    public String deleteImage(@PathVariable Long id, RedirectAttributes redirectAttributes) {
        if (galleryImageRepository.existsById(id)) {
            galleryImageRepository.deleteById(id);
            redirectAttributes.addFlashAttribute("successMessage", "Gallery image deleted successfully.");
        } else {
            redirectAttributes.addFlashAttribute("successMessage", "Gallery image was already removed.");
        }
        return "redirect:/admin/gallery?tab=images";
    }

    @PostMapping("/admin/gallery/images/{id}/toggle")
    public String toggleImage(@PathVariable Long id, RedirectAttributes redirectAttributes) {
        GalleryImage image = image(id);
        image.setActive(!image.isActive());
        galleryImageRepository.save(image);
        redirectAttributes.addFlashAttribute("successMessage", "Gallery image status updated.");
        return "redirect:/admin/gallery?tab=images";
    }

    @GetMapping("/admin/gallery/videos/new")
    public String newVideo(Model model) {
        model.addAttribute("galleryVideoForm", new GalleryVideoForm());
        model.addAttribute("mode", "new");
        return "admin/gallery-video-form";
    }

    @GetMapping("/admin/gallery/videos/{id}/edit")
    public String editVideo(@PathVariable Long id, Model model) {
        GalleryVideo video = video(id);
        model.addAttribute("galleryVideoForm", videoForm(video));
        model.addAttribute("videoId", id);
        model.addAttribute("mode", "edit");
        return "admin/gallery-video-form";
    }

    @PostMapping("/admin/gallery/videos")
    public String saveVideo(@Valid @ModelAttribute("galleryVideoForm") GalleryVideoForm form,
                            BindingResult bindingResult,
                            @RequestParam(value = "videoFile", required = false) MultipartFile videoFile,
                            @RequestParam(value = "thumbnailFile", required = false) MultipartFile thumbnailFile,
                            RedirectAttributes redirectAttributes) {
        if (bindingResult.hasErrors()) {
            return "admin/gallery-video-form";
        }

        try {
            String thumbnailUrl = videoThumbnail(form.getVideoUrl(), optionalImagePath(thumbnailFile, "thumbnails"));
            String videoUrl = mediaPath(form.getVideoUrl(), videoFile, false, "videos");
            GalleryVideo video = new GalleryVideo();
            applyVideo(form, video, videoUrl, thumbnailUrl);
            galleryVideoRepository.save(video);
        } catch (IllegalArgumentException | IllegalStateException ex) {
            bindingResult.rejectValue("videoUrl", "gallery.video.invalid", ex.getMessage());
            return "admin/gallery-video-form";
        }

        redirectAttributes.addFlashAttribute("successMessage", "Gallery video saved successfully.");
        return "redirect:/admin/gallery?tab=videos";
    }

    @PostMapping("/admin/gallery/videos/{id}")
    public String updateVideo(@PathVariable Long id,
                              @Valid @ModelAttribute("galleryVideoForm") GalleryVideoForm form,
                              BindingResult bindingResult,
                              @RequestParam(value = "videoFile", required = false) MultipartFile videoFile,
                              @RequestParam(value = "thumbnailFile", required = false) MultipartFile thumbnailFile,
                              RedirectAttributes redirectAttributes,
                              Model model) {
        if (bindingResult.hasErrors()) {
            model.addAttribute("videoId", id);
            model.addAttribute("mode", "edit");
            return "admin/gallery-video-form";
        }

        GalleryVideo video = video(id);
        try {
            String thumbnailInput = optionalImagePath(thumbnailFile, "thumbnails");
            String thumbnailUrl = videoThumbnail(form.getVideoUrl(), thumbnailInput);
            String videoUrl = mediaPath(form.getVideoUrl(), videoFile, false, "videos");
            if (thumbnailInput == null && youtubeVideoId(form.getVideoUrl()) == null) {
                thumbnailUrl = video.getThumbnailUrl();
            }
            applyVideo(form, video, videoUrl, thumbnailUrl);
            galleryVideoRepository.save(video);
        } catch (IllegalArgumentException | IllegalStateException ex) {
            bindingResult.rejectValue("videoUrl", "gallery.video.invalid", ex.getMessage());
            model.addAttribute("videoId", id);
            model.addAttribute("mode", "edit");
            return "admin/gallery-video-form";
        }

        redirectAttributes.addFlashAttribute("successMessage", "Gallery video updated successfully.");
        return "redirect:/admin/gallery?tab=videos";
    }

    @PostMapping("/admin/gallery/videos/{id}/delete")
    public String deleteVideo(@PathVariable Long id, RedirectAttributes redirectAttributes) {
        if (galleryVideoRepository.existsById(id)) {
            galleryVideoRepository.deleteById(id);
            redirectAttributes.addFlashAttribute("successMessage", "Gallery video deleted successfully.");
        } else {
            redirectAttributes.addFlashAttribute("successMessage", "Gallery video was already removed.");
        }
        return "redirect:/admin/gallery?tab=videos";
    }

    @PostMapping("/admin/gallery/videos/{id}/toggle")
    public String toggleVideo(@PathVariable Long id, RedirectAttributes redirectAttributes) {
        GalleryVideo video = video(id);
        video.setActive(!video.isActive());
        galleryVideoRepository.save(video);
        redirectAttributes.addFlashAttribute("successMessage", "Gallery video status updated.");
        return "redirect:/admin/gallery?tab=videos";
    }

    @GetMapping("/admin/gallery/speakers/new")
    public String newSpeaker(Model model) {
        model.addAttribute("speakerForm", new SpeakerForm());
        model.addAttribute("mode", "new");
        return "admin/speaker-form";
    }

    @GetMapping("/admin/gallery/speakers/{id}/edit")
    public String editSpeaker(@PathVariable Long id, Model model) {
        Speaker speaker = speaker(id);
        model.addAttribute("speakerForm", speakerForm(speaker));
        model.addAttribute("speakerId", id);
        model.addAttribute("mode", "edit");
        model.addAttribute("currentProfileImageUrl", speaker.getProfileImageUrl());
        return "admin/speaker-form";
    }

    @PostMapping("/admin/gallery/speakers")
    public String saveSpeaker(@Valid @ModelAttribute("speakerForm") SpeakerForm form,
                              BindingResult bindingResult,
                              @RequestParam(value = "profileImageFile", required = false) MultipartFile profileImageFile,
                              RedirectAttributes redirectAttributes) {
        if (bindingResult.hasErrors()) {
            return "admin/speaker-form";
        }
        if (!validateSpeakerTimes(form, bindingResult)) {
            return "admin/speaker-form";
        }

        try {
            validateSpeakerImageFormat(profileImageFile);
            String profileImageUrl = galleryStorageService.uploadImage(profileImageFile, "speakers");
            Speaker speaker = new Speaker();
            applySpeaker(form, speaker, profileImageUrl);
            speakerRepository.save(speaker);
        } catch (IllegalArgumentException | IllegalStateException ex) {
            bindingResult.reject("speaker.image.invalid", ex.getMessage());
            return "admin/speaker-form";
        }

        redirectAttributes.addFlashAttribute("successMessage", "Speaker saved successfully.");
        return "redirect:/admin/speaker-update";
    }

    @PostMapping("/admin/gallery/speakers/{id}")
    public String updateSpeaker(@PathVariable Long id,
                                @Valid @ModelAttribute("speakerForm") SpeakerForm form,
                                BindingResult bindingResult,
                                @RequestParam(value = "profileImageFile", required = false) MultipartFile profileImageFile,
                                RedirectAttributes redirectAttributes,
                                Model model) {
        if (bindingResult.hasErrors()) {
            model.addAttribute("speakerId", id);
            model.addAttribute("mode", "edit");
            model.addAttribute("currentProfileImageUrl", speaker(id).getProfileImageUrl());
            return "admin/speaker-form";
        }
        if (!validateSpeakerTimes(form, bindingResult)) {
            model.addAttribute("speakerId", id);
            model.addAttribute("mode", "edit");
            model.addAttribute("currentProfileImageUrl", speaker(id).getProfileImageUrl());
            return "admin/speaker-form";
        }

        Speaker speaker = speaker(id);
        try {
            validateSpeakerImageFormat(profileImageFile);
            String profileImageUrl = profileImageFile == null || profileImageFile.isEmpty()
                    ? speaker.getProfileImageUrl()
                    : galleryStorageService.uploadImage(profileImageFile, "speakers");
            if (profileImageUrl == null || profileImageUrl.isBlank()) {
                throw new IllegalArgumentException("Please choose a speaker profile image.");
            }
            applySpeaker(form, speaker, profileImageUrl);
            speakerRepository.save(speaker);
        } catch (IllegalArgumentException | IllegalStateException ex) {
            bindingResult.reject("speaker.image.invalid", ex.getMessage());
            model.addAttribute("speakerId", id);
            model.addAttribute("mode", "edit");
            model.addAttribute("currentProfileImageUrl", speaker.getProfileImageUrl());
            return "admin/speaker-form";
        }

        redirectAttributes.addFlashAttribute("successMessage", "Speaker updated successfully.");
        return "redirect:/admin/speaker-update";
    }

    @PostMapping("/admin/gallery/speakers/{id}/delete")
    public String deleteSpeaker(@PathVariable Long id, RedirectAttributes redirectAttributes) {
        if (speakerRepository.existsById(id)) {
            speakerRepository.deleteById(id);
            redirectAttributes.addFlashAttribute("successMessage", "Speaker deleted successfully.");
        } else {
            redirectAttributes.addFlashAttribute("successMessage", "Speaker was already removed.");
        }
        return "redirect:/admin/speaker-update";
    }

    @PostMapping("/admin/gallery/speakers/{id}/toggle")
    public String toggleSpeaker(@PathVariable Long id, RedirectAttributes redirectAttributes) {
        Speaker speaker = speaker(id);
        speaker.setActive(!speaker.isActive());
        speakerRepository.save(speaker);
        redirectAttributes.addFlashAttribute("successMessage", "Speaker status updated.");
        return "redirect:/admin/speaker-update";
    }

    private GalleryImage image(Long id) {
        return galleryImageRepository.findById(id).orElseThrow(() -> new ResponseStatusException(NOT_FOUND));
    }

    private GalleryVideo video(Long id) {
        return galleryVideoRepository.findById(id).orElseThrow(() -> new ResponseStatusException(NOT_FOUND));
    }

    private Speaker speaker(Long id) {
        return speakerRepository.findById(id).orElseThrow(() -> new ResponseStatusException(NOT_FOUND));
    }

    private String mediaPath(String existingPath, MultipartFile file, boolean image, String folder) {
        if (file != null && !file.isEmpty()) {
            return image ? galleryStorageService.uploadImage(file, folder) : galleryStorageService.uploadVideo(file, folder);
        }
        String value = existingPath == null ? "" : existingPath.trim();
        if (value.isBlank()) {
            throw new IllegalArgumentException(image ? "Please upload an image or enter an image URL." : "Please upload a video or enter a video URL.");
        }
        return value;
    }

    private String optionalImagePath(MultipartFile file, String folder) {
        if (file != null && !file.isEmpty()) {
            if (file.getSize() > MAX_VIDEO_THUMBNAIL_SIZE_BYTES) {
                throw new IllegalArgumentException("Thumbnail image must be 1 MB or smaller.");
            }
            return galleryStorageService.uploadImage(file, folder);
        }
        return null;
    }

    private static String videoThumbnail(String videoUrl, String providedThumbnail) {
        if (providedThumbnail != null && !providedThumbnail.isBlank()) {
            return providedThumbnail;
        }
        String videoId = youtubeVideoId(videoUrl);
        return videoId == null ? null : "https://img.youtube.com/vi/" + videoId + "/hqdefault.jpg";
    }

    private static String youtubeVideoId(String videoUrl) {
        if (videoUrl == null || videoUrl.isBlank()) {
            return null;
        }
        try {
            URI uri = URI.create(videoUrl.trim());
            String host = uri.getHost();
            if (host == null) {
                return null;
            }
            host = host.toLowerCase(Locale.ROOT);
            String id = null;
            if (host.equals("youtu.be") || host.equals("www.youtu.be")) {
                String path = uri.getPath();
                id = path == null ? null : path.replaceFirst("^/", "").split("/", 2)[0];
            } else if (host.equals("youtube.com") || host.endsWith(".youtube.com")
                    || host.equals("youtube-nocookie.com") || host.endsWith(".youtube-nocookie.com")) {
                String path = uri.getPath();
                if (path == null || path.equals("/watch")) {
                    String query = uri.getRawQuery();
                    if (query != null) {
                        for (String part : query.split("&")) {
                            if (part.startsWith("v=")) {
                                id = part.substring(2);
                                break;
                            }
                        }
                    }
                } else if (path.startsWith("/embed/") || path.startsWith("/shorts/") || path.startsWith("/live/")) {
                    id = path.substring(path.lastIndexOf('/') + 1);
                }
            }
            return id != null && id.matches("[A-Za-z0-9_-]{11}") ? id : null;
        } catch (IllegalArgumentException ex) {
            return null;
        }
    }

    private static String cleanTab(String tab) {
        return switch (tab) {
            case "videos", "speakers" -> tab;
            default -> "images";
        };
    }

    private static void applyImage(GalleryImageForm form, GalleryImage image, String imageUrl) {
        image.setTitle(form.getTitle().trim());
        image.setCategory(form.getCategory().trim());
        image.setImageUrl(imageUrl);
        image.setDisplayOrder(form.getDisplayOrder());
        image.setActive(form.isActive());
    }

    private static void applyVideo(GalleryVideoForm form, GalleryVideo video, String videoUrl, String thumbnailUrl) {
        video.setTitle(form.getTitle().trim());
        video.setDescription(form.getDescription().trim());
        video.setVideoUrl(videoUrl);
        video.setThumbnailUrl(thumbnailUrl);
        video.setDisplayOrder(form.getDisplayOrder());
        video.setActive(form.isActive());
    }

    private static void applySpeaker(SpeakerForm form, Speaker speaker, String profileImageUrl) {
        speaker.setName(form.getName().trim());
        speaker.setDesignation(form.getDesignation().trim());
        speaker.setSessionTiming(LocalDate.parse(form.getSessionDate()).format(SPEAKER_DATE_FORMAT)
                + ", " + toDisplayTime(form.getStartTime()) + " - " + toDisplayTime(form.getEndTime()));
        speaker.setOrganization(form.getOrganization().trim());
        speaker.setProfileImageUrl(profileImageUrl);
        speaker.setDisplayOrder(form.getDisplayOrder());
        speaker.setActive(form.isActive());
    }

    private static void validateSpeakerImageFormat(MultipartFile file) {
        if (file == null || file.isEmpty()) return;

        String filename = file.getOriginalFilename();
        String contentType = file.getContentType();
        String extension = filename == null || filename.lastIndexOf('.') < 0
                ? ""
                : filename.substring(filename.lastIndexOf('.')).toLowerCase(Locale.ENGLISH);
        boolean jpeg = (".jpg".equals(extension) || ".jpeg".equals(extension))
                && contentType != null && ("image/jpeg".equalsIgnoreCase(contentType)
                || "image/jpg".equalsIgnoreCase(contentType));
        boolean png = ".png".equals(extension) && contentType != null
                && "image/png".equalsIgnoreCase(contentType);
        if (!jpeg && !png) {
            throw new IllegalArgumentException("Choose a JPG or PNG image file.");
        }
    }

    private static GalleryImageForm imageForm(GalleryImage image) {
        GalleryImageForm form = new GalleryImageForm();
        form.setTitle(image.getTitle());
        form.setCategory(image.getCategory());
        form.setDisplayOrder(image.getDisplayOrder());
        form.setActive(image.isActive());
        return form;
    }

    private static GalleryVideoForm videoForm(GalleryVideo video) {
        GalleryVideoForm form = new GalleryVideoForm();
        form.setTitle(video.getTitle());
        form.setDescription(video.getDescription());
        form.setVideoUrl(video.getVideoUrl());
        form.setDisplayOrder(video.getDisplayOrder());
        form.setActive(video.isActive());
        return form;
    }

    private static SpeakerForm speakerForm(Speaker speaker) {
        SpeakerForm form = new SpeakerForm();
        form.setName(speaker.getName());
        form.setDesignation(speaker.getDesignation());
        populateSpeakerTimes(form, speaker.getSessionTiming());
        form.setOrganization(speaker.getOrganization());
        form.setDisplayOrder(speaker.getDisplayOrder());
        form.setActive(speaker.isActive());
        return form;
    }

    private static boolean validateSpeakerTimes(SpeakerForm form, BindingResult bindingResult) {
        try {
            LocalDate.parse(form.getSessionDate());
        } catch (RuntimeException ex) {
            bindingResult.rejectValue("sessionDate", "speaker.sessionDate.invalid", "Choose a valid session date.");
            return false;
        }
        if (!LocalTime.parse(form.getEndTime()).isAfter(LocalTime.parse(form.getStartTime()))) {
            bindingResult.rejectValue("endTime", "speaker.endTime.order", "End time must be later than start time.");
            return false;
        }
        return true;
    }

    private static void populateSpeakerTimes(SpeakerForm form, String sessionTiming) {
        if (sessionTiming == null || sessionTiming.isBlank()) return;
        Matcher matcher = SESSION_TIME_PATTERN.matcher(sessionTiming);
        if (!matcher.find()) return;
        String start = matcher.group(1);
        if (!matcher.find()) return;
        String end = matcher.group(1);
        try {
            form.setStartTime(toTimeInput(start));
            form.setEndTime(toTimeInput(end));
            Matcher dateMatcher = Pattern.compile("(?i)(\\d{1,2}\\s+[A-Z]{3,9}\\s+\\d{4})").matcher(sessionTiming);
            if (dateMatcher.find()) {
                form.setSessionDate(LocalDate.parse(dateMatcher.group(1), SPEAKER_DATE_FORMAT).toString());
            }
        } catch (DateTimeParseException ignored) {
            // The admin can reselect times for legacy values that don't use a recognized time format.
        }
    }

    private static String toDisplayTime(String value) {
        return parseTime(value).format(TIME_INPUT_FORMAT);
    }

    private static String toTimeInput(String value) {
        return parseTime(value).format(DateTimeFormatter.ofPattern("HH:mm"));
    }

    private static LocalTime parseTime(String value) {
        String normalized = value.trim().replaceAll("\\s+", " ").toUpperCase(Locale.ENGLISH);
        DateTimeFormatter formatter = normalized.endsWith("AM") || normalized.endsWith("PM")
                ? TWELVE_HOUR_TIME
                : TWENTY_FOUR_HOUR_TIME;
        return LocalTime.parse(normalized, formatter);
    }
}

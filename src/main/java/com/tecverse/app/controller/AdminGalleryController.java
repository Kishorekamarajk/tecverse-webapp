package com.tecverse.app.controller;

import java.net.URI;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.Locale;
import java.util.List;
import java.util.ArrayList;
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
import org.springframework.web.multipart.MultipartHttpServletRequest;
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

    @PostMapping("/admin/gallery/images/bulk")
    public String uploadImages(@RequestParam("imageFiles") List<MultipartFile> imageFiles,
                               @RequestParam("category") String category,
                               @RequestParam(value = "displayOrder", defaultValue = "0") int displayOrder,
                               RedirectAttributes redirectAttributes) {
        String cleanCategory = category == null ? "" : category.trim();
        if (cleanCategory.isEmpty() || cleanCategory.length() > 120) {
            redirectAttributes.addFlashAttribute("errorMessage", "Enter a category up to 120 characters.");
            return "redirect:/admin/gallery?tab=images";
        }
        if (displayOrder < 0) {
            redirectAttributes.addFlashAttribute("errorMessage", "Display order cannot be negative.");
            return "redirect:/admin/gallery?tab=images";
        }

        try {
            List<MultipartFile> selected = imageFiles == null ? List.of()
                    : imageFiles.stream().filter(file -> file != null && !file.isEmpty()).toList();
            List<String> imageUrls = galleryStorageService.uploadImages(selected, "images");
            List<GalleryImage> images = new ArrayList<>(imageUrls.size());
            int order = displayOrder;
            for (int i = 0; i < imageUrls.size(); i++) {
                MultipartFile file = selected.get(i);
                GalleryImage image = new GalleryImage();
                image.setTitle(imageTitle(file.getOriginalFilename()));
                image.setCategory(cleanCategory);
                image.setImageUrl(imageUrls.get(i));
                image.setDisplayOrder(order++);
                image.setActive(true);
                images.add(image);
            }
            galleryImageRepository.saveAll(images);
            redirectAttributes.addFlashAttribute("successMessage", images.size() + " gallery images uploaded successfully.");
        } catch (IllegalArgumentException | IllegalStateException ex) {
            redirectAttributes.addFlashAttribute("errorMessage", ex.getMessage());
        }
        return "redirect:/admin/gallery?tab=images";
    }

    private static String imageTitle(String fileName) {
        if (fileName == null || fileName.isBlank()) return "Gallery image";
        String name = fileName.replace('\\', '/');
        name = name.substring(name.lastIndexOf('/') + 1);
        int dot = name.lastIndexOf('.');
        if (dot > 0) name = name.substring(0, dot);
        name = name.replaceAll("[_-]+", " ").trim();
        if (name.length() > 180) name = name.substring(0, 180).trim();
        return name.isBlank() ? "Gallery image" : name;
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
        GalleryImage image = galleryImageRepository.findById(id).orElse(null);
        if (image != null) {
            galleryImageRepository.delete(image);
            try {
                galleryStorageService.deleteStoredMedia(image.getImageUrl());
            } catch (IllegalStateException ex) {
                redirectAttributes.addFlashAttribute("errorMessage", "Image record deleted, but its uploaded file could not be removed.");
                return "redirect:/admin/gallery?tab=images";
            }
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

    @PostMapping("/admin/gallery/videos/bulk")
    public String uploadVideos(@RequestParam("videoFiles") List<MultipartFile> videoFiles,
                               @RequestParam("titles") List<String> titles,
                               @RequestParam(value = "descriptions", required = false) List<String> descriptions,
                               @RequestParam(value = "displayOrder", defaultValue = "0") int displayOrder,
                               MultipartHttpServletRequest multipartRequest,
                               RedirectAttributes redirectAttributes) {
        List<MultipartFile> selected = videoFiles == null ? List.of()
                : videoFiles.stream().filter(file -> file != null && !file.isEmpty()).toList();
        if (selected.isEmpty() || titles == null || titles.size() != selected.size()
                || (descriptions != null && descriptions.size() != selected.size())) {
            redirectAttributes.addFlashAttribute("errorMessage", "Select videos and complete their title details.");
            return "redirect:/admin/gallery?tab=videos";
        }
        if (displayOrder < 0) {
            redirectAttributes.addFlashAttribute("errorMessage", "Display order cannot be negative.");
            return "redirect:/admin/gallery?tab=videos";
        }
        for (String title : titles) {
            if (title == null || title.isBlank() || title.trim().length() > 180) {
                redirectAttributes.addFlashAttribute("errorMessage", "Each video needs a title of 1 to 180 characters.");
                return "redirect:/admin/gallery?tab=videos";
            }
        }
        List<String> urls = new ArrayList<>();
        List<String> thumbnailUrls = new ArrayList<>();
        try {
            urls.addAll(galleryStorageService.uploadVideos(selected, "videos"));
            List<GalleryVideo> videos = new ArrayList<>(urls.size());
            for (int i = 0; i < urls.size(); i++) {
                GalleryVideo video = new GalleryVideo();
                String title = titles.get(i).trim();
                String description = descriptions == null ? "" : descriptions.get(i).trim();
                MultipartFile thumbnailFile = multipartRequest.getFile("thumbnailFiles[" + i + "]");
                String thumbnailUrl = optionalImagePath(thumbnailFile, "thumbnails");
                if (thumbnailUrl != null) thumbnailUrls.add(thumbnailUrl);
                video.setTitle(title);
                video.setDescription(description.isBlank() ? title : description);
                video.setVideoUrl(urls.get(i));
                video.setThumbnailUrl(thumbnailUrl);
                video.setDisplayOrder(displayOrder + i);
                video.setActive(true);
                videos.add(video);
            }
            galleryVideoRepository.saveAll(videos);
            redirectAttributes.addFlashAttribute("successMessage", videos.size() + " gallery videos uploaded successfully.");
        } catch (IllegalArgumentException | IllegalStateException ex) {
            urls.forEach(galleryStorageService::deleteStoredMedia);
            thumbnailUrls.forEach(galleryStorageService::deleteStoredMedia);
            redirectAttributes.addFlashAttribute("errorMessage", ex.getMessage());
        }
        return "redirect:/admin/gallery?tab=videos";
    }

    @PostMapping("/admin/gallery/videos/bulk-youtube")
    public String uploadYoutubeVideos(@RequestParam("youtubeUrls") List<String> urls,
                                      @RequestParam("youtubeTitles") List<String> titles,
                                      @RequestParam(value = "youtubeDescriptions", required = false) List<String> descriptions,
                                      MultipartHttpServletRequest multipartRequest,
                                      @RequestParam(value = "displayOrder", defaultValue = "0") int displayOrder,
                                      RedirectAttributes redirectAttributes) {
        int count = urls == null ? 0 : urls.size();
        if (count == 0 || count > 20 || titles == null || titles.size() != count
                || (descriptions != null && descriptions.size() != count)) {
            redirectAttributes.addFlashAttribute("errorMessage", "Add between 1 and 20 YouTube videos and complete each row.");
            return "redirect:/admin/gallery?tab=videos";
        }
        if (displayOrder < 0) {
            redirectAttributes.addFlashAttribute("errorMessage", "Display order cannot be negative.");
            return "redirect:/admin/gallery?tab=videos";
        }
        for (int i = 0; i < count; i++) {
            String title = titles.get(i);
            String description = descriptions == null ? "" : descriptions.get(i);
            if (title == null || title.isBlank() || title.trim().length() > 180
                    || (description != null && description.length() > 500)
                    || youtubeVideoId(urls.get(i)) == null) {
                redirectAttributes.addFlashAttribute("errorMessage", "Check each YouTube link, title, and description.");
                return "redirect:/admin/gallery?tab=videos";
            }
            MultipartFile thumbnail = multipartRequest.getFile("youtubeThumbnail" + i);
            try {
                validateYoutubeThumbnail(thumbnail);
            } catch (IllegalArgumentException ex) {
                redirectAttributes.addFlashAttribute("errorMessage", ex.getMessage());
                return "redirect:/admin/gallery?tab=videos";
            }
        }

        try {
            List<GalleryVideo> videos = new ArrayList<>(count);
            for (int i = 0; i < count; i++) {
                String title = titles.get(i).trim();
                String description = descriptions == null || descriptions.get(i) == null
                        ? "" : descriptions.get(i).trim();
                MultipartFile thumbnail = multipartRequest.getFile("youtubeThumbnail" + i);
                String customThumbnail = optionalImagePath(thumbnail, "thumbnails");
                GalleryVideo video = new GalleryVideo();
                video.setTitle(title);
                video.setDescription(description.isBlank() ? title : description);
                video.setVideoUrl(urls.get(i).trim());
                video.setThumbnailUrl(videoThumbnail(video.getVideoUrl(), customThumbnail));
                video.setDisplayOrder(displayOrder + i);
                video.setActive(true);
                videos.add(video);
            }
            galleryVideoRepository.saveAll(videos);
            redirectAttributes.addFlashAttribute("successMessage", videos.size() + " YouTube videos added successfully.");
        } catch (IllegalArgumentException | IllegalStateException ex) {
            redirectAttributes.addFlashAttribute("errorMessage", ex.getMessage());
        }
        return "redirect:/admin/gallery?tab=videos";
    }

    private static void validateYoutubeThumbnail(MultipartFile file) {
        if (file == null || file.isEmpty()) return;
        if (file.getSize() > MAX_VIDEO_THUMBNAIL_SIZE_BYTES) {
            throw new IllegalArgumentException("Each thumbnail must be 1 MB or smaller.");
        }
        String filename = file.getOriginalFilename();
        String contentType = file.getContentType();
        if (filename == null || contentType == null) throw new IllegalArgumentException("Choose JPG, PNG, WEBP, or GIF thumbnails.");
        String extension = filename.substring(filename.lastIndexOf('.') + 1).toLowerCase(Locale.ENGLISH);
        String mime = contentType.toLowerCase(Locale.ENGLISH);
        boolean supported = switch (extension) {
            case "jpg", "jpeg" -> mime.equals("image/jpeg") || mime.equals("image/jpg");
            case "png" -> mime.equals("image/png");
            case "webp" -> mime.equals("image/webp");
            case "gif" -> mime.equals("image/gif");
            default -> false;
        };
        if (!supported) throw new IllegalArgumentException("Choose JPG, PNG, WEBP, or GIF thumbnails.");
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
        GalleryVideo video = galleryVideoRepository.findById(id).orElse(null);
        if (video != null) {
            galleryVideoRepository.delete(video);
            try {
                galleryStorageService.deleteStoredMedia(video.getVideoUrl());
                galleryStorageService.deleteStoredMedia(video.getThumbnailUrl());
            } catch (IllegalStateException ex) {
                redirectAttributes.addFlashAttribute("errorMessage", "Video record deleted, but one of its uploaded files could not be removed.");
                return "redirect:/admin/gallery?tab=videos";
            }
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

    @PostMapping("/admin/gallery/speakers/bulk")
    public String uploadSpeakers(@RequestParam("profileImageFiles") List<MultipartFile> profileImageFiles,
                                 @RequestParam("speakerNames") List<String> names,
                                 @RequestParam("speakerDesignations") List<String> designations,
                                 @RequestParam("speakerOrganizations") List<String> organizations,
                                 @RequestParam(value = "speakerSessionTimings", required = false) List<String> timings,
                                 @RequestParam(value = "displayOrder", defaultValue = "0") int displayOrder,
                                 RedirectAttributes redirectAttributes) {
        List<MultipartFile> selected = profileImageFiles == null ? List.of()
                : profileImageFiles.stream().filter(file -> file != null && !file.isEmpty()).toList();
        int size = selected.size();
        if (size == 0 || names == null || designations == null || organizations == null
                || names.size() != size || designations.size() != size || organizations.size() != size
                || (timings != null && timings.size() != size)) {
            redirectAttributes.addFlashAttribute("errorMessage", "Select speaker photos and complete each speaker's details.");
            return "redirect:/admin/gallery?tab=speakers";
        }
        if (displayOrder < 0) {
            redirectAttributes.addFlashAttribute("errorMessage", "Display order cannot be negative.");
            return "redirect:/admin/gallery?tab=speakers";
        }
        for (int i = 0; i < size; i++) {
            if (blankOrTooLong(names.get(i), 160) || blankOrTooLong(designations.get(i), 180)
                    || blankOrTooLong(organizations.get(i), 180)
                    || (timings != null && timings.get(i) != null && timings.get(i).length() > 120)) {
                redirectAttributes.addFlashAttribute("errorMessage", "Check each speaker's name, designation, organization, and session timing lengths.");
                return "redirect:/admin/gallery?tab=speakers";
            }
            try {
                validateSpeakerImageFormat(selected.get(i));
            } catch (IllegalArgumentException ex) {
                redirectAttributes.addFlashAttribute("errorMessage", ex.getMessage());
                return "redirect:/admin/gallery?tab=speakers";
            }
        }
        try {
            List<String> imageUrls = galleryStorageService.uploadImages(selected, "speakers");
            List<Speaker> speakers = new ArrayList<>(size);
            for (int i = 0; i < size; i++) {
                Speaker speaker = new Speaker();
                speaker.setName(names.get(i).trim());
                speaker.setDesignation(designations.get(i).trim());
                speaker.setOrganization(organizations.get(i).trim());
                String timing = timings == null ? null : timings.get(i);
                speaker.setSessionTiming(timing == null || timing.isBlank() ? null : timing.trim());
                speaker.setProfileImageUrl(imageUrls.get(i));
                speaker.setDisplayOrder(displayOrder + i);
                speaker.setActive(true);
                speakers.add(speaker);
            }
            speakerRepository.saveAll(speakers);
            redirectAttributes.addFlashAttribute("successMessage", speakers.size() + " speakers uploaded successfully.");
        } catch (IllegalArgumentException | IllegalStateException ex) {
            redirectAttributes.addFlashAttribute("errorMessage", ex.getMessage());
        }
        return "redirect:/admin/gallery?tab=speakers";
    }

    private static boolean blankOrTooLong(String value, int maxLength) {
        return value == null || value.isBlank() || value.trim().length() > maxLength;
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
        Speaker speaker = speakerRepository.findById(id).orElse(null);
        if (speaker != null) {
            speakerRepository.delete(speaker);
            try {
                galleryStorageService.deleteStoredMedia(speaker.getProfileImageUrl());
            } catch (IllegalStateException ex) {
                redirectAttributes.addFlashAttribute("errorMessage", "Speaker record deleted, but its uploaded profile image could not be removed.");
                return "redirect:/admin/speaker-update";
            }
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

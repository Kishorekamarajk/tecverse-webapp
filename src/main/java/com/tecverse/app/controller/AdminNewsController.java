package com.tecverse.app.controller;

import java.time.LocalTime;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import com.tecverse.app.config.ThematicDomainCardSeeder;
import com.tecverse.app.dto.ConferenceScheduleItemForm;
import com.tecverse.app.dto.NewsUpdateForm;
import com.tecverse.app.dto.ThematicDomainCardForm;
import com.tecverse.app.entity.ConferenceScheduleItem;
import com.tecverse.app.entity.NewsUpdate;
import com.tecverse.app.entity.ThematicDomainCard;
import com.tecverse.app.repository.ConferenceScheduleItemRepository;
import com.tecverse.app.repository.NewsUpdateRepository;
import com.tecverse.app.repository.ThematicDomainCardRepository;
import com.tecverse.app.service.GalleryStorageService;
import com.tecverse.app.service.AdminDashboardService;
import com.tecverse.app.security.AdminCaptchaService;

import jakarta.validation.Valid;

@Controller
public class AdminNewsController {

    private final ConferenceScheduleItemRepository conferenceScheduleItemRepository;
    private final NewsUpdateRepository newsUpdateRepository;
    private final ThematicDomainCardRepository thematicDomainCardRepository;
    private final GalleryStorageService galleryStorageService;
    private final AdminDashboardService adminDashboardService;
    private final AdminCaptchaService adminCaptchaService;

    public AdminNewsController(ConferenceScheduleItemRepository conferenceScheduleItemRepository,
                               NewsUpdateRepository newsUpdateRepository,
                               ThematicDomainCardRepository thematicDomainCardRepository,
                               GalleryStorageService galleryStorageService,
                               AdminDashboardService adminDashboardService,
                               AdminCaptchaService adminCaptchaService) {
        this.conferenceScheduleItemRepository = conferenceScheduleItemRepository;
        this.newsUpdateRepository = newsUpdateRepository;
        this.thematicDomainCardRepository = thematicDomainCardRepository;
        this.galleryStorageService = galleryStorageService;
        this.adminDashboardService = adminDashboardService;
        this.adminCaptchaService = adminCaptchaService;
    }

    @GetMapping("/adminportal")
    public String login(Model model, jakarta.servlet.http.HttpSession session) {
        model.addAttribute("adminCaptcha", adminCaptchaService.newChallenge(session));
        return "admin/login";
    }

    @GetMapping("/admin")
    public String dashboard(Model model) {
        model.addAttribute("submissionCounts", adminDashboardService.getSubmissionCounts());
        model.addAttribute("dashboardAnalytics", adminDashboardService.getAnalytics());
        return "admin/dashboard";
    }

    @GetMapping("/admin/news-updates")
    public String newsUpdates(Model model) {
        model.addAttribute("newsUpdates", newsUpdateRepository.findAllByOrderByPublishedDateDescIdDesc());
        return "admin/news-updates";
    }

    @GetMapping("/admin/news-updates/new")
    public String createForm(Model model) {
        model.addAttribute("newsUpdateForm", new NewsUpdateForm());
        return "admin/news-update-form";
    }

    @GetMapping("/admin/conference-schedule")
    public String conferenceSchedule(Model model) {
        model.addAttribute("scheduleItems", conferenceScheduleItemRepository.findAllByOrderByDayNumberAscDisplayOrderAscIdAsc());
        return "admin/conference-schedule";
    }

    @GetMapping("/admin/conference-schedule/new")
    public String conferenceScheduleForm(Model model) {
        model.addAttribute("conferenceScheduleItemForm", new ConferenceScheduleItemForm());
        model.addAttribute("mode", "create");
        return "admin/conference-schedule-form";
    }

    @GetMapping("/admin/conference-schedule/{id}/edit")
    public String editConferenceSchedule(@PathVariable Long id, Model model) {
        ConferenceScheduleItem item = conferenceScheduleItemRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Schedule item not found."));
        model.addAttribute("conferenceScheduleItemForm", toConferenceScheduleForm(item));
        model.addAttribute("scheduleItemId", id);
        model.addAttribute("currentImageUrl", item.getImageUrl());
        model.addAttribute("mode", "edit");
        return "admin/conference-schedule-form";
    }

    @PostMapping("/admin/conference-schedule")
    public String saveConferenceSchedule(@Valid @ModelAttribute("conferenceScheduleItemForm") ConferenceScheduleItemForm form,
                                         BindingResult bindingResult,
                                         @RequestParam(value = "imageFile", required = false) MultipartFile imageFile,
                                         Model model,
                                         RedirectAttributes redirectAttributes) {
        if (bindingResult.hasErrors()) {
            model.addAttribute("mode", "create");
            return "admin/conference-schedule-form";
        }

        if (!LocalTime.parse(form.getEndTime()).isAfter(LocalTime.parse(form.getStartTime()))) {
            bindingResult.rejectValue("endTime", "schedule.endTime.order", "End time must be later than start time.");
            model.addAttribute("mode", "create");
            return "admin/conference-schedule-form";
        }

        String imageUrl;
        try {
            imageUrl = galleryStorageService.uploadImage(imageFile, "schedule");
        } catch (IllegalArgumentException | IllegalStateException ex) {
            bindingResult.reject("schedule.image.invalid", ex.getMessage());
            model.addAttribute("mode", "create");
            return "admin/conference-schedule-form";
        }

        ConferenceScheduleItem item = new ConferenceScheduleItem();
        applyScheduleForm(form, item, imageUrl);
        conferenceScheduleItemRepository.save(item);

        redirectAttributes.addFlashAttribute("successMessage", "Conference schedule item saved successfully.");
        return "redirect:/admin/conference-schedule";
    }

    @PostMapping("/admin/conference-schedule/bulk")
    public String saveConferenceScheduleBulk(
            @RequestParam("imageFiles") List<MultipartFile> imageFiles,
            @RequestParam("dayNumbers") List<Integer> dayNumbers,
            @RequestParam("scheduleDates") List<String> scheduleDates,
            @RequestParam("sessionTitles") List<String> sessionTitles,
            @RequestParam("startTimes") List<String> startTimes,
            @RequestParam("endTimes") List<String> endTimes,
            @RequestParam(value = "displayOrder", defaultValue = "0") int displayOrder,
            RedirectAttributes redirectAttributes) {
        List<MultipartFile> selected = imageFiles == null ? List.of()
                : imageFiles.stream().filter(file -> file != null && !file.isEmpty()).toList();
        int count = selected.size();
        if (count == 0 || count > 20 || dayNumbers == null || dayNumbers.size() != count
                || scheduleDates == null || scheduleDates.size() != count
                || sessionTitles == null || sessionTitles.size() != count
                || startTimes == null || startTimes.size() != count
                || endTimes == null || endTimes.size() != count) {
            redirectAttributes.addFlashAttribute("errorMessage", "Select 1 to 20 schedule images and complete every session.");
            return "redirect:/admin/conference-schedule";
        }
        if (displayOrder < 0 || displayOrder > Integer.MAX_VALUE - count) {
            redirectAttributes.addFlashAttribute("errorMessage", "Starting display order is outside the supported range.");
            return "redirect:/admin/conference-schedule";
        }

        List<LocalDate> dates = new ArrayList<>(count);
        List<LocalTime> starts = new ArrayList<>(count);
        List<LocalTime> ends = new ArrayList<>(count);
        for (int i = 0; i < count; i++) {
            String title = sessionTitles.get(i) == null ? "" : sessionTitles.get(i).trim();
            if (dayNumbers.get(i) == null || dayNumbers.get(i) < 1 || dayNumbers.get(i) > 3
                    || title.isBlank() || title.length() > 220) {
                redirectAttributes.addFlashAttribute("errorMessage", "Choose Day 1 to 3 and enter a session title up to 220 characters for every row.");
                return "redirect:/admin/conference-schedule";
            }
            try {
                dates.add(LocalDate.parse(scheduleDates.get(i)));
                LocalTime start = LocalTime.parse(startTimes.get(i));
                LocalTime end = LocalTime.parse(endTimes.get(i));
                if (!end.isAfter(start)) {
                    redirectAttributes.addFlashAttribute("errorMessage", "Every session end time must be later than its start time.");
                    return "redirect:/admin/conference-schedule";
                }
                starts.add(start);
                ends.add(end);
            } catch (DateTimeParseException | NullPointerException ex) {
                redirectAttributes.addFlashAttribute("errorMessage", "Choose a valid date and start/end time for each schedule item.");
                return "redirect:/admin/conference-schedule";
            }
        }

        List<String> imageUrls = new ArrayList<>();
        try {
            imageUrls.addAll(galleryStorageService.uploadImages(selected, "schedule"));
            List<ConferenceScheduleItem> items = new ArrayList<>(count);
            for (int i = 0; i < count; i++) {
                ConferenceScheduleItem item = new ConferenceScheduleItem();
                item.setDayNumber(dayNumbers.get(i));
                item.setScheduleDate(dates.get(i));
                item.setSessionTitle(sessionTitles.get(i).trim());
                item.setImageUrl(imageUrls.get(i));
                item.setTimeValue(starts.get(i).toString());
                item.setTimeLabel(toScheduleDisplayTime(starts.get(i).toString()) + " - " + toScheduleDisplayTime(ends.get(i).toString()));
                item.setDisplayOrder(displayOrder + i);
                item.setHighlighted(false);
                item.setActive(true);
                items.add(item);
            }
            conferenceScheduleItemRepository.saveAll(items);
            redirectAttributes.addFlashAttribute("successMessage", items.size() + " conference schedule items added successfully.");
        } catch (RuntimeException ex) {
            for (String imageUrl : imageUrls) {
                try {
                    galleryStorageService.deleteStoredMedia(imageUrl);
                } catch (RuntimeException ignored) {
                    // Keep the original bulk upload error visible to the admin.
                }
            }
            redirectAttributes.addFlashAttribute("errorMessage", ex.getMessage() == null
                    ? "Unable to save conference schedule items. Please try again." : ex.getMessage());
        }
        return "redirect:/admin/conference-schedule";
    }

    @PostMapping("/admin/conference-schedule/{id}")
    public String updateConferenceSchedule(@PathVariable Long id,
                                           @Valid @ModelAttribute("conferenceScheduleItemForm") ConferenceScheduleItemForm form,
                                           BindingResult bindingResult,
                                           @RequestParam(value = "imageFile", required = false) MultipartFile imageFile,
                                           Model model,
                                           RedirectAttributes redirectAttributes) {
        ConferenceScheduleItem item = conferenceScheduleItemRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Schedule item not found."));
        model.addAttribute("mode", "edit");
        model.addAttribute("scheduleItemId", id);
        model.addAttribute("currentImageUrl", item.getImageUrl());
        if (bindingResult.hasErrors()) {
            return "admin/conference-schedule-form";
        }
        if (!LocalTime.parse(form.getEndTime()).isAfter(LocalTime.parse(form.getStartTime()))) {
            bindingResult.rejectValue("endTime", "schedule.endTime.order", "End time must be later than start time.");
            return "admin/conference-schedule-form";
        }

        String imageUrl = item.getImageUrl();
        if (imageFile != null && !imageFile.isEmpty()) {
            try {
                imageUrl = galleryStorageService.uploadImage(imageFile, "schedule");
            } catch (IllegalArgumentException | IllegalStateException ex) {
                bindingResult.reject("schedule.image.invalid", ex.getMessage());
                return "admin/conference-schedule-form";
            }
        }
        applyScheduleForm(form, item, imageUrl);
        conferenceScheduleItemRepository.save(item);
        redirectAttributes.addFlashAttribute("successMessage", "Conference schedule item updated successfully.");
        return "redirect:/admin/conference-schedule";
    }

    private static ConferenceScheduleItemForm toConferenceScheduleForm(ConferenceScheduleItem item) {
        ConferenceScheduleItemForm form = new ConferenceScheduleItemForm();
        form.setDayNumber(item.getDayNumber());
        form.setScheduleDate(item.getScheduleDate());
        form.setSessionTitle(item.getSessionTitle());
        form.setStartTime(toScheduleTimeInput(item.getTimeValue()));
        String[] range = item.getTimeLabel().split("\\s+-\\s+", 2);
        form.setEndTime(toScheduleTimeInput(range.length == 2 ? range[1] : item.getTimeValue()));
        form.setDisplayOrder(item.getDisplayOrder());
        form.setHighlighted(item.isHighlighted());
        form.setActive(item.isActive());
        return form;
    }

    private static void applyScheduleForm(ConferenceScheduleItemForm form, ConferenceScheduleItem item, String imageUrl) {
        item.setDayNumber(form.getDayNumber());
        item.setScheduleDate(form.getScheduleDate());
        item.setSessionTitle(form.getSessionTitle().trim());
        item.setImageUrl(imageUrl);
        item.setTimeLabel(toScheduleDisplayTime(form.getStartTime()) + " - " + toScheduleDisplayTime(form.getEndTime()));
        item.setTimeValue(form.getStartTime().trim());
        item.setDisplayOrder(form.getDisplayOrder());
        item.setHighlighted(form.isHighlighted());
        item.setActive(form.isActive());
    }

    private static final DateTimeFormatter SCHEDULE_DISPLAY_TIME = DateTimeFormatter.ofPattern("hh:mm a", Locale.ENGLISH);
    private static final DateTimeFormatter SCHEDULE_TWELVE_HOUR_TIME = DateTimeFormatter.ofPattern("h:mm a", Locale.ENGLISH);

    private static String toScheduleDisplayTime(String value) {
        return LocalTime.parse(value.trim()).format(SCHEDULE_DISPLAY_TIME);
    }

    // Accepts "14:00", "2:00 pm" or "02:00 PM" and returns the HH:mm value expected by <input type="time">.
    private static String toScheduleTimeInput(String value) {
        if (value == null) {
            return null;
        }
        String normalized = value.trim().replaceAll("\\s+", " ").toUpperCase(Locale.ENGLISH);
        try {
            LocalTime time = normalized.endsWith("AM") || normalized.endsWith("PM")
                    ? LocalTime.parse(normalized, SCHEDULE_TWELVE_HOUR_TIME)
                    : LocalTime.parse(normalized);
            return time.format(DateTimeFormatter.ofPattern("HH:mm"));
        } catch (DateTimeParseException ex) {
            return value.trim();
        }
    }

    @PostMapping("/admin/conference-schedule/{id}/delete")
    public String deleteConferenceSchedule(@PathVariable Long id, RedirectAttributes redirectAttributes) {
        if (conferenceScheduleItemRepository.existsById(id)) {
            conferenceScheduleItemRepository.deleteById(id);
            redirectAttributes.addFlashAttribute("successMessage", "Conference schedule item deleted successfully.");
        } else {
            redirectAttributes.addFlashAttribute("successMessage", "Conference schedule item was already removed.");
        }
        return "redirect:/admin/conference-schedule";
    }

    @GetMapping("/admin/thematic-cards")
    public String thematicCards(Model model) {
        model.addAttribute("thematicCards", thematicDomainCardRepository.findAllByOrderByInstitutionAscDisplayOrderAscIdAsc());
        return "admin/thematic-cards";
    }

    @GetMapping("/admin/thematic-cards/new")
    public String thematicCardForm(Model model) {
        model.addAttribute("thematicDomainCardForm", new ThematicDomainCardForm());
        model.addAttribute("mode", "create");
        return "admin/thematic-card-form";
    }

    @GetMapping("/admin/thematic-cards/{id}/edit")
    public String editThematicCard(@PathVariable Long id, Model model) {
        ThematicDomainCard card = thematicDomainCardRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Thematic area not found."));
        model.addAttribute("thematicDomainCardForm", toThematicCardForm(card));
        model.addAttribute("thematicCardId", id);
        model.addAttribute("mode", "edit");
        return "admin/thematic-card-form";
    }

    @PostMapping("/admin/thematic-cards")
    public String saveThematicCard(@Valid @ModelAttribute("thematicDomainCardForm") ThematicDomainCardForm form,
                                   BindingResult bindingResult,
                                   Model model,
                                   RedirectAttributes redirectAttributes) {
        if (bindingResult.hasErrors()) {
            model.addAttribute("mode", "create");
            return "admin/thematic-card-form";
        }

        ThematicDomainCard card = new ThematicDomainCard();
        applyThematicCardForm(form, card);
        thematicDomainCardRepository.save(card);

        redirectAttributes.addFlashAttribute("successMessage", "Thematic area saved successfully.");
        return "redirect:/admin/thematic-cards";
    }

    @PostMapping("/admin/thematic-cards/{id}")
    public String updateThematicCard(@PathVariable Long id,
                                     @Valid @ModelAttribute("thematicDomainCardForm") ThematicDomainCardForm form,
                                     BindingResult bindingResult,
                                     Model model,
                                     RedirectAttributes redirectAttributes) {
        if (bindingResult.hasErrors()) {
            model.addAttribute("thematicCardId", id);
            model.addAttribute("mode", "edit");
            return "admin/thematic-card-form";
        }
        ThematicDomainCard card = thematicDomainCardRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Thematic area not found."));
        applyThematicCardForm(form, card);
        thematicDomainCardRepository.save(card);
        redirectAttributes.addFlashAttribute("successMessage", "Thematic area updated successfully.");
        return "redirect:/admin/thematic-cards";
    }

    @PostMapping("/admin/thematic-cards/{id}/toggle")
    public String toggleThematicCard(@PathVariable Long id, RedirectAttributes redirectAttributes) {
        thematicDomainCardRepository.findById(id).ifPresent(card -> {
            card.setActive(!card.isActive());
            thematicDomainCardRepository.save(card);
        });
        redirectAttributes.addFlashAttribute("successMessage", "Thematic area visibility updated.");
        return "redirect:/admin/thematic-cards";
    }

    private static ThematicDomainCardForm toThematicCardForm(ThematicDomainCard card) {
        ThematicDomainCardForm form = new ThematicDomainCardForm();
        form.setInstitution(card.getInstitution());
        form.setTitle(card.getTitle());
        form.setIcon(card.getIcon());
        form.setDescription(card.getDescription());
        form.setDisplayOrder(card.getDisplayOrder());
        form.setActive(card.isActive());
        return form;
    }

    private static void applyThematicCardForm(ThematicDomainCardForm form, ThematicDomainCard card) {
        card.setInstitution(form.getInstitution().trim().toLowerCase(Locale.ENGLISH));
        card.setTitle(form.getTitle().trim());
        card.setIcon(cleanIcon(form.getIcon()));
        card.setDescription(form.getDescription().trim());
        card.setDisplayOrder(form.getDisplayOrder());
        card.setActive(form.isActive());
    }

    @PostMapping("/admin/thematic-cards/{id}/delete")
    public String deleteThematicCard(@PathVariable Long id, RedirectAttributes redirectAttributes) {
        if (thematicDomainCardRepository.existsById(id)) {
            thematicDomainCardRepository.deleteById(id);
            redirectAttributes.addFlashAttribute("successMessage", "Thematic card deleted successfully.");
        } else {
            redirectAttributes.addFlashAttribute("successMessage", "Thematic card was already removed.");
        }
        return "redirect:/admin/thematic-cards";
    }

    @PostMapping("/admin/thematic-cards/reset-original")
    public String resetThematicCards(RedirectAttributes redirectAttributes) {
        ThematicDomainCardSeeder.restoreOriginalCards(thematicDomainCardRepository);
        redirectAttributes.addFlashAttribute("successMessage", "Original thematic key terms restored.");
        return "redirect:/admin/thematic-cards";
    }

    @PostMapping("/admin/news-updates")
    public String save(@Valid @ModelAttribute("newsUpdateForm") NewsUpdateForm form,
                       BindingResult bindingResult,
                       @RequestParam(value = "imageFile", required = false) MultipartFile imageFile,
                       RedirectAttributes redirectAttributes) {
        if (bindingResult.hasErrors()) {
            return "admin/news-update-form";
        }

        String imageUrl;
        try {
            imageUrl = galleryStorageService.uploadImage(imageFile, "news");
        } catch (IllegalArgumentException | IllegalStateException ex) {
            bindingResult.reject("news.image.invalid", ex.getMessage());
            return "admin/news-update-form";
        }

        NewsUpdate newsUpdate = new NewsUpdate();
        newsUpdate.setTitle(form.getTitle().trim());
        newsUpdate.setSlug(uniqueSlug(form.getTitle()));
        newsUpdate.setPublishedDate(form.getPublishedDate());
        newsUpdate.setImageUrl(imageUrl);
        newsUpdate.setExcerpt(form.getExcerpt().trim());
        newsUpdate.setContent(form.getContent().trim());
        newsUpdate.setActive(form.isActive());
        newsUpdateRepository.save(newsUpdate);

        redirectAttributes.addFlashAttribute("successMessage", "News update saved successfully.");
        return "redirect:/admin/news-updates";
    }

    @PostMapping("/admin/news-updates/bulk")
    public String saveBulk(@RequestParam("imageFiles") List<MultipartFile> imageFiles,
                           @RequestParam("titles") List<String> titles,
                           @RequestParam("publishedDates") List<String> publishedDates,
                           @RequestParam("excerpts") List<String> excerpts,
                           @RequestParam("contents") List<String> contents,
                           RedirectAttributes redirectAttributes) {
        List<MultipartFile> selected = imageFiles == null ? List.of()
                : imageFiles.stream().filter(file -> file != null && !file.isEmpty()).toList();
        int count = selected.size();
        if (count == 0 || count > 20 || titles == null || titles.size() != count
                || publishedDates == null || publishedDates.size() != count
                || excerpts == null || excerpts.size() != count || contents == null || contents.size() != count) {
            redirectAttributes.addFlashAttribute("errorMessage", "Select 1 to 20 news photos and complete every news item.");
            return "redirect:/admin/news-updates";
        }

        List<LocalDate> dates = new ArrayList<>(count);
        for (int i = 0; i < count; i++) {
            String title = titles.get(i) == null ? "" : titles.get(i).trim();
            String excerpt = excerpts.get(i) == null ? "" : excerpts.get(i).trim();
            String content = contents.get(i) == null ? "" : contents.get(i).trim();
            if (title.isBlank() || title.length() > 220 || excerpt.isBlank() || excerpt.length() > 500
                    || content.isBlank() || content.length() > 10_000) {
                redirectAttributes.addFlashAttribute("errorMessage", "Check each title, excerpt, and full content length.");
                return "redirect:/admin/news-updates";
            }
            try {
                dates.add(LocalDate.parse(publishedDates.get(i)));
            } catch (DateTimeParseException | NullPointerException ex) {
                redirectAttributes.addFlashAttribute("errorMessage", "Choose a valid publication date for each news item.");
                return "redirect:/admin/news-updates";
            }
        }

        List<String> imageUrls = new ArrayList<>();
        try {
            imageUrls.addAll(galleryStorageService.uploadImages(selected, "news"));
            Set<String> reservedSlugs = new HashSet<>();
            List<NewsUpdate> updates = new ArrayList<>(count);
            for (int i = 0; i < count; i++) {
                NewsUpdate update = new NewsUpdate();
                String title = titles.get(i).trim();
                update.setTitle(title);
                update.setSlug(uniqueSlug(title, reservedSlugs));
                update.setPublishedDate(dates.get(i));
                update.setImageUrl(imageUrls.get(i));
                update.setExcerpt(excerpts.get(i).trim());
                update.setContent(contents.get(i).trim());
                update.setActive(true);
                updates.add(update);
            }
            newsUpdateRepository.saveAll(updates);
            redirectAttributes.addFlashAttribute("successMessage", updates.size() + " news updates uploaded successfully.");
        } catch (RuntimeException ex) {
            for (String imageUrl : imageUrls) {
                try {
                    galleryStorageService.deleteStoredMedia(imageUrl);
                } catch (RuntimeException ignored) {
                    // Preserve the original bulk upload error for the admin.
                }
            }
            redirectAttributes.addFlashAttribute("errorMessage", ex.getMessage() == null
                    ? "Unable to save news updates. Please try again." : ex.getMessage());
        }
        return "redirect:/admin/news-updates";
    }

    @PostMapping("/admin/news-updates/{id}/delete")
    public String delete(@PathVariable Long id, RedirectAttributes redirectAttributes) {
        if (newsUpdateRepository.existsById(id)) {
            newsUpdateRepository.deleteById(id);
            redirectAttributes.addFlashAttribute("successMessage", "News update deleted successfully.");
        } else {
            redirectAttributes.addFlashAttribute("successMessage", "News update was already removed.");
        }
        return "redirect:/admin/news-updates";
    }

    private String uniqueSlug(String title) {
        String base = slugify(title);
        String candidate = base;
        int suffix = 2;
        while (newsUpdateRepository.existsBySlug(candidate)) {
            candidate = base + "-" + suffix;
            suffix++;
        }
        return candidate;
    }

    private String uniqueSlug(String title, Set<String> reservedSlugs) {
        String base = slugify(title);
        String candidate = base;
        int suffix = 2;
        while (newsUpdateRepository.existsBySlug(candidate) || !reservedSlugs.add(candidate)) {
            candidate = base + "-" + suffix++;
        }
        return candidate;
    }

    private static String slugify(String value) {
        String slug = value == null ? "" : value.toLowerCase(Locale.ENGLISH)
                .replaceAll("[^a-z0-9]+", "-")
                .replaceAll("(^-|-$)", "");
        return slug.isBlank() ? "tec-verse-update" : slug;
    }

    private static String cleanIcon(String icon) {
        String value = icon == null ? "" : icon.trim();
        if (value.startsWith("bi-")) {
            value = value.substring(3);
        }
        return value.isBlank() ? "stars" : value;
    }

}

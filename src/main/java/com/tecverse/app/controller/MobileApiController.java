package com.tecverse.app.controller;

import java.time.Duration;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.tecverse.app.dto.mobile.MobileLoginRequest;
import com.tecverse.app.entity.ConferenceScheduleItem;
import com.tecverse.app.entity.MobileAttendeePreference;
import com.tecverse.app.entity.MobileNotification;
import com.tecverse.app.entity.MobilePassCheckIn;
import com.tecverse.app.entity.TicketRegistration;
import com.tecverse.app.repository.ChiefGuestRepository;
import com.tecverse.app.repository.ConferenceScheduleItemRepository;
import com.tecverse.app.repository.ExhibitorLogoRepository;
import com.tecverse.app.repository.ExhibitorRepository;
import com.tecverse.app.repository.FaqItemRepository;
import com.tecverse.app.repository.ImportantDateRepository;
import com.tecverse.app.repository.MobileAttendeePreferenceRepository;
import com.tecverse.app.repository.MobileNotificationRepository;
import com.tecverse.app.repository.MobilePassCheckInRepository;
import com.tecverse.app.repository.NewsUpdateRepository;
import com.tecverse.app.repository.SpeakerRepository;
import com.tecverse.app.repository.ThematicDomainCardRepository;
import com.tecverse.app.repository.TicketRegistrationRepository;
import com.tecverse.app.service.MobileSessionService;
import com.tecverse.app.service.RateLimitService;
import com.tecverse.app.service.impl.TicketOtpServiceImpl;

import jakarta.servlet.http.HttpServletRequest;

/** JSON API used by the Flutter client; reads the same PostgreSQL rows as the website. */
@RestController
@RequestMapping(value = "/api/mobile", produces = MediaType.APPLICATION_JSON_VALUE)
public class MobileApiController {

    private final MobileSessionService sessions;
    private final PasswordEncoder passwordEncoder;
    private final TicketRegistrationRepository ticketRegistrations;
    private final ImportantDateRepository importantDates;
    private final ConferenceScheduleItemRepository schedule;
    private final ExhibitorLogoRepository exhibitorLogos;
    private final ExhibitorRepository exhibitors;
    private final SpeakerRepository speakers;
    private final ChiefGuestRepository chiefGuests;
    private final ThematicDomainCardRepository domains;
    private final FaqItemRepository faqs;
    private final NewsUpdateRepository news;
    private final MobileAttendeePreferenceRepository preferences;
    private final MobilePassCheckInRepository checkIns;
    private final TicketOtpServiceImpl otpService;
    private final MobileNotificationRepository notifications;
    private final RateLimitService rateLimitService;

    public MobileApiController(
            MobileSessionService sessions,
            PasswordEncoder passwordEncoder,
            TicketRegistrationRepository ticketRegistrations,
            ImportantDateRepository importantDates,
            ConferenceScheduleItemRepository schedule,
            ExhibitorLogoRepository exhibitorLogos,
            ExhibitorRepository exhibitors,
            SpeakerRepository speakers,
            ChiefGuestRepository chiefGuests,
            ThematicDomainCardRepository domains,
            FaqItemRepository faqs,
            NewsUpdateRepository news,
            MobileAttendeePreferenceRepository preferences,
            MobilePassCheckInRepository checkIns,
            TicketOtpServiceImpl otpService,
            MobileNotificationRepository notifications,
            RateLimitService rateLimitService) {

        this.sessions = sessions;
        this.passwordEncoder = passwordEncoder;
        this.ticketRegistrations = ticketRegistrations;
        this.importantDates = importantDates;
        this.schedule = schedule;
        this.exhibitorLogos = exhibitorLogos;
        this.exhibitors = exhibitors;
        this.speakers = speakers;
        this.chiefGuests = chiefGuests;
        this.domains = domains;
        this.faqs = faqs;
        this.news = news;
        this.preferences = preferences;
        this.checkIns = checkIns;
        this.otpService = otpService;
        this.notifications = notifications;
        this.rateLimitService = rateLimitService;
    }

    @GetMapping("/health")
    public Map<String, Object> health() {
        return Map.of(
                "status", "ok",
                "service", "tecverse-shared-backend");
    }

    @PostMapping("/auth/login")
    public Map<String, Object> login(
            @RequestBody MobileLoginRequest request,
            HttpServletRequest httpRequest) {

        String identifier = request.resolvedIdentifier();

        rateLimitService.check(
                httpRequest,
                "mobile-login",
                identifier == null ? null : identifier.trim().toLowerCase(),
                5,
                Duration.ofMinutes(15),
                30,
                Duration.ofMinutes(15));

        return sessions.login(identifier, request.password());
    }

    @PostMapping("/auth/logout")
    public Map<String, Object> logout(
            @RequestHeader(value = "Authorization", required = false)
            String authorization) {

        sessions.logout(authorization);
        return Map.of("success", true);
    }

    @GetMapping("/profile")
    public Map<String, Object> profile(
            @RequestHeader("Authorization") String authorization) {

        TicketRegistration attendee = sessions.requireAttendee(authorization);

        Map<String, Object> result =
                new LinkedHashMap<>(MobileSessionService.profile(attendee));

        result.put("interests", storedInterests(attendee.getId()));

        return result;
    }

    @PutMapping("/me/interests")
    public Map<String, Object> updateInterests(
            @RequestHeader("Authorization") String authorization,
            @RequestBody Map<String, Object> request) {

        TicketRegistration attendee = sessions.requireAttendee(authorization);

        Object raw = request.get("interests");

        List<String> values = raw instanceof List<?> list
                ? list.stream()
                        .filter(String.class::isInstance)
                        .map(String.class::cast)
                        .distinct()
                        .limit(30)
                        .toList()
                : List.of();

        MobileAttendeePreference preference =
                preferences.findByRegistrationId(attendee.getId())
                        .orElseGet(() -> {
                            MobileAttendeePreference created =
                                    new MobileAttendeePreference();
                            created.setRegistrationId(attendee.getId());
                            return created;
                        });

        try {
            preference.setInterestsJson(
                    new com.fasterxml.jackson.databind.ObjectMapper()
                            .writeValueAsString(values));

            preferences.save(preference);

        } catch (com.fasterxml.jackson.core.JsonProcessingException exception) {
            throw new IllegalStateException(
                    "Could not store attendee preferences.", exception);
        }

        Map<String, Object> result =
                new LinkedHashMap<>(MobileSessionService.profile(attendee));

        result.put("interests", values);

        return result;
    }

    @GetMapping("/event")
    public Map<String, Object> event() {
        return Map.of(
                "title", "Tec-Verse 2026",
                "headline", "Beacon of Rising Tech Innovation & AI",
                "heroBadge", "26-27-28 Nov 2026",
                "heroSubtitle", "Explore. Innovate. Empower the Future.",
                "venue", "Chennai Trade Centre, Mount Poonamallee Road, Nandambakkam, Chennai – 600089",
                "visitorCount", 15000,
                "exhibitorCount",
                exhibitors.countBy() + exhibitorLogos.countByActiveTrue(),
                "speakerCount",
                speakers.findByActiveTrueOrderByDisplayOrderAscIdAsc().size(),
                "description",
                "India’s premier platform for technology, entrepreneurship, and breakthrough innovation.");
    }

    @GetMapping("/schedule")
    public List<Map<String, Object>> schedule() {
        return schedule.findByActiveTrueOrderByDayNumberAscDisplayOrderAscIdAsc()
                .stream()
                .map(this::scheduleItem)
                .toList();
    }

    @GetMapping("/important-dates")
    public List<Map<String, Object>> importantDates() {
        return importantDates.findByActiveTrueOrderByDisplayOrderAscIdAsc()
                .stream()
                .map(item -> {
                    Map<String, Object> result = new LinkedHashMap<>();

                    result.put("id", item.getId());
                    result.put("title", item.getTitle());
                    result.put("eventDate", item.getEventDate());
                    result.put("dateLabel", item.getDateLabel());
                    result.put("iconClass", item.getIconClass());
                    result.put("accentColor", item.getAccentColor());

                    return result;
                })
                .toList();
    }

    @GetMapping("/technology-domains")
    public List<Map<String, Object>> technologyDomains() {
        return domains.findByActiveTrueOrderByInstitutionAscDisplayOrderAscIdAsc()
                .stream()
                .map(item -> mapOfNullable(
                        "id", item.getId(),
                        "title", item.getTitle(),
                        "description", item.getDescription(),
                        "icon", item.getIcon(),
                        "institution", item.getInstitution()))
                .toList();
    }

    @GetMapping("/thematic-sessions")
    public List<Map<String, Object>> thematicSessions(
            @RequestParam(required = false) String domains) {

        List<String> requested = domains == null
                ? List.of()
                : java.util.Arrays.stream(domains.split(","))
                        .map(String::trim)
                        .filter(s -> !s.isEmpty())
                        .map(String::toLowerCase)
                        .toList();

        return schedule.findByActiveTrueOrderByDayNumberAscDisplayOrderAscIdAsc()
                .stream()
                .filter(item -> requested.isEmpty()
                        || (item.getSessionTitle() != null
                                && requested.stream().anyMatch(key ->
                                        item.getSessionTitle()
                                                .toLowerCase()
                                                .contains(key))))
                .map(this::scheduleItem)
                .toList();
    }

    @GetMapping("/exhibitors")
    public List<Map<String, Object>> exhibitors() {
        return exhibitorLogos.findByActiveTrueOrderByDisplayOrderAscIdAsc()
                .stream()
                .map(item -> mapOfNullable(
                        "id", item.getId(),
                        "companyName", item.getCompanyName(),
                        "name", item.getCompanyName(),
                        "logoUrl", item.getImageUrl(),
                        "imageUrl", item.getImageUrl(),
                        "stallAllocation", item.getStallAllocation()))
                .toList();
    }

    @GetMapping("/speakers")
    public List<Map<String, Object>> speakers() {
        List<Map<String, Object>> result = new ArrayList<>();

        speakers.findByActiveTrueOrderByDisplayOrderAscIdAsc()
                .forEach(item -> result.add(mapOfNullable(
                        "id", item.getId(),
                        "name", item.getName(),
                        "designation", item.getDesignation(),
                        "organization", item.getOrganization(),
                        "imageUrl", item.getProfileImageUrl(),
                        "sessionTiming",
                        item.getSessionTiming() == null
                                ? "" : item.getSessionTiming())));

        chiefGuests.findByActiveTrueOrderByDisplayOrderAscIdAsc()
                .forEach(item -> result.add(mapOfNullable(
                        "id", "guest-" + item.getId(),
                        "name", item.getName(),
                        "designation", item.getDesignation(),
                        "organization", item.getOrganization(),
                        "imageUrl", item.getImageUrl(),
                        "sessionTiming", "")));

        return result;
    }

    @GetMapping("/faq")
    public List<Map<String, Object>> faqs() {
        return faqs.findByPageKeyAndActiveTrueOrderByDisplayOrderAscIdAsc("home")
                .stream()
                .map(item -> mapOfNullable(
                        "id", item.getId(),
                        "question", item.getQuestion(),
                        "answer", item.getAnswer(),
                        "category", "General"))
                .toList();
    }

    @GetMapping("/faq/search")
    public List<Map<String, Object>> searchFaqs(
            @RequestParam(required = false, defaultValue = "") String query) {

        String needle = query == null ? "" : query.trim().toLowerCase();

        return faqs().stream()
                .filter(item ->
                        Objects.toString(item.get("question"), "")
                                .toLowerCase().contains(needle)
                        || Objects.toString(item.get("answer"), "")
                                .toLowerCase().contains(needle))
                .toList();
    }

    @GetMapping("/news")
    public List<Map<String, Object>> news() {
        return news.findByActiveTrueOrderByPublishedDateDescIdDesc()
                .stream()
                .map(item -> mapOfNullable(
                        "id", item.getId(),
                        "slug", item.getSlug(),
                        "title", item.getTitle(),
                        "date", item.getDateLabel(),
                        "publishedDate",
                        item.getPublishedDate() == null
                                ? null : item.getPublishedDate().toString(),
                        "imageUrl", item.getImageUrl(),
                        "excerpt", item.getDisplayExcerpt(),
                        "content", item.getContent()))
                .toList();
    }

    @GetMapping("/notifications")
    public List<Map<String, Object>> notifications(
            @RequestHeader("Authorization") String authorization) {

        TicketRegistration attendee = sessions.requireAttendee(authorization);

        return notifications.findTop100ByRegistrationIdOrderByCreatedAtDesc(attendee.getId())
                .stream()
                .map(this::notificationItem)
                .toList();
    }

    @PostMapping("/notifications/{id}/read")
    @Transactional
    public Map<String, Object> markNotificationRead(
            @RequestHeader("Authorization") String authorization,
            @PathVariable Long id) {

        TicketRegistration attendee = sessions.requireAttendee(authorization);

        MobileNotification notification =
                notifications.findByIdAndRegistrationId(id, attendee.getId())
                        .orElseThrow(() ->
                                new IllegalArgumentException("Notification not found."));

        notification.setRead(true);
        notifications.save(notification);

        return Map.of("success", true);
    }

    @PostMapping("/notifications/read-all")
    @Transactional
    public Map<String, Object> markAllNotificationsRead(
            @RequestHeader("Authorization") String authorization) {

        TicketRegistration attendee = sessions.requireAttendee(authorization);

        notifications.findTop100ByRegistrationIdOrderByCreatedAtDesc(attendee.getId())
                .forEach(item -> item.setRead(true));

        return Map.of("success", true);
    }

    @PostMapping("/auth/forgot-password")
    public Map<String, Object> forgotPassword(
            @RequestBody Map<String, String> request,
            HttpServletRequest httpRequest) {

        String email = firstNonBlank(
                request.get("email"), request.get("identifier"));

        rateLimitService.check(
                httpRequest,
                "mobile-password-reset-send",
                null,
                0,
                Duration.ofHours(1),
                20,
                Duration.ofHours(1));

        long retryAfterSeconds = email == null || email.isBlank()
                ? 0
                : rateLimitService.recordPasswordResetSend(
                        email, 3, Duration.ofMinutes(1));

        otpService.sendPasswordResetOtp(email);

        return Map.of(
                "message",
                "If an account matches that email, a password reset OTP has been sent.",
                "retryAfterSeconds", retryAfterSeconds);
    }

    @PostMapping("/auth/verify-reset-otp")
    public Map<String, Object> verifyResetOtp(
            @RequestBody Map<String, String> request,
            HttpServletRequest httpRequest) {

        String email = firstNonBlank(
                request.get("email"), request.get("identifier"));

        rateLimitService.check(
                httpRequest,
                "mobile-password-reset-verify",
                email,
                5,
                Duration.ofMinutes(15),
                30,
                Duration.ofMinutes(15));

        String resetToken =
                otpService.verifyPasswordResetOtp(email, request.get("otp"));

        return mapOfNullable(
                "success", true,
                "resetToken", resetToken);
    }

    @PostMapping("/auth/reset-password")
    @Transactional
    public Map<String, Object> resetPassword(
            @RequestBody Map<String, String> request,
            HttpServletRequest httpRequest) {

        String email = firstNonBlank(
                request.get("email"), request.get("identifier"));

        rateLimitService.check(
                httpRequest,
                "mobile-password-reset-complete",
                email,
                5,
                Duration.ofHours(1),
                20,
                Duration.ofHours(1));

        String newPassword = request.get("newPassword");

        if (newPassword == null || newPassword.length() < 8) {
            throw new IllegalArgumentException(
                    "Password must contain at least 8 characters.");
        }

        if (!newPassword.equals(request.get("confirmPassword"))) {
            throw new IllegalArgumentException(
                    "Password and confirmation do not match.");
        }

        if (!otpService.consumePasswordResetVerification(
                email, request.get("resetToken"))) {
            throw new IllegalArgumentException(
                    "Verify a valid reset OTP before changing the password.");
        }

        TicketRegistration attendee =
                ticketRegistrations.findByEmailIgnoreCase(email)
                        .orElseThrow(() ->
                                new IllegalArgumentException(
                                        "No attendee account was found for that email address."));

        attendee.setPasswordHash(passwordEncoder.encode(newPassword));
        ticketRegistrations.save(attendee);

        return Map.of(
                "success", true,
                "message", "Password updated successfully.");
    }

    /**
     * Permanently deletes the signed-in attendee's account and all data linked to it.
     * The current password is required.
     */
    @PostMapping("/me/delete")
    @Transactional
    public Map<String, Object> deleteAccount(
            @RequestHeader("Authorization") String authorization,
            @RequestBody Map<String, String> request,
            HttpServletRequest httpRequest) {

        TicketRegistration attendee = sessions.requireAttendee(authorization);

        rateLimitService.check(
                httpRequest,
                "mobile-account-delete",
                attendee.getEmail(),
                5,
                Duration.ofMinutes(15),
                30,
                Duration.ofMinutes(15));

        String password = request.get("password");

        if (password == null
                || attendee.getPasswordHash() == null
                || !passwordEncoder.matches(password, attendee.getPasswordHash())) {
            throw new IllegalArgumentException(
                    "Incorrect password. Your account was not deleted.");
        }

        Long id = attendee.getId();

        notifications.deleteByRegistrationId(id);
        preferences.deleteByRegistrationId(id);
        checkIns.deleteByRegistrationId(id);
        ticketRegistrations.delete(attendee);

        // Existing tokens stop working because the registration no longer exists.
        sessions.logout(authorization);

        return Map.of(
                "success", true,
                "message", "Your account and registration data have been deleted.");
    }

    @GetMapping("/digital-pass")
    public Map<String, Object> digitalPass(
            @RequestHeader("Authorization") String authorization) {

        TicketRegistration attendee = sessions.requireAttendee(authorization);
        return pass(attendee);
    }

    @GetMapping("/digital-pass/{passId}/status")
    public Map<String, Object> passStatus(
            @RequestHeader("Authorization") String authorization,
            @PathVariable String passId) {

        TicketRegistration attendee = sessions.requireAttendee(authorization);

        if (!passId.equals("TV26-PASS-" + suffix(attendee.getReferenceNumber()))) {
            throw new IllegalArgumentException("Digital pass not found.");
        }

        return pass(attendee);
    }

    @PostMapping("/pass/verify")
    @Transactional
    public Map<String, Object> verifyPass(
            @RequestBody Map<String, String> request) {

        // Identify passes using the random scan token, not the sequential reference number.
        // Accepts "TECVERSE26:<token>" and URLs ending in "/ticket/scan/<token>".
        String scanToken = scanTokenFrom(request.get("qrToken"));

        if (scanToken == null) {
            throw new IllegalArgumentException("Invalid event pass.");
        }

        TicketRegistration attendee =
                ticketRegistrations.findByScanToken(scanToken)
                        .orElseThrow(() ->
                                new IllegalArgumentException("Pass registration not found."));

        if (checkIns.findByRegistrationId(attendee.getId()).isPresent()) {
            throw new IllegalArgumentException(
                    "This pass has already been checked in.");
        }

        MobilePassCheckIn checkIn = new MobilePassCheckIn();
        checkIn.setRegistrationId(attendee.getId());
        checkIn.setGateId(firstNonBlank(request.get("gateId"), "main-gate"));
        checkIn.setCheckedInAt(java.time.LocalDateTime.now());

        checkIns.saveAndFlush(checkIn);

        return pass(attendee);
    }

    private Map<String, Object> pass(TicketRegistration attendee) {
        Map<String, Object> result = new LinkedHashMap<>();

        result.put("passId", "TV26-PASS-" + suffix(attendee.getReferenceNumber()));
        result.put("attendeeId", attendee.getReferenceNumber());
        result.put("userId", attendee.getId().toString());
        result.put("holderName", attendee.getOfficialName());
        result.put("organization",
                MobileSessionService.profile(attendee).get("organization"));
        result.put("designation",
                MobileSessionService.profile(attendee).get("designation"));
        result.put("category", attendee.getCategory());
        result.put("eventName", "Tec-Verse 2026");
        result.put("eventDates", "26-27 NOVEMBER 2026");
        result.put("venue", "CHENNAI TRADE CENTRE, NANDAMBAKKAM, CHENNAI 600089");
        result.put("attendanceDays", attendee.getAttendanceDays());
        result.put("qrToken", "TECVERSE26:" + attendee.getScanToken());

        MobilePassCheckIn checkIn =
                checkIns.findByRegistrationId(attendee.getId()).orElse(null);

        result.put("status", checkIn == null ? "active" : "used");
        result.put("issuedAt", attendee.getCreatedAt().toString());

        if (checkIn != null) {
            result.put("checkedInAt", checkIn.getCheckedInAt().toString());
        }

        return result;
    }

    private Map<String, Object> scheduleItem(ConferenceScheduleItem item) {
        return mapOfNullable(
                "id", item.getId(),
                "dayNumber", item.getDayNumber(),
                "scheduleDate", item.getDateValue(),
                "dayTitle", item.getDayTitle(),
                "sessionTitle", item.getSessionTitle(),
                "timeLabel", item.getTimeLabel(),
                "timeValue", item.getTimeValue(),
                "highlighted", item.isHighlighted(),
                "imageUrl", item.getImageUrl() == null ? "" : item.getImageUrl());
    }

    private Map<String, Object> notificationItem(MobileNotification item) {
        return mapOfNullable(
                "id", item.getId(),
                "title", item.getTitle(),
                "message", item.getMessage(),
                "category", item.getCategory(),
                "priority", item.getPriority(),
                "actionRoute", item.getActionRoute() == null ? "" : item.getActionRoute(),
                "isRead", item.isRead(),
                "createdAt",
                item.getCreatedAt() == null ? null : item.getCreatedAt().toString());
    }

    /**
     * Builds a JSON response map that safely permits nullable database fields.
     */
    private static Map<String, Object> mapOfNullable(Object... entries) {
        if (entries == null || entries.length % 2 != 0) {
            throw new IllegalArgumentException(
                    "Map entries must be supplied as key-value pairs.");
        }

        Map<String, Object> result = new LinkedHashMap<>();

        for (int i = 0; i < entries.length; i += 2) {
            if (!(entries[i] instanceof String key)) {
                throw new IllegalArgumentException(
                        "Map keys must be non-null strings.");
            }

            result.put(key, entries[i + 1]);
        }

        return result;
    }

    private static final java.util.regex.Pattern SCAN_TOKEN =
            java.util.regex.Pattern.compile(
                    "^(?:TECVERSE26:|.*/ticket/scan/)([a-f0-9]{32})/?$");

    private static String scanTokenFrom(String qrValue) {
        if (qrValue == null) {
            return null;
        }

        java.util.regex.Matcher matcher =
                SCAN_TOKEN.matcher(qrValue.trim());

        return matcher.matches() ? matcher.group(1) : null;
    }

    private static String suffix(String reference) {
        return reference.length() >= 6
                ? reference.substring(reference.length() - 6)
                : reference;
    }

    private static String firstNonBlank(String... values) {
        for (String value : values) {
            if (value != null && !value.isBlank()) {
                return value.trim();
            }
        }

        return "";
    }

    private List<String> storedInterests(Long registrationId) {
        return preferences.findByRegistrationId(registrationId)
                .map(preference -> {
                    try {
                        return new com.fasterxml.jackson.databind.ObjectMapper()
                                .readValue(
                                        preference.getInterestsJson(),
                                        new com.fasterxml.jackson.core.type.TypeReference<List<String>>() {});
                    } catch (com.fasterxml.jackson.core.JsonProcessingException exception) {
                        return List.<String>of();
                    }
                })
                .orElse(List.of());
    }
}
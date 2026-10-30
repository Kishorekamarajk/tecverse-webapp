package com.tecverse.app.controller;

import com.tecverse.app.entity.Exhibitor;
import com.tecverse.app.entity.SponsorEnquiry;
import com.tecverse.app.repository.ExhibitorRepository;
import com.tecverse.app.repository.SponsorEnquiryRepository;
import com.tecverse.app.service.BusinessConversationService;
import com.tecverse.app.service.BusinessQueryNotificationService;
import com.tecverse.app.service.RateLimitService;
import com.tecverse.app.service.TicketOtpService;
import com.tecverse.app.exception.RateLimitExceededException;
import com.tecverse.app.util.ValidationUtil;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.time.Duration;
import java.util.LinkedHashMap;
import java.util.Map;

@Controller
public class BusinessPortalController {
    private static final org.slf4j.Logger log = org.slf4j.LoggerFactory.getLogger(BusinessPortalController.class);
    private static final String PORTAL_ROLE = "TECVERSE_BUSINESS_ROLE";
    private static final String PORTAL_PHONE = "TECVERSE_BUSINESS_PHONE";
    private static final String PORTAL_NAME = "TECVERSE_BUSINESS_NAME";

    private final ExhibitorRepository exhibitors;
    private final SponsorEnquiryRepository sponsors;
    private final TicketOtpService otpService;
    private final RateLimitService rateLimits;
    private final BusinessConversationService conversations;
    private final BusinessQueryNotificationService queryNotifications;

    public BusinessPortalController(ExhibitorRepository exhibitors, SponsorEnquiryRepository sponsors,
                                    TicketOtpService otpService, RateLimitService rateLimits,
                                    BusinessConversationService conversations,
                                    BusinessQueryNotificationService queryNotifications) {
        this.exhibitors = exhibitors;
        this.sponsors = sponsors;
        this.otpService = otpService;
        this.rateLimits = rateLimits;
        this.conversations = conversations;
        this.queryNotifications = queryNotifications;
    }

    @PostMapping("/business-login/{role}/send-otp")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> sendLoginOtp(@PathVariable String role,
                                                             @RequestBody Map<String, String> body,
                                                             HttpServletRequest request) {
        String phone = normalizePhone(body.get("phone"));
        rateLimits.check(request, "business-login-otp-send-" + role, phone,
                5, Duration.ofMinutes(3), 30, Duration.ofMinutes(3));
        rateLimits.check(request, "business-login-otp-daily-" + role, phone,
                20, Duration.ofDays(1), 150, Duration.ofDays(1));
        rateLimits.check(request, "business-login-otp-global-ip", null,
                0, Duration.ofMinutes(3), 60, Duration.ofMinutes(3));
        rateLimits.check(request, "business-login-otp-global-daily-ip", null,
                0, Duration.ofDays(1), 300, Duration.ofDays(1));
        rateLimits.check(request, "business-login-otp-cooldown-" + role, phone,
                1, Duration.ofSeconds(30), 100, Duration.ofMinutes(1));

        boolean registered = switch (role) {
            case "exhibitor" -> exhibitors.findLatestByPhoneNormalized(phone).isPresent();
            case "sponsor" -> sponsors.findByPhone(phone).isPresent();
            default -> throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Choose a valid login type.");
        };
        if (!registered) {
            Map<String, Object> result = new LinkedHashMap<>();
            result.put("success", false);
            result.put("message", "This mobile number is not registered as an " + role + ". Please register to continue.");
            result.put("registrationUrl", role.equals("exhibitor") ? "/exhibitor-registration" : "/become-sponsor");
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(result);
        }

        otpService.sendExhibitorMobileOtp(phone);
        return ResponseEntity.ok(Map.of("success", true, "message", "A one-time code was sent to your registered mobile number."));
    }

    @PostMapping("/business-login/{role}/verify-otp")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> verifyLoginOtp(@PathVariable String role,
                                                               @RequestBody Map<String, String> body,
                                                               HttpServletRequest request) {
        if (!role.equals("exhibitor") && !role.equals("sponsor")) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Choose a valid login type.");
        }
        String phone = normalizePhone(body.get("phone"));
        String code = body.get("otp");
        if (code == null || !code.matches("^\\d{6}$")) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Enter the 6-digit code.");
        }
        rateLimits.check(request, "business-login-otp-verify-" + role, phone,
                8, Duration.ofMinutes(3), 90, Duration.ofMinutes(3));
        rateLimits.check(request, "business-login-otp-global-verify-ip", null,
                0, Duration.ofMinutes(3), 180, Duration.ofMinutes(3));
        String contactName = role.equals("exhibitor")
                ? exhibitors.findLatestByPhoneNormalized(phone).map(Exhibitor::getFullName).orElse(null)
                : sponsors.findByPhone(phone).map(SponsorEnquiry::getName).orElse(null);
        if (contactName == null) throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Registration not found. Please register first.");

        otpService.verifyMobileOtp(phone, code);
        HttpSession session = request.getSession(true);
        request.changeSessionId();
        session.setAttribute(PORTAL_ROLE, role);
        session.setAttribute(PORTAL_PHONE, phone);
        session.setAttribute(PORTAL_NAME, contactName);
        return ResponseEntity.ok(Map.of("success", true, "redirectUrl", "/" + role + "/dashboard"));
    }

    @GetMapping("/exhibitor/dashboard")
    public String exhibitorDashboard(HttpSession session, Model model, HttpServletResponse response) {
        String phone = requirePortalSession(session, "exhibitor");
        Exhibitor exhibitor = exhibitors.findLatestByPhoneNormalized(phone)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
        response.setHeader("Cache-Control", "no-store");
        model.addAttribute("businessRole", "exhibitor");
        model.addAttribute("businessSignedIn", true);
        model.addAttribute("businessContactName", exhibitor.getFullName());
        model.addAttribute("exhibitor", exhibitor);
        model.addAttribute("conversationMessages", conversations.messages("exhibitor", phone));
        return "business-dashboard";
    }

    @GetMapping("/sponsor/dashboard")
    public String sponsorDashboard(HttpSession session, Model model, HttpServletResponse response) {
        String phone = requirePortalSession(session, "sponsor");
        SponsorEnquiry sponsor = sponsors.findByPhone(phone)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
        response.setHeader("Cache-Control", "no-store");
        model.addAttribute("businessRole", "sponsor");
        model.addAttribute("businessSignedIn", true);
        model.addAttribute("businessContactName", sponsor.getName());
        model.addAttribute("sponsor", sponsor);
        model.addAttribute("conversationMessages", conversations.messages("sponsor", phone));
        return "business-dashboard";
    }

    @PostMapping("/{role}/dashboard/query")
    public String submitQuery(@PathVariable String role, @SessionAttribute(name = PORTAL_PHONE, required = false) String phone,
                              @SessionAttribute(name = PORTAL_ROLE, required = false) String sessionRole,
                              @RequestParam @NotBlank @Size(max = 4000) String query,
                              HttpServletRequest request, RedirectAttributes flash) {
        if (!role.equals(sessionRole) || phone == null || (!role.equals("exhibitor") && !role.equals("sponsor"))) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Please sign in to continue.");
        }
        if (query == null || query.isBlank() || query.length() > 4000) {
            flash.addFlashAttribute("portalError", "Enter a query of up to 4,000 characters.");
            return "redirect:/" + role + "/dashboard#query";
        }
        try {
            rateLimits.check(request, "business-dashboard-query", phone, 5, Duration.ofHours(1), 20, Duration.ofHours(1));
            String name;
            String company;
            if (role.equals("exhibitor")) {
                Exhibitor exhibitor = exhibitors.findLatestByPhoneNormalized(phone).orElseThrow();
                name = exhibitor.getFullName(); company = exhibitor.getCompanyName();
            } else {
                SponsorEnquiry sponsor = sponsors.findByPhone(phone).orElseThrow();
                name = sponsor.getName(); company = sponsor.getCompany();
            }
            conversations.add(role, phone, name, company, "BUSINESS", query);
            try { queryNotifications.notifyStaff(role, name, company, phone, query); }
            catch (org.springframework.core.task.TaskRejectedException queueFull) {
                log.warn("Could not queue staff email notification for saved business portal message", queueFull);
            }
            flash.addFlashAttribute("portalSuccess", "Your query has been added to your conversation. Our team will reply here shortly.");
        } catch (RateLimitExceededException limited) {
            flash.addFlashAttribute("portalError", limited.getMessage());
        } catch (RuntimeException failure) {
            flash.addFlashAttribute("portalError", "We could not send your query right now. Please email stall-tecverse@cdac.in.");
        }
        return "redirect:/" + role + "/dashboard#query";
    }

    @PostMapping("/business-portal/logout")
    public String logout(HttpSession session) {
        session.removeAttribute(PORTAL_ROLE);
        session.removeAttribute(PORTAL_PHONE);
        session.removeAttribute(PORTAL_NAME);
        return "redirect:/";
    }

    private static String requirePortalSession(HttpSession session, String role) {
        String actualRole = (String) session.getAttribute(PORTAL_ROLE);
        String phone = (String) session.getAttribute(PORTAL_PHONE);
        if (!role.equals(actualRole) || phone == null) throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Please sign in to continue.");
        return phone;
    }

    private static String normalizePhone(String value) {
        String phone = ValidationUtil.normalizeIndianMobile(value);
        if (phone == null || !phone.matches("^[6-9]\\d{9}$")) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Enter a valid 10-digit Indian mobile number.");
        }
        return phone;
    }

    @ExceptionHandler({IllegalArgumentException.class, RateLimitExceededException.class})
    @ResponseBody
    public ResponseEntity<Map<String, Object>> handleLoginError(RuntimeException failure) {
        HttpStatus status = failure instanceof RateLimitExceededException ? HttpStatus.TOO_MANY_REQUESTS : HttpStatus.BAD_REQUEST;
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("success", false);
        result.put("message", failure.getMessage() == null ? "Unable to complete sign in." : failure.getMessage());
        if (failure instanceof RateLimitExceededException limited) {
            result.put("retryAfter", limited.getRetryAfterSeconds());
            return ResponseEntity.status(status).header("Retry-After", Long.toString(limited.getRetryAfterSeconds())).body(result);
        }
        return ResponseEntity.status(status).body(result);
    }
}

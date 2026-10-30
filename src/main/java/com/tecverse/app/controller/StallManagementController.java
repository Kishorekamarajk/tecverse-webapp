package com.tecverse.app.controller;

import java.time.Duration;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;

import com.tecverse.app.service.BusinessConversationService;
import com.tecverse.app.service.RateLimitService;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;

@Controller
public class StallManagementController {
    private static final String AUTH = "TECVERSE_STALL_MANAGEMENT_AUTH";
    private final String username;
    private final String passwordHash;
    private final String dummyHash;
    private final PasswordEncoder passwords;
    private final RateLimitService rateLimits;
    private final BusinessConversationService conversations;

    public StallManagementController(
            @Value("${tecverse.stall-management.username:stall-verse@cdac.in}") String username,
            @Value("${tecverse.stall-management.password:}") String password,
            PasswordEncoder passwords, RateLimitService rateLimits,
            BusinessConversationService conversations) {
        this.username = username.trim();
        this.passwords = passwords;
        this.passwordHash = password.isBlank() ? "" : passwords.encode(password);
        this.dummyHash = passwords.encode("stall-management-invalid-login-timing");
        this.rateLimits = rateLimits;
        this.conversations = conversations;
    }

    @GetMapping("/stall-managementlogin")
    public String loginPage(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session != null && Boolean.TRUE.equals(session.getAttribute(AUTH))) return "redirect:/stall-management";
        return "stall-management-login";
    }

    @PostMapping("/stall-managementlogin")
    public String login(@RequestParam String username, @RequestParam String password,
                        HttpServletRequest request, Model model) {
        rateLimits.check(request, "stall-management-login", username,
                5, Duration.ofMinutes(15), 20, Duration.ofHours(1));
        String submittedPassword = password == null ? "" : password;
        boolean matches = passwords.matches(submittedPassword, passwordHash.isEmpty() ? dummyHash : passwordHash);
        if (passwordHash.isEmpty() || !this.username.equalsIgnoreCase(username.trim()) || !matches) {
            model.addAttribute("loginError", "Email or password is incorrect.");
            return "stall-management-login";
        }
        HttpSession session = request.getSession(true);
        request.changeSessionId();
        session.setAttribute(AUTH, true);
        return "redirect:/stall-management";
    }

    @GetMapping("/stall-management")
    public String inbox(@RequestParam(required = false) String conversation,
                        @RequestParam(name = "type", required = false) String requestedType,
                        HttpServletRequest request, Model model) {
        requireStaff(request);
        var allThreads = conversations.conversations();
        long exhibitorCount = allThreads.stream().filter(thread -> "exhibitor".equals(thread.role())).count();
        long sponsorCount = allThreads.stream().filter(thread -> "sponsor".equals(thread.role())).count();
        String roleFilter = "sponsor".equals(requestedType) || "exhibitor".equals(requestedType)
                ? requestedType : exhibitorCount > 0 || sponsorCount == 0 ? "exhibitor" : "sponsor";
        var threads = allThreads.stream().filter(thread -> roleFilter.equals(thread.role())).toList();
        boolean requestedConversationExists = false;
        if (conversation != null) {
            for (var thread : threads) {
                if ((thread.role() + ":" + thread.phone()).equals(conversation)) {
                    requestedConversationExists = true;
                    break;
                }
            }
        }
        String selected = requestedConversationExists ? conversation
                : threads.isEmpty() ? "" : threads.get(0).role() + ":" + threads.get(0).phone();
        model.addAttribute("conversations", threads);
        model.addAttribute("exhibitorCount", exhibitorCount);
        model.addAttribute("sponsorCount", sponsorCount);
        model.addAttribute("selectedType", roleFilter);
        model.addAttribute("selectedConversation", selected);
        return "stall-management-inbox";
    }

    @PostMapping("/stall-management/reply")
    public String reply(@RequestParam String role, @RequestParam String phone,
                        @RequestParam String message, HttpServletRequest request) {
        requireStaff(request);
        if ((!"sponsor".equals(role) && !"exhibitor".equals(role)) || phone == null || !phone.matches("[6-9]\\d{9}")
                || message == null || message.isBlank() || message.length() > 4000
                || conversations.messages(role, phone).isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Conversation or reply is invalid.");
        }
        rateLimits.check(request, "stall-management-reply", phone,
                40, Duration.ofMinutes(10), 300, Duration.ofHours(1));
        conversations.add(role, phone, "Tec-Verse Stall Team", "Event Support", "STAFF", message);
        return "redirect:/stall-management?type=" + role + "#" + role + "-" + phone;
    }

    @PostMapping("/stall-management/logout")
    public String logout(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session != null) session.invalidate();
        return "redirect:/stall-managementlogin?logout";
    }

    private static void requireStaff(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session == null || !Boolean.TRUE.equals(session.getAttribute(AUTH))) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED);
        }
    }
}

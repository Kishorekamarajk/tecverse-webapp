package com.tecverse.app.security;

import com.tecverse.app.exception.RateLimitExceededException;
import com.tecverse.app.service.RateLimitService;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.time.Duration;

/** Enforces exact-case CAPTCHA validation before Spring Security processes admin credentials. */
public class AdminCaptchaFilter extends OncePerRequestFilter {
    public static final String ANSWER_PARAMETER = "captchaAnswer";

    private final AdminCaptchaService captchaService;
    private final RateLimitService rateLimitService;

    public AdminCaptchaFilter(AdminCaptchaService captchaService, RateLimitService rateLimitService) {
        this.captchaService = captchaService;
        this.rateLimitService = rateLimitService;
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        return !"POST".equalsIgnoreCase(request.getMethod())
                || !"/adminportal".equals(request.getServletPath());
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        boolean valid = session != null && captchaService.consume(session, request.getParameter(ANSWER_PARAMETER));
        if (valid) {
            chain.doFilter(request, response);
            return;
        }

        try {
            rateLimitService.check(request, "admin-login", request.getParameter("username"),
                    5, Duration.ofMinutes(15), 20, Duration.ofMinutes(15));
            response.sendRedirect(request.getContextPath() + "/adminportal?captchaError=true");
        } catch (RateLimitExceededException limited) {
            response.setStatus(429);
            response.setHeader("Retry-After", Long.toString(limited.getRetryAfterSeconds()));
            response.setContentType("text/plain;charset=UTF-8");
            response.getWriter().write("Too many login attempts. Please wait before trying again.");
        }
    }
}

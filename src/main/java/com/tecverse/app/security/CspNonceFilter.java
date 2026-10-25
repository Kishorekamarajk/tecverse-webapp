package com.tecverse.app.security;

import java.io.IOException;
import java.security.SecureRandom;
import java.util.Base64;

import org.springframework.web.filter.OncePerRequestFilter;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

/**
 * Issues a fresh nonce per request and writes a Content-Security-Policy that allows only
 * scripts carrying that nonce (plus the listed hosts). Templates reference it via
 * {@code th:nonce="${cspNonce}"} on inline {@code <script>} blocks.
 */
final class CspNonceFilter extends OncePerRequestFilter {

    static final String NONCE_ATTRIBUTE = "cspNonce";

    private static final SecureRandom RANDOM = new SecureRandom();

    // style-src keeps 'unsafe-inline' because the Tailwind CDN build injects <style> elements at
    // runtime and templates use style attributes; inline styles cannot execute script.
    private static final String POLICY_TEMPLATE = "default-src 'self'; "
            + "base-uri 'self'; object-src 'none'; frame-ancestors 'self'; form-action 'self'; "
            + "script-src 'self' 'nonce-%s' https://cdn.jsdelivr.net "
            + "https://code.jquery.com https://cdn.tailwindcss.com https://*.googletagmanager.com; "
            + "script-src-attr 'none'; "
            + "style-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net https://fonts.googleapis.com; "
            + "img-src 'self' data: blob: https:; "
            + "font-src 'self' data: https://cdn.jsdelivr.net https://fonts.gstatic.com; "
            // Google Analytics 4 (fragments/analytics.html) loads from googletagmanager and reports to these hosts.
            + "connect-src 'self' https://cdn.jsdelivr.net https://cdn.tailwindcss.com "
            + "https://*.google-analytics.com https://*.analytics.google.com https://*.googletagmanager.com; "
            + "frame-src 'self' https://www.youtube.com https://www.youtube-nocookie.com https://www.google.com https://maps.google.com; "
            + "media-src 'self' blob: https:";

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        byte[] bytes = new byte[18];
        RANDOM.nextBytes(bytes);
        String nonce = Base64.getEncoder().encodeToString(bytes);

        request.setAttribute(NONCE_ATTRIBUTE, nonce);
        response.setHeader("Content-Security-Policy", POLICY_TEMPLATE.formatted(nonce));
        filterChain.doFilter(request, response);
    }
}

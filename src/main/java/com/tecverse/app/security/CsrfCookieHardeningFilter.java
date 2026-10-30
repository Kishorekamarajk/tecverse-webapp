package com.tecverse.app.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpServletResponseWrapper;
import org.springframework.security.web.csrf.CookieCsrfTokenRepository;
import org.springframework.security.web.csrf.CsrfToken;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

/** Reissues an existing CSRF cookie with current security attributes on page loads. */
public class CsrfCookieHardeningFilter extends OncePerRequestFilter {
    private final CookieCsrfTokenRepository repository;

    public CsrfCookieHardeningFilter(CookieCsrfTokenRepository repository) {
        this.repository = repository;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        HttpServletResponse effectiveResponse = response;
        if (isLocalHttp(request)) {
            // Browsers reject Secure cookies over http://localhost. Keep CSRF enabled,
            // but allow the matching cookie to be stored for local development.
            effectiveResponse = new HttpServletResponseWrapper(response) {
                @Override public void addCookie(jakarta.servlet.http.Cookie cookie) {
                    cookie.setSecure(false);
                    super.addCookie(cookie);
                }
                @Override public void addHeader(String name, String value) {
                    super.addHeader(name, isSetCookie(name) ? withoutSecure(value) : value);
                }
                @Override public void setHeader(String name, String value) {
                    super.setHeader(name, isSetCookie(name) ? withoutSecure(value) : value);
                }
            };
        }
        String accept = request.getHeader("Accept");
        if ("GET".equalsIgnoreCase(request.getMethod()) && accept != null && accept.contains("text/html")) {
            CsrfToken existing = repository.loadToken(request);
            if (existing != null) {
                repository.saveToken(existing, request, effectiveResponse);
            }
        }
        chain.doFilter(request, effectiveResponse);
    }

    private static boolean isLocalHttp(HttpServletRequest request) {
        if (request.isSecure()) return false;
        String host = request.getServerName();
        return "localhost".equalsIgnoreCase(host) || "127.0.0.1".equals(host) || "::1".equals(host);
    }

    private static boolean isSetCookie(String name) { return "Set-Cookie".equalsIgnoreCase(name); }

    private static String withoutSecure(String value) {
        return value.replaceAll("(?i);\\s*Secure(?=;|$)", "");
    }
}

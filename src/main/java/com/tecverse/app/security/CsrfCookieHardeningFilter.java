package com.tecverse.app.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
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
        String accept = request.getHeader("Accept");
        if ("GET".equalsIgnoreCase(request.getMethod()) && accept != null && accept.contains("text/html")) {
            CsrfToken existing = repository.loadToken(request);
            if (existing != null) {
                repository.saveToken(existing, request, response);
            }
        }
        chain.doFilter(request, response);
    }
}

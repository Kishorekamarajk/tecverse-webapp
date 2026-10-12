package com.tecverse.app.security;

import java.io.IOException;
import java.util.regex.Pattern;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

/** Removes legacy servlet session identifiers from incoming URLs. */
@Component
public class SessionIdUrlFilter extends OncePerRequestFilter {
    private static final Pattern SESSION_ID = Pattern.compile(";jsessionid=[^;/?]*", Pattern.CASE_INSENSITIVE);

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        String requestUri = request.getRequestURI();
        String cleanUri = SESSION_ID.matcher(requestUri).replaceAll("");
        if (!cleanUri.equals(requestUri)) {
            String query = request.getQueryString();
            response.sendRedirect(cleanUri + (query == null || query.isBlank() ? "" : "?" + query));
            return;
        }
        filterChain.doFilter(request, response);
    }
}

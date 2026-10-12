package com.tecverse.app.controller;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.CacheControl;
import org.springframework.http.ResponseEntity;
import org.springframework.security.web.csrf.CookieCsrfTokenRepository;
import org.springframework.security.web.csrf.CsrfToken;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestAttribute;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class CsrfTokenController {
    private final CookieCsrfTokenRepository csrfTokenRepository;

    public CsrfTokenController(CookieCsrfTokenRepository csrfTokenRepository) {
        this.csrfTokenRepository = csrfTokenRepository;
    }

    @GetMapping("/csrf")
    public ResponseEntity<TokenResponse> token(@RequestAttribute("_csrf") CsrfToken csrfToken,
                                                HttpServletRequest request,
                                                HttpServletResponse response) {
        // Upgrade cookies issued by earlier versions while preserving their token value.
        CsrfToken storedToken = csrfTokenRepository.loadToken(request);
        if (storedToken != null) {
            csrfTokenRepository.saveToken(storedToken, request, response);
        }
        return ResponseEntity.ok().cacheControl(CacheControl.noStore())
                .body(new TokenResponse(csrfToken.getHeaderName(), csrfToken.getToken()));
    }

    public record TokenResponse(String headerName, String token) { }
}

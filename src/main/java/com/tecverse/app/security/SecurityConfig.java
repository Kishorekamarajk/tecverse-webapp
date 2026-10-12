package com.tecverse.app.security;

import java.nio.file.Paths;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Duration;
import java.util.Arrays;
import java.util.function.Supplier;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.authentication.AuthenticationProvider;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.AuthenticationFailureHandler;
import org.springframework.security.web.csrf.CookieCsrfTokenRepository;
import org.springframework.security.web.csrf.CsrfToken;
import org.springframework.security.web.csrf.CsrfTokenRequestAttributeHandler;
import org.springframework.security.web.csrf.CsrfTokenRequestHandler;
import org.springframework.security.web.csrf.XorCsrfTokenRequestAttributeHandler;
import org.springframework.util.StringUtils;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import com.tecverse.app.exception.RateLimitExceededException;
import com.tecverse.app.service.RateLimitService;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@Configuration
public class SecurityConfig implements WebMvcConfigurer {

    private static final String ADMIN_USERNAME = "admin@cdac.in";
    private static final String ADMIN_PASSWORD = "23weSDxc@23";
    private final String uploadsLocation;
    private final String galleryLocation;
    private final String documentsLocation;
    private final String[] mobileWebOrigins;

    public SecurityConfig(@Value("${tecverse.storage.uploads-dir:uploads}") String uploadsDirectory,
                          @Value("${tecverse.storage.gallery-dir:uploads/gallery}") String galleryDirectory,
                          @Value("${tecverse.storage.documents-dir:uploads/exhibitor-documents}") String documentsDirectory,
                          @Value("${tecverse.mobile.web-origins:}") String mobileWebOrigins) {
        this.uploadsLocation = resourceLocation(uploadsDirectory);
        this.galleryLocation = resourceLocation(galleryDirectory);
        this.documentsLocation = resourceLocation(documentsDirectory);
        this.mobileWebOrigins = Arrays.stream(mobileWebOrigins.split(",")).map(String::trim).filter(s -> !s.isEmpty()).toArray(String[]::new);
    }

    private static String resourceLocation(String directory) {
        String location = Paths.get(directory).toAbsolutePath().normalize().toUri().toString();
        return location.endsWith("/") ? location : location + "/";
    }

    @Bean
    PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    SecurityFilterChain securityFilterChain(HttpSecurity http, RateLimitService rateLimitService,
                                            AuthenticationProvider adminAuthenticationProvider) throws Exception {
        CookieCsrfTokenRepository csrfTokenRepository = CookieCsrfTokenRepository.withHttpOnlyFalse();
        csrfTokenRepository.setCookiePath("/");

        http.authorizeHttpRequests(authorize -> authorize
                        .requestMatchers("/adminportal").permitAll()
                        .requestMatchers("/admin", "/admin/**").hasRole("ADMIN")
                        .requestMatchers("/api/mobile/pass/verify").hasRole("ADMIN")
                        .anyRequest().permitAll())
                .csrf(csrf -> csrf
                        .csrfTokenRepository(csrfTokenRepository)
                        .csrfTokenRequestHandler(new SpaCsrfTokenRequestHandler()))
                .formLogin(form -> form
                        .loginPage("/adminportal")
                        .loginProcessingUrl("/adminportal")
                        .usernameParameter("username")
                        .passwordParameter("password")
                        .defaultSuccessUrl("/admin", true)
                        .failureUrl("/adminportal?error=true")
                        .failureHandler(adminLoginFailureHandler(rateLimitService))
                        .permitAll())
                .httpBasic(AbstractHttpConfigurer::disable)
                .logout(logout -> logout
                        .logoutUrl("/admin/logout")
                        .logoutSuccessUrl("/adminportal?logout=true")
                        .invalidateHttpSession(true)
                        .deleteCookies("JSESSIONID")
                        .permitAll());

        http.authenticationProvider(adminAuthenticationProvider);

        http.csrf(csrf -> csrf.ignoringRequestMatchers(request -> {
            String path = request.getServletPath();
            return path.startsWith("/api/mobile/") && !path.equals("/api/mobile/pass/verify");
        }));

        return http.build();
    }

    private AuthenticationFailureHandler adminLoginFailureHandler(RateLimitService rateLimitService) {
        return (request, response, exception) -> {
            try {
                rateLimitService.check(request, "admin-login", request.getParameter("username"),
                        5, Duration.ofMinutes(15), 20, Duration.ofMinutes(15));
                response.sendRedirect(request.getContextPath() + "/adminportal?error=true");
            } catch (RateLimitExceededException limited) {
                response.setStatus(429);
                response.setHeader("Retry-After", Long.toString(limited.getRetryAfterSeconds()));
                response.setContentType("text/plain;charset=UTF-8");
                response.getWriter().write("Too many login attempts. Please wait before trying again.");
            }
        };
    }

    @Bean
    AuthenticationProvider adminAuthenticationProvider() {
        return new AuthenticationProvider() {
            @Override
            public org.springframework.security.core.Authentication authenticate(
                    org.springframework.security.core.Authentication authentication) {
                String username = authentication.getName();
                Object credentials = authentication.getCredentials();
                String password = credentials == null ? "" : credentials.toString();
                boolean passwordMatches = MessageDigest.isEqual(
                        ADMIN_PASSWORD.getBytes(StandardCharsets.UTF_8),
                        password.getBytes(StandardCharsets.UTF_8));

                if (username != null
                        && ADMIN_USERNAME.equalsIgnoreCase(username.trim())
                        && passwordMatches) {
                    return UsernamePasswordAuthenticationToken.authenticated(
                            ADMIN_USERNAME, null, java.util.List.of(new SimpleGrantedAuthority("ROLE_ADMIN")));
                }
                throw new BadCredentialsException("Invalid username or password.");
            }

            @Override
            public boolean supports(Class<?> authentication) {
                return UsernamePasswordAuthenticationToken.class.isAssignableFrom(authentication);
            }
        };
    }

    private static final class SpaCsrfTokenRequestHandler implements CsrfTokenRequestHandler {
        private final CsrfTokenRequestHandler plain = new CsrfTokenRequestAttributeHandler();
        private final CsrfTokenRequestHandler xor = new XorCsrfTokenRequestAttributeHandler();

        @Override
        public void handle(HttpServletRequest request, HttpServletResponse response,
                           Supplier<CsrfToken> csrfToken) {
            xor.handle(request, response, csrfToken);
            csrfToken.get();
        }

        @Override
        public String resolveCsrfTokenValue(HttpServletRequest request, CsrfToken csrfToken) {
            String headerValue = request.getHeader(csrfToken.getHeaderName());
            return StringUtils.hasText(headerValue)
                    ? plain.resolveCsrfTokenValue(request, csrfToken)
                    : xor.resolveCsrfTokenValue(request, csrfToken);
        }
    }

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        if (mobileWebOrigins.length > 0) {
            registry.addMapping("/api/mobile/**").allowedOrigins(mobileWebOrigins)
                    .allowedMethods("GET", "POST", "PUT", "OPTIONS")
                    .allowedHeaders("Authorization", "Content-Type", "Accept")
                    .maxAge(3600);
        }
    }

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        // Register the generic root first so Spring selects the more specific
        // gallery/documents mappings for their URL prefixes.
        registry.addResourceHandler("/uploads/**")
                .addResourceLocations(uploadsLocation);
        registry.addResourceHandler("/uploads/documents/**")
                .addResourceLocations(documentsLocation);
        registry.addResourceHandler("/uploads/gallery/**")
                .addResourceLocations(galleryLocation);
    }
}

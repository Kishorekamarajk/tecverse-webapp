package com.tecverse.app.security;

import java.nio.file.Paths;
import java.time.Duration;
import java.util.Arrays;
import java.util.function.Supplier;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.boot.web.servlet.ServletContextInitializer;
import org.springframework.boot.web.servlet.ServletListenerRegistrationBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.Ordered;
import org.springframework.http.HttpMethod;
import org.springframework.security.authentication.AuthenticationProvider;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.authorization.AuthorizationDecision;
import org.springframework.security.core.session.SessionRegistry;
import org.springframework.security.core.session.SessionRegistryImpl;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.AuthenticationFailureHandler;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.security.web.csrf.CookieCsrfTokenRepository;
import org.springframework.security.web.csrf.CsrfFilter;
import org.springframework.security.web.csrf.CsrfToken;
import org.springframework.security.web.csrf.CsrfTokenRequestHandler;
import org.springframework.security.web.csrf.XorCsrfTokenRequestAttributeHandler;
import org.springframework.security.web.header.HeaderWriterFilter;
import org.springframework.security.web.header.writers.ReferrerPolicyHeaderWriter;
import org.springframework.security.web.header.writers.StaticHeadersWriter;
import org.springframework.security.web.session.HttpSessionEventPublisher;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import com.tecverse.app.exception.RateLimitExceededException;
import com.tecverse.app.service.RateLimitService;

import jakarta.servlet.SessionCookieConfig;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@Configuration
public class SecurityConfig implements WebMvcConfigurer {

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
    SessionRegistry adminSessionRegistry() {
        return new SessionRegistryImpl();
    }

    @Bean
    ServletListenerRegistrationBean<HttpSessionEventPublisher> httpSessionEventPublisher() {
        return new ServletListenerRegistrationBean<>(new HttpSessionEventPublisher());
    }

    /** Runs before every other filter so security, rate limits and redirects see the real client and HTTPS. */
    @Bean
    FilterRegistrationBean<TrustedProxyFilter> trustedProxyFilter(
            @Value("${tecverse.proxy.trusted:127.0.0.1,::1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16}") String trustedProxies) {
        FilterRegistrationBean<TrustedProxyFilter> registration = new FilterRegistrationBean<>(new TrustedProxyFilter(trustedProxies));
        registration.setOrder(Ordered.HIGHEST_PRECEDENCE);
        return registration;
    }

    /** Session cookie flags are set here because server.servlet.session.* is ignored in a WAR deployment. */
    @Bean
    ServletContextInitializer sessionCookieHardening(@Value("${tecverse.cookies.secure:true}") boolean secureCookies) {
        return servletContext -> {
            SessionCookieConfig cookie = servletContext.getSessionCookieConfig();
            cookie.setHttpOnly(true);
            cookie.setSecure(secureCookies);
            cookie.setAttribute("SameSite", "Lax");
        };
    }

    @Bean
    CookieCsrfTokenRepository csrfTokenRepository(@Value("${tecverse.cookies.secure:true}") boolean secureCookies) {
        CookieCsrfTokenRepository repository = CookieCsrfTokenRepository.withHttpOnlyFalse();
        repository.setCookiePath("/");
        repository.setCookieHttpOnly(true);
        repository.setCookieCustomizer(cookie -> cookie.sameSite("Lax").secure(secureCookies));
        return repository;
    }

    @Bean
    SecurityFilterChain securityFilterChain(HttpSecurity http, RateLimitService rateLimitService,
                                            AuthenticationProvider adminAuthenticationProvider,
                                            AdminCaptchaService adminCaptchaService,
                                            CookieCsrfTokenRepository csrfTokenRepository,
                                            SessionRegistry adminSessionRegistry) throws Exception {

        http.authorizeHttpRequests(authorize -> authorize
                        .requestMatchers("/adminportal").permitAll()
                        .requestMatchers("/stall-managementlogin").permitAll()
                        .requestMatchers("/stall-management", "/stall-management/**").access((authentication, context) -> {
                            jakarta.servlet.http.HttpSession session = context.getRequest().getSession(false);
                            return new AuthorizationDecision(session != null
                                    && Boolean.TRUE.equals(session.getAttribute("TECVERSE_STALL_MANAGEMENT_AUTH")));
                        })
                        .requestMatchers(HttpMethod.POST, "/admin/logout").hasAnyRole("ADMIN", "ADMIN_VIEWER")
                        .requestMatchers(HttpMethod.GET, "/admin", "/admin/**").hasAnyRole("ADMIN", "ADMIN_VIEWER")
                        .requestMatchers("/admin/**").hasRole("ADMIN")
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
                .headers(headers -> headers
                        .referrerPolicy(referrerPolicy -> referrerPolicy
                                .policy(ReferrerPolicyHeaderWriter.ReferrerPolicy.STRICT_ORIGIN_WHEN_CROSS_ORIGIN))
                        .addHeaderWriter(new StaticHeadersWriter(
                                "Cross-Origin-Opener-Policy", "same-origin-allow-popups"))
                        .addHeaderWriter(new StaticHeadersWriter(
                                "Cross-Origin-Embedder-Policy", "credentialless"))
                        .addHeaderWriter(new StaticHeadersWriter(
                                "Cross-Origin-Resource-Policy", "same-origin"))
                        // X-XSS-Protection is set once by the front-end web server; the application must not
                        // send its own copy, or clients receive two conflicting values.
                        .xssProtection(xss -> xss.disable()))
                .logout(logout -> logout
                        .logoutUrl("/admin/logout")
                        .logoutSuccessUrl("/adminportal?logout=true")
                        .invalidateHttpSession(true)
                        .deleteCookies("JSESSIONID")
                        .permitAll())
                .sessionManagement(session -> session
                        .maximumSessions(1)
                        .maxSessionsPreventsLogin(false)
                        .expiredUrl("/adminportal?sessionExpired=true")
                        .sessionRegistry(adminSessionRegistry));

        http.authenticationProvider(adminAuthenticationProvider);
        http.addFilterBefore(new AdminCaptchaFilter(adminCaptchaService, rateLimitService),
                UsernamePasswordAuthenticationFilter.class);
        http.addFilterBefore(new CsrfCookieHardeningFilter(csrfTokenRepository), CsrfFilter.class);
        http.addFilterBefore(new CspNonceFilter(), HeaderWriterFilter.class);

        http.csrf(csrf -> csrf.ignoringRequestMatchers(request -> {
            // Path within the application, independent of how the dispatcher servlet is mapped.
            String path = request.getRequestURI().substring(request.getContextPath().length());
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
    AuthenticationProvider adminAuthenticationProvider(PasswordEncoder passwordEncoder,
            @Value("${tecverse.admin.username:admin@cdac.in}") String adminUsername,
            @Value("${tecverse.admin.password-hash:}") String adminPasswordHash,
            @Value("${tecverse.admin.password:23weSDxc@23}") String adminPassword,
            @Value("${tecverse.admin.viewer.username:tecview@cdac.in}") String viewerUsername,
            @Value("${tecverse.admin.viewer.password-hash:}") String viewerPasswordHash,
            @Value("${tecverse.admin.viewer.password:Tec1234#$}") String viewerPassword) {
        // Hardcoded defaults apply unless overridden by configuration (secrets file or env vars).
        // Prefer a BCrypt hash; a plain password is hashed once at startup and never kept.
        String configuredHash = !adminPasswordHash.isBlank() ? adminPasswordHash.trim()
                : adminPassword.isBlank() ? "" : passwordEncoder.encode(adminPassword);
        String configuredUsername = adminUsername.trim();
        boolean adminEnabled = !configuredUsername.isEmpty() && !configuredHash.isEmpty();
        String configuredViewerHash = !viewerPasswordHash.isBlank() ? viewerPasswordHash.trim()
                : viewerPassword.isBlank() ? "" : passwordEncoder.encode(viewerPassword);
        String configuredViewerUsername = viewerUsername.trim();
        boolean viewerEnabled = !configuredViewerUsername.isEmpty() && !configuredViewerHash.isEmpty()
                && !configuredViewerUsername.equalsIgnoreCase(configuredUsername);
        if (!adminEnabled) {
            org.slf4j.LoggerFactory.getLogger(SecurityConfig.class).warn(
                    "Admin login is disabled: set tecverse.admin.username and tecverse.admin.password-hash "
                    + "(or ADMIN_USERNAME / ADMIN_PASSWORD_HASH environment variables).");
        }
        if (!viewerEnabled) {
            org.slf4j.LoggerFactory.getLogger(SecurityConfig.class).info(
                    "Admin viewer login is disabled until ADMIN_VIEWER_PASSWORD or ADMIN_VIEWER_PASSWORD_HASH is configured.");
        }
        // Compared against unknown usernames so the response time does not reveal whether the username matched.
        String dummyHash = passwordEncoder.encode("tecverse-dummy-" + System.nanoTime());
        return new AuthenticationProvider() {
            @Override
            public org.springframework.security.core.Authentication authenticate(
                    org.springframework.security.core.Authentication authentication) {
                String username = authentication.getName();
                Object credentials = authentication.getCredentials();
                String password = credentials == null ? "" : credentials.toString();
                boolean usernameMatches = adminEnabled && username != null
                        && configuredUsername.equalsIgnoreCase(username.trim());
                boolean viewerUsernameMatches = viewerEnabled && username != null
                        && configuredViewerUsername.equalsIgnoreCase(username.trim());
                String expectedHash = usernameMatches ? configuredHash
                        : viewerUsernameMatches ? configuredViewerHash : dummyHash;
                boolean passwordMatches = passwordEncoder.matches(password, expectedHash);

                if (usernameMatches && passwordMatches) {
                    return UsernamePasswordAuthenticationToken.authenticated(
                            configuredUsername, null, java.util.List.of(new SimpleGrantedAuthority("ROLE_ADMIN")));
                }
                if (viewerUsernameMatches && passwordMatches) {
                    return UsernamePasswordAuthenticationToken.authenticated(
                            configuredViewerUsername, null, java.util.List.of(new SimpleGrantedAuthority("ROLE_ADMIN_VIEWER")));
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
        private final CsrfTokenRequestHandler xor = new XorCsrfTokenRequestAttributeHandler();

        @Override
        public void handle(HttpServletRequest request, HttpServletResponse response,
                           Supplier<CsrfToken> csrfToken) {
            xor.handle(request, response, csrfToken);
            csrfToken.get();
        }

        @Override
        public String resolveCsrfTokenValue(HttpServletRequest request, CsrfToken csrfToken) {
            return xor.resolveCsrfTokenValue(request, csrfToken);
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

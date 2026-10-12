package com.tecverse.app.config;

import java.net.Inet4Address;
import java.net.Inet6Address;
import java.net.InetAddress;
import java.time.Duration;
import java.util.Arrays;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.TimeUnit;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Component;

/** Logs effective non-secret SMTP settings and the JVM DNS order; never sends mail. */
@Component
public class SmtpConfigurationDiagnostics implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(SmtpConfigurationDiagnostics.class);
    private static final Duration DNS_LOOKUP_LIMIT = Duration.ofSeconds(2);

    private final Environment environment;

    public SmtpConfigurationDiagnostics(Environment environment) {
        this.environment = environment;
    }

    @Override
    public void run(ApplicationArguments args) {
        String host = property("spring.mail.host", "").trim();
        String port = property("spring.mail.port", "").trim();
        boolean usernamePresent = hasText(property("spring.mail.username", ""));
        boolean passwordPresent = hasText(property("spring.mail.password", ""));
        boolean auth = bool("spring.mail.properties.mail.smtp.auth", true);
        boolean startTls = bool("spring.mail.properties.mail.smtp.starttls.enable", true);
        boolean startTlsRequired = bool("spring.mail.properties.mail.smtp.starttls.required", true);
        boolean ssl = bool("spring.mail.properties.mail.smtp.ssl.enable", false);

        log.info("SMTP effective configuration host={} port={} usernameConfigured={} passwordConfigured={} auth={} startTls={} startTlsRequired={} implicitSsl={}",
                host, port, usernamePresent, passwordPresent, auth, startTls, startTlsRequired, ssl);
        log.info("JVM network preferences preferIPv4Stack={} preferIPv6Addresses={}",
                System.getProperty("java.net.preferIPv4Stack", "false"),
                System.getProperty("java.net.preferIPv6Addresses", "false"));

        if (ssl && startTls) {
            log.error("SMTP configuration enables both implicit SSL and STARTTLS. Use one mode matching the provider's port.");
        }
        if (host.isBlank()) return;

        CompletableFuture.supplyAsync(() -> resolveInJvmOrder(host))
                .orTimeout(DNS_LOOKUP_LIMIT.toMillis(), TimeUnit.MILLISECONDS)
                .whenComplete((addresses, error) -> {
                    if (error != null) {
                        log.warn("SMTP DNS diagnostic failed for host {}: {}", host, rootMessage(error));
                    } else {
                        log.info("SMTP addresses in JVM resolver order for {}: {}", host, addresses);
                    }
                });
    }

    private String property(String name, String fallback) {
        String value = environment.getProperty(name);
        return value == null ? fallback : value;
    }

    private boolean bool(String name, boolean fallback) {
        String value = environment.getProperty(name);
        return value == null || value.isBlank() ? fallback : Boolean.parseBoolean(value.trim());
    }

    private static String resolveInJvmOrder(String host) {
        try {
            return Arrays.stream(InetAddress.getAllByName(host))
                    .map(address -> address.getHostAddress() + (address instanceof Inet4Address ? " (IPv4)"
                            : address instanceof Inet6Address ? " (IPv6)" : ""))
                    .toList().toString();
        } catch (Exception ex) {
            throw new IllegalStateException(ex);
        }
    }

    private static String rootMessage(Throwable throwable) {
        Throwable root = throwable;
        while (root.getCause() != null && root.getCause() != root) root = root.getCause();
        return root.getMessage() == null ? root.getClass().getSimpleName() : root.getMessage();
    }

    private static boolean hasText(String value) {
        return value != null && !value.isBlank();
    }
}

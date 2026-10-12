package com.tecverse.app.config;

import java.util.Map;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.context.config.ConfigDataEnvironmentPostProcessor;
import org.springframework.boot.env.EnvironmentPostProcessor;
import org.springframework.core.Ordered;
import org.springframework.core.env.ConfigurableEnvironment;
import org.springframework.core.env.MapPropertySource;

/** Normalizes MAIL_PORT before Spring Boot binds its integer-valued MailProperties. */
public final class SmtpPortEnvironmentPostProcessor implements EnvironmentPostProcessor, Ordered {

    public static final int DEFAULT_PORT = 587;
    private static final String PROPERTY_SOURCE = "tecverseSmtpPortNormalization";

    @Override
    public int getOrder() {
        return ConfigDataEnvironmentPostProcessor.ORDER + 1;
    }

    @Override
    public void postProcessEnvironment(ConfigurableEnvironment environment, SpringApplication application) {
        String configuredPort = environment.getProperty("MAIL_PORT");
        if (configuredPort == null || configuredPort.isBlank()) {
            configuredPort = environment.getProperty("spring.mail.port");
        }
        int port = parsePort(configuredPort);
        environment.getPropertySources().addFirst(new MapPropertySource(
                PROPERTY_SOURCE, Map.of("spring.mail.port", Integer.toString(port))));
    }

    static int parsePort(String configuredPort) {
        if (configuredPort == null || configuredPort.isBlank()) return DEFAULT_PORT;
        final int port;
        try {
            port = Integer.parseInt(configuredPort.trim());
        } catch (NumberFormatException ex) {
            throw new IllegalStateException("MAIL_PORT must be an integer between 1 and 65535.", ex);
        }
        if (port < 1 || port > 65535) {
            throw new IllegalStateException("MAIL_PORT must be an integer between 1 and 65535.");
        }
        return port;
    }
}

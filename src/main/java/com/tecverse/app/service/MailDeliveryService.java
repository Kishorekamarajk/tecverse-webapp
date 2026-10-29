package com.tecverse.app.service;

import java.net.ConnectException;
import java.net.UnknownHostException;
import java.net.SocketTimeoutException;
import javax.net.ssl.SSLException;
import javax.net.ssl.SSLHandshakeException;
import java.util.Locale;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.MailAuthenticationException;
import org.springframework.mail.MailException;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Service
public class MailDeliveryService {

    private static final Logger log =
            LoggerFactory.getLogger(MailDeliveryService.class);

    private final JavaMailSender mailSender;
    private final String fromAddress;
    private final String smtpHost;
    private final int smtpPort;
    private final boolean usernameConfigured;
    private final boolean passwordConfigured;
    private final boolean authenticationEnabled;

    public MailDeliveryService(
            JavaMailSender mailSender,
            @Value("${spring.mail.username:}") String fromAddress,
            @Value("${spring.mail.host:}") String smtpHost,
            @Value("${spring.mail.port:0}") int smtpPort,
            @Value("${spring.mail.password:}") String smtpPassword,
            @Value("${spring.mail.properties.mail.smtp.auth:true}") boolean authenticationEnabled) {

        this.mailSender = mailSender;
        this.fromAddress = fromAddress;
        this.smtpHost = smtpHost;
        this.smtpPort = smtpPort;
        this.usernameConfigured = fromAddress != null && !fromAddress.isBlank();
        this.passwordConfigured = smtpPassword != null && !smtpPassword.isBlank();
        this.authenticationEnabled = authenticationEnabled;
    }

    /**
     * Sends an email using the default label.
     * This matches TicketOtpServiceImpl.sendSimple(to, subject, text).
     */
    public boolean sendSimple(
            String to,
            String subject,
            String text) {

        return sendSimple(to, subject, text, "Email");
    }

    /**
     * Sends an email with a custom fallback/log label.
     */
    public boolean sendSimple(
            String to,
            String subject,
            String text,
            String fallbackLabel) {

        SimpleMailMessage message = new SimpleMailMessage();

        if (fromAddress != null && !fromAddress.isBlank()) {
            message.setFrom(fromAddress);
        }

        message.setTo(to);
        message.setSubject(subject);
        message.setText(text);

        try {
            log.debug(
                    "Attempting SMTP delivery via {}:{} for {} email.",
                    smtpHost,
                    smtpPort,
                    fallbackLabel
            );

            mailSender.send(message);

            log.debug(
                    "SMTP delivery via {}:{} succeeded for {} email.",
                    smtpHost,
                    smtpPort,
                    fallbackLabel
            );

            return true;

        } catch (MailException ex) {
            SmtpFailure failure = classifyFailure(ex);
            Throwable root = rootCause(ex);
            String cause = root.getMessage() == null ? "no server detail" : root.getMessage();
            log.error("SMTP delivery failed: host={}, port={}, category={}, causeType={}, cause={}. "
                            + "SMTP settings: authenticationEnabled={}, usernameConfigured={}, passwordConfigured={}. "
                            + "Verify the SMTP account credentials and account policy; do not include secrets in logs.",
                    smtpHost, smtpPort, failure, root.getClass().getSimpleName(), cause,
                    authenticationEnabled, usernameConfigured, passwordConfigured);

            throw new IllegalStateException(
                    userMessage(failure),
                    ex
            );
        }
    }

    public static String rootMessage(Throwable throwable) {
        Throwable root = rootCause(throwable);
        return root.getMessage() == null
                ? throwable.getMessage()
                : root.getMessage();
    }

    static SmtpFailure classifyFailure(Throwable exception) {
        String reason = rootMessage(exception);
        if (hasCause(exception, UnknownHostException.class)) return SmtpFailure.DNS_FAILURE;
        if (hasCause(exception, MailAuthenticationException.class)
                || containsIgnoreCase(reason, "authentication failed")
                || containsIgnoreCase(reason, "could not connect to smtp host using username")) {
            return SmtpFailure.AUTHENTICATION_FAILURE;
        }
        if (hasCause(exception, SSLHandshakeException.class)
                || hasCause(exception, SSLException.class)
                || containsIgnoreCase(reason, "starttls")
                || containsIgnoreCase(reason, "tls handshake")) {
            return SmtpFailure.TLS_FAILURE;
        }
        if (hasCause(exception, SocketTimeoutException.class)) {
            return containsIgnoreCase(reason, "connect timed out")
                    ? SmtpFailure.CONNECT_TIMEOUT : SmtpFailure.READ_TIMEOUT;
        }
        if (hasCause(exception, ConnectException.class)) {
            return containsIgnoreCase(reason, "connection refused")
                    ? SmtpFailure.CONNECT_REFUSED : SmtpFailure.CONNECT_FAILURE;
        }
        if (containsIgnoreCase(reason, "relay") || containsIgnoreCase(reason, "550")
                || containsIgnoreCase(reason, "5.7.")) {
            return SmtpFailure.SMTP_REJECTION;
        }
        return SmtpFailure.GENERAL_SMTP_FAILURE;
    }

    private static String userMessage(SmtpFailure failure) {
        return switch (failure) {
            case DNS_FAILURE, CONNECT_REFUSED, CONNECT_TIMEOUT, CONNECT_FAILURE ->
                    "Mail server is temporarily down. Please try again later.";
            case READ_TIMEOUT -> "Mail server is temporarily down. Please try again later.";
            case TLS_FAILURE -> "A secure connection to the email server could not be established. Please contact support.";
            case AUTHENTICATION_FAILURE -> "The email service could not authenticate. Check the configured SMTP account credentials.";
            case SMTP_REJECTION -> "The email server rejected the message. Please contact support.";
            case GENERAL_SMTP_FAILURE -> "Mail server is temporarily down. Please try again later.";
        };
    }

    private static Throwable rootCause(Throwable exception) {
        Throwable root = exception;
        while (root.getCause() != null && root.getCause() != root) root = root.getCause();
        return root;
    }

    enum SmtpFailure {
        DNS_FAILURE,
        CONNECT_REFUSED,
        CONNECT_TIMEOUT,
        CONNECT_FAILURE,
        READ_TIMEOUT,
        TLS_FAILURE,
        AUTHENTICATION_FAILURE,
        SMTP_REJECTION,
        GENERAL_SMTP_FAILURE
    }

    private static boolean hasCause(
            Throwable throwable,
            Class<? extends Throwable> type) {

        for (
                Throwable current = throwable;
                current != null;
                current = current.getCause()
        ) {
            if (type.isInstance(current)) {
                return true;
            }
        }

        return false;
    }

    private static boolean containsIgnoreCase(
            String value,
            String fragment) {

        return value != null
                && value.toLowerCase(Locale.ROOT).contains(fragment);
    }
}

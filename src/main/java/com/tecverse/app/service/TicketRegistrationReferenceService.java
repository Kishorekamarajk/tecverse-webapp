package com.tecverse.app.service;

import com.tecverse.app.dto.TicketRegistrationRequest;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.util.Locale;

@Service
public class TicketRegistrationReferenceService {
    private static final long MAX_SEQUENCE = 999_999;
    private final JdbcTemplate jdbcTemplate;

    public TicketRegistrationReferenceService(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @EventListener(ApplicationReadyEvent.class)
    public void initializeExistingSequences() {
        jdbcTemplate.update("""
                INSERT INTO tecverse_ticket_registration_sequences (reference_code, last_value)
                SELECT SUBSTRING(reference_number, 5, 2),
                       MAX(SUBSTRING(reference_number, 7, 6)::BIGINT)
                FROM tecverse_ticket_registrations
                WHERE reference_number ~ '^TV26[A-Z]{2}[0-9]{6}$'
                GROUP BY SUBSTRING(reference_number, 5, 2)
                ON CONFLICT (reference_code) DO NOTHING
                """);
    }

    public String nextReference(TicketRegistrationRequest request) {
        String code = referenceCode(request);
        Long sequence = jdbcTemplate.queryForObject("""
                INSERT INTO tecverse_ticket_registration_sequences (reference_code, last_value)
                VALUES (?, 1)
                ON CONFLICT (reference_code) DO UPDATE
                SET last_value = tecverse_ticket_registration_sequences.last_value + 1
                RETURNING last_value
                """, Long.class, code);
        if (sequence == null || sequence > MAX_SEQUENCE) {
            throw new IllegalStateException("Registration reference sequence is exhausted for " + code + ".");
        }
        return "TV26" + code + String.format(Locale.ROOT, "%06d", sequence);
    }

    static String referenceCode(TicketRegistrationRequest request) {
        return switch (request.getCategory()) {
            case "ACADEMIA" -> switch (normalize(request.getAcademiaRole())) {
                case "STUDENT" -> "AS";
                case "FACULTY", "PROFESSOR / FACULTY", "PROFESSOR/FACULTY" -> "AP";
                case "RESEARCH SCHOLAR" -> "AR";
                default -> throw new IllegalArgumentException("Choose a valid Academia applicant role.");
            };
            case "STATE_GOVERNMENT" -> "SG";
            case "CENTRAL_GOVERNMENT" -> "CG";
            case "INDUSTRY_STARTUP" -> "ID";
            case "VIP_SPECIAL_INVITEE" -> "VI";
            case "SPEAKER" -> "SP";
            case "ORGANIZER" -> "OR";
            default -> throw new IllegalArgumentException("Choose a valid registration category.");
        };
    }

    private static String normalize(String value) {
        return value == null ? "" : value.trim().toUpperCase(Locale.ROOT);
    }
}

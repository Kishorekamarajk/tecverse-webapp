package com.tecverse.app.controller;

import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;

import com.tecverse.app.dto.AdminSessionParticipantSummary;
import com.tecverse.app.dto.AdminSessionReservationRow;
import com.tecverse.app.repository.ThematicReservationRepository;

@Controller
public class AdminSessionReservationController {
    private final ThematicReservationRepository reservations;

    public AdminSessionReservationController(ThematicReservationRepository reservations) {
        this.reservations = reservations;
    }

    @GetMapping("/admin/session-reservations/fragment")
    public String fragment(@RequestParam String kind, @RequestParam(defaultValue = "0") int page, Model model) {
        int safePage = Math.max(0, page);
        model.addAttribute("kind", validKind(kind));
        if ("bookings".equals(kind)) {
            model.addAttribute("page", reservations.findConfirmedReservationRows(PageRequest.of(safePage, 10)));
        } else {
            Page<AdminSessionParticipantSummary> participants = reservations.findConfirmedAdminSessionParticipants(
                    PageRequest.of(safePage, 10));
            List<Long> ids = participants.getContent().stream().map(AdminSessionParticipantSummary::registrationId).toList();
            Map<Long, String> titles = new LinkedHashMap<>();
            if (!ids.isEmpty()) for (AdminSessionReservationRow row : reservations.findConfirmedReservationRowsForParticipants(ids))
                titles.merge(row.registrationId(), row.sessionTitle(), (existing, next) -> existing + ", " + next);
            model.addAttribute("participants", participants.getContent().stream().map(p -> new ParticipantRow(
                    p.attendeeName(), p.registrationReference(), titles.getOrDefault(p.registrationId(), ""))).toList());
            model.addAttribute("page", participants);
        }
        return "admin/fragments/session-reservation-rows :: rows";
    }

    @GetMapping("/admin/session-reservations/export")
    public ResponseEntity<byte[]> export(@RequestParam String kind) {
        String safeKind = validKind(kind);
        StringBuilder csv = new StringBuilder("\uFEFF");
        if ("bookings".equals(safeKind)) {
            csv.append("Participant,Registration reference,Session,Type,Reserved at,Status\r\n");
            reservations.findAllConfirmedReservationRows().forEach(row -> append(csv, row));
        } else {
            csv.append("Participant,Registration reference,Confirmed session count,Confirmed sessions\r\n");
            Map<Long, List<AdminSessionReservationRow>> byParticipant = new LinkedHashMap<>();
            reservations.findAllConfirmedReservationRows().forEach(row -> byParticipant
                    .computeIfAbsent(row.registrationId(), ignored -> new java.util.ArrayList<>()).add(row));
            byParticipant.values().forEach(rows -> {
                AdminSessionReservationRow first = rows.get(0);
                csv.append(csv(first.attendeeName())).append(',').append(csv(first.registrationReference())).append(',')
                        .append(rows.size()).append(',').append(csv(rows.stream().map(AdminSessionReservationRow::sessionTitle)
                                .collect(java.util.stream.Collectors.joining(", ")))).append("\r\n");
            });
        }
        return ResponseEntity.ok().header(HttpHeaders.CONTENT_DISPOSITION,
                "attachment; filename=\"session-" + safeKind + ".csv\"")
                .contentType(MediaType.parseMediaType("text/csv; charset=UTF-8"))
                .body(csv.toString().getBytes(StandardCharsets.UTF_8));
    }

    private static void append(StringBuilder csv, AdminSessionReservationRow row) {
        csv.append(csv(row.attendeeName())).append(',').append(csv(row.registrationReference())).append(',')
                .append(csv(row.sessionTitle())).append(',').append(csv(row.sessionType())).append(',')
                .append(csv(row.reservedAt() == null ? "" : row.reservedAt().toString())).append(',')
                .append(csv(row.status())).append("\r\n");
    }

    private static String validKind(String kind) {
        if (!"bookings".equals(kind) && !"participants".equals(kind))
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.NOT_FOUND);
        return kind;
    }

    private static String csv(String value) {
        String safe = value == null ? "" : value;
        if (safe.matches("^[\\s]*[=+@-].*")) safe = "'" + safe;
        return "\"" + safe.replace("\"", "\"\"") + "\"";
    }

    public record ParticipantRow(String name, String reference, String sessions) {}
}

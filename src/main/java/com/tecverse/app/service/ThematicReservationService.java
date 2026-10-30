package com.tecverse.app.service;

import com.tecverse.app.entity.ThematicReservation;
import com.tecverse.app.entity.ThematicSession;
import com.tecverse.app.repository.ThematicReservationRepository;
import com.tecverse.app.repository.ThematicSessionRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;

@Service
public class ThematicReservationService {
    private static final DateTimeFormatter STORAGE_TIME = DateTimeFormatter.ofPattern("HH:mm");
    private static final DateTimeFormatter DISPLAY_TIME = DateTimeFormatter.ofPattern("h:mm a", Locale.ENGLISH);
    private final ThematicSessionRepository sessions;
    private final ThematicReservationRepository reservations;

    public ThematicReservationService(ThematicSessionRepository sessions, ThematicReservationRepository reservations) {
        this.sessions = sessions;
        this.reservations = reservations;
    }

    public List<Map<String, Object>> publicSessions(Long userId) {
        return sessions.findByPublishedTrueAndActiveTrueOrderBySessionDateAscIdAsc().stream().map(session -> {
            boolean available = reservations.countBySessionIdAndStatus(session.getId(), "CONFIRMED")
                    < session.getTotalCapacity() - session.getReservedSeats();
            return Map.<String, Object>of(
                    "id", session.getId(), "title", session.getTitle(),
                    "description", Objects.toString(session.getDescription(), ""),
                    "date", displayDate(session.getSessionDate()), "time", displayTimeRange(session),
                    "availability", available ? "Available" : "Not Available",
                    "reserved", reservations.existsByRegistrationIdAndSessionIdAndStatus(userId, session.getId(), "CONFIRMED"));
        }).toList();
    }

    @Transactional
    public void reserve(Long userId, Long sessionId) {
        ThematicSession session = sessions.findByIdForUpdate(sessionId)
                .orElseThrow(() -> new IllegalArgumentException("Session not found."));
        if (!session.isPublished() || !session.isActive()) throw new IllegalArgumentException("This session is not open for reservations.");
        ThematicReservation reservation = reservations.findByRegistrationIdAndSessionId(userId, sessionId).orElse(null);
        if (reservation != null && "CONFIRMED".equals(reservation.getStatus())) throw new IllegalArgumentException("You have already reserved this session.");
        if (reservations.countBySessionIdAndStatus(sessionId, "CONFIRMED") >= session.getTotalCapacity() - session.getReservedSeats()) {
            throw new IllegalArgumentException("This session is fully booked. Refresh the list to see current availability.");
        }
        if (reservation == null) {
            reservation = new ThematicReservation();
            reservation.setRegistrationId(userId);
            reservation.setSessionId(sessionId);
        } else reservation.setStatus("CONFIRMED");
        reservations.save(reservation);
    }

    @Transactional
    public void cancel(Long userId, Long reservationId) {
        ThematicReservation reservation = reservations.findOwned(reservationId, userId)
                .orElseThrow(() -> new IllegalArgumentException("Reservation not found."));
        if (!"CONFIRMED".equals(reservation.getStatus())) throw new IllegalArgumentException("This reservation is already cancelled.");
        reservation.setStatus("CANCELLED");
    }

    public List<Map<String, Object>> myReservations(Long userId) {
        return reservations.findByRegistrationIdAndStatus(userId, "CONFIRMED").stream()
                .map(reservation -> sessions.findById(reservation.getSessionId()).map(session -> Map.<String, Object>of(
                        "id", reservation.getId(), "sessionTitle", session.getTitle(),
                        "date", displayDate(session.getSessionDate()), "time", displayTimeRange(session))).orElse(null))
                .filter(Objects::nonNull).toList();
    }

    public List<Map<String, Object>> adminSessions() {
        return sessions.findAllByOrderBySessionDateAscIdAsc().stream().map(session -> {
            long booked = reservations.countBySessionIdAndStatus(session.getId(), "CONFIRMED");
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("id", session.getId());
            item.put("title", session.getTitle());
            item.put("description", Objects.toString(session.getDescription(), ""));
            item.put("date", Objects.toString(session.getSessionDate(), ""));
            item.put("time", Objects.toString(session.getTimeLabel(), ""));
            item.put("toTime", Objects.toString(session.getEndTimeLabel(), ""));
            item.put("totalCapacity", session.getTotalCapacity());
            item.put("reservedSeats", session.getReservedSeats());
            item.put("generalCapacity", session.getTotalCapacity() - session.getReservedSeats());
            item.put("confirmed", booked);
            item.put("remaining", session.getTotalCapacity() - session.getReservedSeats() - booked);
            item.put("published", session.isPublished());
            item.put("active", session.isActive());
            return item;
        }).toList();
    }

    @Transactional
    public ThematicSession save(Long id, Map<String, Object> form) {
        ThematicSession session = id == null ? new ThematicSession() : sessions.findByIdForUpdate(id)
                .orElseThrow(() -> new IllegalArgumentException("Session not found."));
        String title = Objects.toString(form.get("title"), "").trim();
        String description = Objects.toString(form.get("description"), "");
        String date = Objects.toString(form.get("date"), "");
        String fromTime = Objects.toString(form.get("time"), "");
        String toTime = Objects.toString(form.get("toTime"), "");
        int capacity = number(form.get("totalCapacity"), 300);
        int reserved = number(form.get("reservedSeats"), 10);
        if (title.isBlank() || title.length() > 180 || description.length() > 3000 || capacity < 1 || reserved < 0 || reserved >= capacity) {
            throw new IllegalArgumentException("Enter a title, valid session details and capacity values; reserved seats must be less than total capacity.");
        }
        try {
            if (!date.isBlank()) date = LocalDate.parse(date).toString();
            if (!fromTime.isBlank()) fromTime = LocalTime.parse(fromTime).format(STORAGE_TIME);
            if (!toTime.isBlank()) toTime = LocalTime.parse(toTime).format(STORAGE_TIME);
            if (!fromTime.isBlank() && !toTime.isBlank() && !LocalTime.parse(toTime).isAfter(LocalTime.parse(fromTime))) {
                throw new IllegalArgumentException("End time must be later than start time.");
            }
        } catch (java.time.format.DateTimeParseException invalid) {
            throw new IllegalArgumentException("Enter the date as YYYY-MM-DD and times as HH:MM.");
        }
        long confirmed = session.getId() == null ? 0 : reservations.countBySessionIdAndStatus(session.getId(), "CONFIRMED");
        if (capacity - reserved < confirmed) throw new IllegalArgumentException("General capacity cannot be reduced below confirmed reservations.");
        session.setTitle(title);
        session.setDescription(description);
        session.setSessionDate(date);
        session.setTimeLabel(fromTime);
        session.setEndTimeLabel(toTime);
        session.setTotalCapacity(capacity);
        session.setReservedSeats(reserved);
        session.setPublished(Boolean.parseBoolean(Objects.toString(form.get("published"), "false")));
        session.setActive(Boolean.parseBoolean(Objects.toString(form.get("active"), "true")));
        return sessions.save(session);
    }

    @Transactional
    public void delete(Long id) {
        if (reservations.countBySessionId(id) > 0) throw new IllegalArgumentException("Sessions with reservation history cannot be deleted. Set the session inactive to archive it.");
        sessions.deleteById(id);
    }

    private static int number(Object value, int fallback) {
        try { return Integer.parseInt(Objects.toString(value, "")); }
        catch (NumberFormatException ignored) { return fallback; }
    }

    private static String displayDate(String value) {
        try { return value == null || value.isBlank() ? "" : LocalDate.parse(value).format(DateTimeFormatter.ofPattern("d MMM uuuu", Locale.ENGLISH)); }
        catch (java.time.format.DateTimeParseException ignored) { return Objects.toString(value, ""); }
    }

    private static String displayTimeRange(ThematicSession session) {
        String start = displayTime(session.getTimeLabel());
        String end = displayTime(session.getEndTimeLabel());
        if (start.isBlank()) return end;
        return end.isBlank() ? start : start + " - " + end;
    }

    private static String displayTime(String value) {
        try { return value == null || value.isBlank() ? "" : LocalTime.parse(value).format(DISPLAY_TIME); }
        catch (java.time.format.DateTimeParseException ignored) { return Objects.toString(value, ""); }
    }
}

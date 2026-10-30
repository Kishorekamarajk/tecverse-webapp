package com.tecverse.app.service;

import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class BusinessConversationService {
    private final JdbcTemplate jdbc;

    public BusinessConversationService(JdbcTemplate jdbc) { this.jdbc = jdbc; }

    @Transactional
    public void add(String role, String phone, String name, String company, String sender, String body) {
        jdbc.update("INSERT INTO business_portal_messages (business_role, business_phone, contact_name, organization, sender, message_body) VALUES (?, ?, ?, ?, ?, ?)",
                role, phone, name, company, sender, body.trim());
    }

    public List<Message> messages(String role, String phone) {
        return jdbc.query("SELECT id, sender, message_body, created_at FROM business_portal_messages WHERE business_role = ? AND business_phone = ? ORDER BY created_at, id",
                (rs, row) -> new Message(rs.getLong("id"), rs.getString("sender"), rs.getString("message_body"),
                        rs.getTimestamp("created_at").toLocalDateTime()), role, phone);
    }

    public List<Conversation> conversations() {
        List<Row> rows = jdbc.query("SELECT business_role, business_phone, contact_name, organization, sender, message_body, created_at FROM business_portal_messages ORDER BY created_at, id",
                (rs, row) -> new Row(rs.getString("business_role"), rs.getString("business_phone"),
                        rs.getString("contact_name"), rs.getString("organization"), rs.getString("sender"),
                        rs.getString("message_body"), rs.getTimestamp("created_at").toLocalDateTime()));
        Map<String, ConversationBuilder> grouped = new LinkedHashMap<>();
        for (Row row : rows) {
            String key = row.role + ":" + row.phone;
            ConversationBuilder thread = grouped.computeIfAbsent(key, ignored ->
                    new ConversationBuilder(row.role, row.phone, row.name, row.company));
            thread.messages.add(new Message(0, row.sender, row.body, row.createdAt));
        }
        return grouped.values().stream().map(ConversationBuilder::build)
                .sorted(Comparator.comparing((Conversation thread) ->
                        thread.messages().get(thread.messages().size() - 1).createdAt()).reversed())
                .toList();
    }

    public record Message(long id, String sender, String body, LocalDateTime createdAt) { }
    public record Conversation(String role, String phone, String name, String company, List<Message> messages) { }
    private record Row(String role, String phone, String name, String company, String sender, String body, LocalDateTime createdAt) { }
    private static final class ConversationBuilder {
        final String role, phone, name, company;
        final List<Message> messages = new ArrayList<>();
        ConversationBuilder(String role, String phone, String name, String company) {
            this.role = role; this.phone = phone; this.name = name; this.company = company;
        }
        Conversation build() { return new Conversation(role, phone, name, company, List.copyOf(messages)); }
    }
}

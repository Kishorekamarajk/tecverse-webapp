package com.tecverse.app.dto;

import java.util.List;

public record AdminDashboardAnalytics(
        List<String> months,
        List<Long> ticketsByMonth,
        List<Long> exhibitorsByMonth,
        List<Long> sponsorsByMonth,
        List<Long> contactsByMonth,
        List<String> ticketCategories,
        List<Long> ticketsByCategory,
        List<String> ticketStates,
        List<Long> ticketsByState) {
}

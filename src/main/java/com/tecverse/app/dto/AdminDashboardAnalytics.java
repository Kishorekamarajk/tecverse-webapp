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
        List<Long> ticketsByState,
        List<String> topSessionTitles,
        List<Long> topSessionReservationCounts,
        long totalConfirmedBookings,
        long participantsWithBookings,
        long sessionsWithBookings,
        String mostBookedSessionTitle,
        long mostBookedSessionCount,
        String leastBookedSessionTitle,
        long leastBookedSessionCount) {

    public long getAcademiaCount() {
        return categoryCount("ACADEMIA");
    }

    public long getCentralGovernmentCount() {
        return categoryCount("CENTRAL_GOVERNMENT");
    }

    public long getStateGovernmentCount() {
        return categoryCount("STATE_GOVERNMENT");
    }

    public long getIndustryStartupCount() {
        return categoryCount("INDUSTRY_STARTUP");
    }

    private long categoryCount(String category) {
        for (int index = 0; index < ticketCategories.size(); index++) {
            if (ticketCategories.get(index) != null && ticketCategories.get(index).trim().equalsIgnoreCase(category)) {
                Long count = ticketsByCategory.get(index);
                return count == null ? 0L : count;
            }
        }
        return 0L;
    }
}

package com.tecverse.app.service;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.YearMonth;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;

import com.tecverse.app.dto.AdminChartPoint;
import com.tecverse.app.dto.AdminDashboardAnalytics;
import com.tecverse.app.dto.AdminSubmissionCounts;
import com.tecverse.app.repository.ContactUsRepository;
import com.tecverse.app.repository.ExhibitorRepository;
import com.tecverse.app.repository.SponsorEnquiryRepository;
import com.tecverse.app.repository.TicketRegistrationRepository;

@Service
public class AdminDashboardService {

    private final TicketRegistrationRepository ticketRegistrationRepository;
    private final ExhibitorRepository exhibitorRepository;
    private final SponsorEnquiryRepository sponsorEnquiryRepository;
    private final ContactUsRepository contactUsRepository;

    public AdminDashboardService(TicketRegistrationRepository ticketRegistrationRepository,
                                 ExhibitorRepository exhibitorRepository,
                                 SponsorEnquiryRepository sponsorEnquiryRepository,
                                 ContactUsRepository contactUsRepository) {
        this.ticketRegistrationRepository = ticketRegistrationRepository;
        this.exhibitorRepository = exhibitorRepository;
        this.sponsorEnquiryRepository = sponsorEnquiryRepository;
        this.contactUsRepository = contactUsRepository;
    }

    @Transactional(readOnly = true)
    public AdminSubmissionCounts getSubmissionCounts() {
        return new AdminSubmissionCounts(
                ticketRegistrationRepository.count(),
                exhibitorRepository.count(),
                sponsorEnquiryRepository.count(),
                contactUsRepository.count()
        );
    }

    @Transactional(readOnly = true)
    public AdminDashboardAnalytics getAnalytics() {
        YearMonth firstMonth = YearMonth.from(LocalDate.now()).minusMonths(5);
        LocalDateTime start = firstMonth.atDay(1).atStartOfDay();
        List<YearMonth> months = new ArrayList<>();
        for (int i = 0; i < 6; i++) months.add(firstMonth.plusMonths(i));

        Map<String, Long> ticketCounts = monthly(ticketRegistrationRepository.countMonthlySince(start));
        Map<String, Long> exhibitorCounts = monthly(exhibitorRepository.countMonthlySince(start));
        Map<String, Long> sponsorCounts = monthly(sponsorEnquiryRepository.countMonthlySince(start));
        Map<String, Long> contactCounts = monthly(contactUsRepository.countMonthlySince(start));

        List<String> monthLabels = months.stream().map(m -> m.format(DateTimeFormatter.ofPattern("MMM yy"))).toList();
        List<String> keys = months.stream().map(YearMonth::toString).toList();
        List<AdminChartPoint> ticketCategories = ticketRegistrationRepository.countByCategoryForDashboard();
        List<AdminChartPoint> ticketStates = ticketRegistrationRepository.countByApplicantStateForDashboard();
        return new AdminDashboardAnalytics(monthLabels, values(keys, ticketCounts), values(keys, exhibitorCounts),
                values(keys, sponsorCounts), values(keys, contactCounts),
                ticketCategories.stream().map(AdminChartPoint::getLabel).toList(),
                ticketCategories.stream().map(p -> p.getTotalCount() == null ? 0L : p.getTotalCount()).toList(),
                ticketStates.stream().map(AdminChartPoint::getLabel).toList(),
                ticketStates.stream().map(p -> p.getTotalCount() == null ? 0L : p.getTotalCount()).toList());
    }

    private static Map<String, Long> monthly(List<AdminChartPoint> points) {
        Map<String, Long> result = new TreeMap<>();
        for (AdminChartPoint point : points) result.put(point.getLabel(), point.getTotalCount() == null ? 0L : point.getTotalCount());
        return result;
    }

    private static List<Long> values(List<String> keys, Map<String, Long> counts) {
        return keys.stream().map(key -> counts.getOrDefault(key, 0L)).toList();
    }
}

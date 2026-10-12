package com.tecverse.app.service;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

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
}

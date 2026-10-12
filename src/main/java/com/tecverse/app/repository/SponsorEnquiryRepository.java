package com.tecverse.app.repository;

import com.tecverse.app.entity.SponsorEnquiry;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SponsorEnquiryRepository extends JpaRepository<SponsorEnquiry, Long> {

    long countBy();

    boolean existsByEmail(String email);

    boolean existsByPhone(String phone);
}

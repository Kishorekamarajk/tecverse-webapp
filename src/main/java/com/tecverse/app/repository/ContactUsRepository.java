package com.tecverse.app.repository;

import com.tecverse.app.entity.ContactUs;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface ContactUsRepository extends JpaRepository<ContactUs, Long> {

    long countBy();

    Optional<ContactUs> findByEmail(String email);

    Optional<ContactUs> findByPhoneNumber(String phoneNumber);

    boolean existsByEmailIgnoreCase(String email);

    boolean existsByPhoneNumber(String phoneNumber);
}

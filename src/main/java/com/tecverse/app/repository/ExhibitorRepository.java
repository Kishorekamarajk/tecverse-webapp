package com.tecverse.app.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.tecverse.app.entity.Exhibitor;

public interface ExhibitorRepository extends JpaRepository<Exhibitor, Long> {
    long countBy();
    boolean existsByEmail(String email);
    boolean existsByPhone(String phone);
    boolean existsByReferenceNumber(String referenceNumber);
}

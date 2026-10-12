package com.tecverse.app.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.tecverse.app.entity.ThematicDomainCard;

public interface ThematicDomainCardRepository extends JpaRepository<ThematicDomainCard, Long> {

    List<ThematicDomainCard> findByActiveTrueOrderByInstitutionAscDisplayOrderAscIdAsc();

    List<ThematicDomainCard> findAllByOrderByInstitutionAscDisplayOrderAscIdAsc();
}

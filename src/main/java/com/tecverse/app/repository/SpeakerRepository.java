package com.tecverse.app.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.tecverse.app.entity.Speaker;

public interface SpeakerRepository extends JpaRepository<Speaker, Long> {

    boolean existsByNameIgnoreCase(String name);

    List<Speaker> findByActiveTrueOrderByDisplayOrderAscIdAsc();

    List<Speaker> findAllByOrderByDisplayOrderAscIdAsc();
}

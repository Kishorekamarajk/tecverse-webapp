package com.tecverse.app.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.tecverse.app.entity.ChiefGuest;

public interface ChiefGuestRepository extends JpaRepository<ChiefGuest, Long> {

    List<ChiefGuest> findAllByOrderByDisplayOrderAscIdAsc();

    List<ChiefGuest> findByActiveTrueOrderByDisplayOrderAscIdAsc();
}

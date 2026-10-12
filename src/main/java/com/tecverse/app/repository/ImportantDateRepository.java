package com.tecverse.app.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.tecverse.app.entity.ImportantDate;

public interface ImportantDateRepository extends JpaRepository<ImportantDate, Long> {

    List<ImportantDate> findByActiveTrueOrderByDisplayOrderAscIdAsc();

    List<ImportantDate> findAllByOrderByDisplayOrderAscIdAsc();
}

package com.tecverse.app.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.tecverse.app.entity.FaqItem;

public interface FaqItemRepository extends JpaRepository<FaqItem, Long> {

    List<FaqItem> findAllByOrderByPageKeyAscDisplayOrderAscIdAsc();

    List<FaqItem> findByPageKeyOrderByDisplayOrderAscIdAsc(String pageKey);

    List<FaqItem> findByPageKeyAndActiveTrueOrderByDisplayOrderAscIdAsc(String pageKey);
}

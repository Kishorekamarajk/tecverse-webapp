package com.tecverse.app.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.tecverse.app.entity.NewsUpdate;

public interface NewsUpdateRepository extends JpaRepository<NewsUpdate, Long> {

    List<NewsUpdate> findByActiveTrueOrderByPublishedDateDescIdDesc();

    List<NewsUpdate> findAllByOrderByPublishedDateDescIdDesc();

    Optional<NewsUpdate> findBySlug(String slug);

    Optional<NewsUpdate> findBySlugAndActiveTrue(String slug);

    boolean existsBySlug(String slug);
}

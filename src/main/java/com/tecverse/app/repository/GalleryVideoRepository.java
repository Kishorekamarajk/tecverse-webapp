package com.tecverse.app.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.tecverse.app.entity.GalleryVideo;

public interface GalleryVideoRepository extends JpaRepository<GalleryVideo, Long> {

    boolean existsByTitleIgnoreCase(String title);

    List<GalleryVideo> findByActiveTrueOrderByDisplayOrderAscIdAsc();

    List<GalleryVideo> findAllByOrderByDisplayOrderAscIdAsc();
}

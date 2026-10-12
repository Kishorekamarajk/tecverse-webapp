package com.tecverse.app.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.tecverse.app.entity.GalleryImage;

public interface GalleryImageRepository extends JpaRepository<GalleryImage, Long> {

    boolean existsByTitleIgnoreCase(String title);

    List<GalleryImage> findByActiveTrueOrderByDisplayOrderAscIdAsc();

    List<GalleryImage> findAllByOrderByDisplayOrderAscIdAsc();
}

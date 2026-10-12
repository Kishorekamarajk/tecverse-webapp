package com.tecverse.app.repository;

import com.tecverse.app.entity.ExhibitorLogo;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ExhibitorLogoRepository extends JpaRepository<ExhibitorLogo, Long> {
    List<ExhibitorLogo> findAllByOrderByDisplayOrderAscIdAsc();
    List<ExhibitorLogo> findByActiveTrueOrderByDisplayOrderAscIdAsc();
    long countByActiveTrue();
}

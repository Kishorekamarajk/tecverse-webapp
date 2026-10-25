package com.tecverse.app.repository;

import com.tecverse.app.entity.ContactUs;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.List;
import java.time.LocalDateTime;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import com.tecverse.app.dto.AdminChartPoint;

public interface ContactUsRepository extends JpaRepository<ContactUs, Long> {

    long countBy();

    Optional<ContactUs> findByEmail(String email);

    Optional<ContactUs> findByPhoneNumber(String phoneNumber);

    boolean existsByEmailIgnoreCase(String email);

    boolean existsByPhoneNumber(String phoneNumber);
    @Query(value = "SELECT TO_CHAR(created_at, 'YYYY-MM') AS label, COUNT(*) AS \"totalCount\" FROM contact_us WHERE created_at >= :start GROUP BY 1 ORDER BY 1", nativeQuery = true)
    List<AdminChartPoint> countMonthlySince(@Param("start") LocalDateTime start);
}

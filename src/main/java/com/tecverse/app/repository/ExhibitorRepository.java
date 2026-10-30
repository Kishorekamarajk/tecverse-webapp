package com.tecverse.app.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import com.tecverse.app.dto.AdminChartPoint;

import com.tecverse.app.entity.Exhibitor;

public interface ExhibitorRepository extends JpaRepository<Exhibitor, Long> {
    long countBy();
    boolean existsByEmailIgnoreCase(String email);
    @Query(value = "SELECT EXISTS (SELECT 1 FROM exhibitor WHERE regexp_replace(phone, '[^0-9]', '', 'g') IN (:phone, '91' || :phone))", nativeQuery = true)
    boolean existsByPhoneNormalized(@Param("phone") String normalizedPhone);
    @Query(value = "SELECT * FROM exhibitor WHERE regexp_replace(phone, '[^0-9]', '', 'g') IN (:phone, '91' || :phone) ORDER BY created_at DESC LIMIT 1", nativeQuery = true)
    Optional<Exhibitor> findLatestByPhoneNormalized(@Param("phone") String normalizedPhone);
    boolean existsByReferenceNumber(String referenceNumber);
    @Query(value = "SELECT TO_CHAR(created_at, 'YYYY-MM') AS label, COUNT(*) AS \"totalCount\" FROM exhibitor WHERE created_at >= :start GROUP BY 1 ORDER BY 1", nativeQuery = true)
    List<AdminChartPoint> countMonthlySince(@Param("start") LocalDateTime start);
}

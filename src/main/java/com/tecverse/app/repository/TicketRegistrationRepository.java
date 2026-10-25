package com.tecverse.app.repository;
import com.tecverse.app.entity.TicketRegistration;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.time.LocalDateTime;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.data.jpa.repository.Lock;
import jakarta.persistence.LockModeType;
import com.tecverse.app.dto.AdminChartPoint;
public interface TicketRegistrationRepository extends JpaRepository<TicketRegistration,Long>{
 long countBy();
 boolean existsByEmail(String email);
 boolean existsByPhone(String phone);
 boolean existsByEmailOrPhone(String email, String phone);
 boolean existsByReferenceNumber(String referenceNumber);
 java.util.Optional<TicketRegistration> findByReferenceNumber(String referenceNumber);
 java.util.Optional<TicketRegistration> findByScanToken(String scanToken);
 java.util.Optional<TicketRegistration> findByEmailIgnoreCase(String email);
 java.util.Optional<TicketRegistration> findByPhone(String phone);
 @Lock(LockModeType.PESSIMISTIC_WRITE)
 @Query("SELECT t FROM TicketRegistration t WHERE t.id = :id")
 java.util.Optional<TicketRegistration> findByIdForUpdate(@Param("id") Long id);
 List<TicketRegistration> findTop25ByConfirmationEmailSentFalseAndConfirmationEmailAttemptsLessThanOrderByCreatedAtAsc(int maxAttempts);
 @Query(value = "SELECT TO_CHAR(created_at, 'YYYY-MM') AS label, COUNT(*) AS \"totalCount\" FROM tecverse_ticket_registrations WHERE created_at >= :start GROUP BY 1 ORDER BY 1", nativeQuery = true)
 List<AdminChartPoint> countMonthlySince(@Param("start") LocalDateTime start);
 @Query(value = "SELECT category AS label, COUNT(*) AS \"totalCount\" FROM tecverse_ticket_registrations GROUP BY category ORDER BY COUNT(*) DESC", nativeQuery = true)
 List<AdminChartPoint> countByCategoryForDashboard();
 @Query(value = "SELECT COALESCE(NULLIF(BTRIM(applicant_state), ''), 'Not provided') AS label, COUNT(*) AS \"totalCount\" FROM tecverse_ticket_registrations GROUP BY COALESCE(NULLIF(BTRIM(applicant_state), ''), 'Not provided') ORDER BY COUNT(*) DESC, label", nativeQuery = true)
 List<AdminChartPoint> countByApplicantStateForDashboard();
}

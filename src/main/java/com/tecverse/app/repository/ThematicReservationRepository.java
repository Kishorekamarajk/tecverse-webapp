package com.tecverse.app.repository;
import com.tecverse.app.entity.ThematicReservation;
import com.tecverse.app.dto.AdminChartPoint;
import com.tecverse.app.dto.AdminSessionParticipantSummary;
import com.tecverse.app.dto.AdminSessionReservationRow;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.repository.query.Param;
import java.util.List;
public interface ThematicReservationRepository extends JpaRepository<ThematicReservation,Long> {
 long countBySessionIdAndStatus(Long sessionId,String status);
 long countBySessionId(Long sessionId);
 boolean existsByRegistrationIdAndSessionIdAndStatus(Long registrationId,Long sessionId,String status);
 java.util.Optional<ThematicReservation> findByRegistrationIdAndSessionId(Long registrationId,Long sessionId);
 List<ThematicReservation> findByRegistrationIdAndStatus(Long registrationId,String status);
 @Query("select r from ThematicReservation r where r.id=:id and r.registrationId=:userId") java.util.Optional<ThematicReservation> findOwned(@Param("id") Long id,@Param("userId") Long userId);
 @Query(value="select new com.tecverse.app.dto.AdminSessionParticipantSummary(t.id, t.officialName, t.referenceNumber) from ThematicReservation r, TicketRegistration t where t.id = r.registrationId group by t.id, t.officialName, t.referenceNumber order by max(r.updatedAt) desc, t.id asc",
        countQuery="select count(distinct r.registrationId) from ThematicReservation r, TicketRegistration t where t.id = r.registrationId")
 Page<AdminSessionParticipantSummary> findAdminSessionParticipants(Pageable pageable);
 @Query(value="select new com.tecverse.app.dto.AdminSessionParticipantSummary(t.id, t.officialName, t.referenceNumber) from ThematicReservation r, TicketRegistration t where t.id = r.registrationId and r.status = 'CONFIRMED' group by t.id, t.officialName, t.referenceNumber order by max(r.updatedAt) desc, t.id asc",
        countQuery="select count(distinct r.registrationId) from ThematicReservation r, TicketRegistration t where t.id = r.registrationId and r.status = 'CONFIRMED'")
 Page<AdminSessionParticipantSummary> findConfirmedAdminSessionParticipants(Pageable pageable);
 @Query("select new com.tecverse.app.dto.AdminSessionReservationRow(r.registrationId, r.id, t.officialName, t.referenceNumber, s.title, s.sessionType, r.createdAt, r.updatedAt, r.status) from ThematicReservation r, TicketRegistration t, ThematicSession s where t.id = r.registrationId and s.id = r.sessionId and r.registrationId in :registrationIds order by r.registrationId asc, r.updatedAt desc")
 List<AdminSessionReservationRow> findReservationRowsForParticipants(@Param("registrationIds") List<Long> registrationIds);
 @Query("select new com.tecverse.app.dto.AdminSessionReservationRow(r.registrationId, r.id, t.officialName, t.referenceNumber, s.title, s.sessionType, r.createdAt, r.updatedAt, r.status) from ThematicReservation r, TicketRegistration t, ThematicSession s where t.id = r.registrationId and s.id = r.sessionId and r.status = 'CONFIRMED' order by r.createdAt desc, r.id desc")
 Page<AdminSessionReservationRow> findConfirmedReservationRows(Pageable pageable);
 @Query("select new com.tecverse.app.dto.AdminSessionReservationRow(r.registrationId, r.id, t.officialName, t.referenceNumber, s.title, s.sessionType, r.createdAt, r.updatedAt, r.status) from ThematicReservation r, TicketRegistration t, ThematicSession s where t.id = r.registrationId and s.id = r.sessionId and r.status = 'CONFIRMED' order by r.createdAt desc, r.id desc")
 List<AdminSessionReservationRow> findAllConfirmedReservationRows();
 @Query("select new com.tecverse.app.dto.AdminSessionReservationRow(r.registrationId, r.id, t.officialName, t.referenceNumber, s.title, s.sessionType, r.createdAt, r.updatedAt, r.status) from ThematicReservation r, TicketRegistration t, ThematicSession s where t.id = r.registrationId and s.id = r.sessionId and r.registrationId in :registrationIds and r.status = 'CONFIRMED' order by r.registrationId asc, r.updatedAt desc")
 List<AdminSessionReservationRow> findConfirmedReservationRowsForParticipants(@Param("registrationIds") List<Long> registrationIds);
 @Query(value="SELECT s.title AS label, COUNT(r.id) AS \"totalCount\" FROM thematic_reservations r JOIN thematic_sessions s ON s.id = r.session_id WHERE r.status = 'CONFIRMED' GROUP BY s.id, s.title ORDER BY COUNT(r.id) DESC, s.title ASC LIMIT 10", nativeQuery=true)
 List<AdminChartPoint> findTopConfirmedSessionsForDashboard();
 @Query(value="SELECT s.title AS label, COUNT(r.id) AS \"totalCount\" FROM thematic_reservations r JOIN thematic_sessions s ON s.id = r.session_id WHERE r.status = 'CONFIRMED' GROUP BY s.id, s.title ORDER BY COUNT(r.id) ASC, s.title ASC LIMIT 1", nativeQuery=true)
 List<AdminChartPoint> findLeastBookedConfirmedSessionForDashboard();
 @Query(value="SELECT COUNT(*) FROM thematic_reservations WHERE status = 'CONFIRMED'", nativeQuery=true)
 long countConfirmedReservationsForDashboard();
 @Query(value="SELECT COUNT(DISTINCT registration_id) FROM thematic_reservations WHERE status = 'CONFIRMED'", nativeQuery=true)
 long countParticipantsWithConfirmedReservationsForDashboard();
 @Query(value="SELECT COUNT(DISTINCT session_id) FROM thematic_reservations WHERE status = 'CONFIRMED'", nativeQuery=true)
 long countSessionsWithConfirmedReservationsForDashboard();
}

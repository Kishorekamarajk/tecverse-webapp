package com.tecverse.app.repository;
import com.tecverse.app.entity.ThematicReservation;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import java.util.List;
public interface ThematicReservationRepository extends JpaRepository<ThematicReservation,Long> {
 long countBySessionIdAndStatus(Long sessionId,String status);
 long countBySessionId(Long sessionId);
 boolean existsByRegistrationIdAndSessionIdAndStatus(Long registrationId,Long sessionId,String status);
 java.util.Optional<ThematicReservation> findByRegistrationIdAndSessionId(Long registrationId,Long sessionId);
 List<ThematicReservation> findByRegistrationIdAndStatus(Long registrationId,String status);
 @Query("select r from ThematicReservation r where r.id=:id and r.registrationId=:userId") java.util.Optional<ThematicReservation> findOwned(@Param("id") Long id,@Param("userId") Long userId);
}

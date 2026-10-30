package com.tecverse.app.repository;
import com.tecverse.app.entity.ThematicSession;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import java.util.List;
import java.util.Optional;
public interface ThematicSessionRepository extends JpaRepository<ThematicSession,Long> {
 List<ThematicSession> findByPublishedTrueAndActiveTrueOrderBySessionDateAscIdAsc();
 List<ThematicSession> findAllByOrderBySessionDateAscIdAsc();
 @Lock(LockModeType.PESSIMISTIC_WRITE) @Query("select s from ThematicSession s where s.id=:id") Optional<ThematicSession> findByIdForUpdate(@Param("id") Long id);
}

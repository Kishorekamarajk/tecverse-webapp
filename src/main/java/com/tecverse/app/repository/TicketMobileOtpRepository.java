package com.tecverse.app.repository;

import java.time.Instant;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import com.tecverse.app.entity.TicketMobileOtp;
import jakarta.persistence.LockModeType;

public interface TicketMobileOtpRepository extends JpaRepository<TicketMobileOtp, String> {
    /** Row lock so two concurrent verify requests cannot both use the same OTP. */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select o from TicketMobileOtp o where o.mobile = :mobile")
    Optional<TicketMobileOtp> findByMobileForUpdate(@Param("mobile") String mobile);

    @Modifying
    @Query("delete from TicketMobileOtp o where o.expiresAt < :now")
    int deleteExpired(@Param("now") Instant now);
}

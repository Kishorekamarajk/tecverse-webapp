package com.tecverse.app.repository;
import com.tecverse.app.entity.TicketRegistration;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
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
 List<TicketRegistration> findTop25ByConfirmationEmailSentFalseAndConfirmationEmailAttemptsLessThanOrderByCreatedAtAsc(int maxAttempts);
}

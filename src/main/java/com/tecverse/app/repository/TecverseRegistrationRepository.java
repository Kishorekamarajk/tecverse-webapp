package com.tecverse.app.repository;
import com.tecverse.app.entity.TecverseRegistration;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import org.springframework.data.repository.query.Param;
import org.springframework.data.jpa.repository.Query;
public interface TecverseRegistrationRepository extends JpaRepository<TecverseRegistration,Long>{
 boolean existsByEmailIgnoreCase(String email);
 @Query(value = "SELECT EXISTS (SELECT 1 FROM tecverse_registrations WHERE regexp_replace(phone, '[^0-9]', '', 'g') IN (:phone, '91' || :phone))", nativeQuery = true)
 boolean existsByPhoneNormalized(@Param("phone") String normalizedPhone);
 boolean existsByReferenceNumber(String referenceNumber);
 java.util.Optional<TecverseRegistration> findByReferenceNumber(String referenceNumber);
 List<TecverseRegistration> findByEmailVerifiedTrueAndCompanyLogoUrlIsNotNullAndCompanyLogoUrlNotOrderByCreatedAtDesc(String emptyLogoUrl);
}

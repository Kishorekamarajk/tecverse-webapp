package com.tecverse.app.repository;
import com.tecverse.app.entity.TecverseRegistration;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
public interface TecverseRegistrationRepository extends JpaRepository<TecverseRegistration,Long>{
 boolean existsByEmail(String email);
 boolean existsByPhone(String phone);
 boolean existsByReferenceNumber(String referenceNumber);
 List<TecverseRegistration> findByEmailVerifiedTrueAndCompanyLogoUrlIsNotNullAndCompanyLogoUrlNotOrderByCreatedAtDesc(String emptyLogoUrl);
}

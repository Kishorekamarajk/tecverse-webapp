package com.tecverse.app.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.tecverse.app.entity.MediaCoverage;
import com.tecverse.app.entity.SocialPlatform;

public interface MediaCoverageRepository extends JpaRepository<MediaCoverage, Long> {

    Optional<MediaCoverage> findByPlatformAndPostId(SocialPlatform platform, String postId);

    Optional<MediaCoverage> findByPostUrl(String postUrl);

    List<MediaCoverage> findTop20ByActiveTrueAndPlatformInOrderByPublishedDateDesc(List<SocialPlatform> platforms);

}

package com.tecverse.app.config;

import java.util.Set;
import java.util.stream.Collectors;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

/**
 * Keeps the Hibernate-created media_coverage enum check aligned with the current
 * official social platforms. This project uses ddl-auto plus manual SQL scripts,
 * so the forward fix lives here and in src/main/resources/db.
 */
@Component
public class MediaCoverageSchemaMigration implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(MediaCoverageSchemaMigration.class);
    private static final String CONSTRAINT_NAME = "media_coverage_platform_check";
    private static final Set<String> REQUIRED_PLATFORMS = Set.of("YOUTUBE", "FACEBOOK", "INSTAGRAM");
    private static final String REQUIRED_CHECK_SQL =
            "platform::text = ANY (ARRAY['YOUTUBE'::character varying, 'FACEBOOK'::character varying, 'INSTAGRAM'::character varying]::text[])";

    private final JdbcTemplate jdbcTemplate;

    public MediaCoverageSchemaMigration(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override
    public void run(ApplicationArguments args) {
        try {
            if (!tableExists()) {
                log.debug("media_coverage table does not exist yet; skipping platform constraint migration.");
                return;
            }

            String currentDefinition = currentConstraintDefinition();
            if (constraintAlreadyAllowsRequiredPlatforms(currentDefinition)) {
                log.info("{} already supports {}", CONSTRAINT_NAME, REQUIRED_PLATFORMS);
                return;
            }

            if (currentDefinition == null) {
                log.info("{} is missing; creating it with {}", CONSTRAINT_NAME, REQUIRED_PLATFORMS);
            } else {
                log.info("Updating {} from [{}] to allow {}", CONSTRAINT_NAME, currentDefinition, REQUIRED_PLATFORMS);
            }

            jdbcTemplate.execute("ALTER TABLE media_coverage DROP CONSTRAINT IF EXISTS " + CONSTRAINT_NAME);
            jdbcTemplate.execute("ALTER TABLE media_coverage ADD CONSTRAINT " + CONSTRAINT_NAME
                    + " CHECK (" + REQUIRED_CHECK_SQL + ")");
            jdbcTemplate.execute("""
                    CREATE UNIQUE INDEX IF NOT EXISTS uk_media_coverage_platform_post_id
                    ON media_coverage(platform, post_id)
                    WHERE post_id IS NOT NULL
                    """);
            jdbcTemplate.execute("""
                    CREATE INDEX IF NOT EXISTS idx_media_coverage_active_published_date
                    ON media_coverage(active, published_date DESC)
                    """);

            log.info("{} after migration: {}", CONSTRAINT_NAME, currentConstraintDefinition());
        } catch (Exception ex) {
            log.error("Could not migrate {}. Social refresh will remain failure-safe, but inserts may be rejected: {}",
                    CONSTRAINT_NAME, ex.getMessage(), ex);
        }
    }

    private boolean tableExists() {
        Boolean exists = jdbcTemplate.queryForObject(
                "SELECT to_regclass('public.media_coverage') IS NOT NULL",
                Boolean.class);
        return Boolean.TRUE.equals(exists);
    }

    private String currentConstraintDefinition() {
        return jdbcTemplate.query("""
                        SELECT pg_get_constraintdef(c.oid)
                        FROM pg_constraint c
                        JOIN pg_class t ON t.oid = c.conrelid
                        JOIN pg_namespace n ON n.oid = t.relnamespace
                        WHERE n.nspname = 'public'
                          AND t.relname = 'media_coverage'
                          AND c.conname = ?
                        """,
                rs -> rs.next() ? rs.getString(1) : null,
                CONSTRAINT_NAME);
    }

    private boolean constraintAlreadyAllowsRequiredPlatforms(String definition) {
        if (definition == null) {
            return false;
        }
        Set<String> allowedValues = REQUIRED_PLATFORMS.stream()
                .filter(definition::contains)
                .collect(Collectors.toSet());
        return allowedValues.containsAll(REQUIRED_PLATFORMS) && !definition.contains("TWITTER");
    }
}

-- Apply before deploying the application version that maps applicant_state.
ALTER TABLE tecverse_ticket_registrations
    ADD COLUMN IF NOT EXISTS applicant_state VARCHAR(100);

# TEC-VERSE mobile app

This Flutter app is kept alongside the Spring Boot website/backend so both clients can be maintained in one project. The backend's PostgreSQL connection is configured by `DB_URL`, `DB_USERNAME`, and `DB_PASSWORD` in the Spring Boot environment; the Flutter app must call backend APIs and must never connect directly to PostgreSQL.

## Staging API

The app defaults to the website's staging origin, `https://ngypr123.bosschn.in/tecverse`, and appends `/api`. Override the origin for a different staging domain with:

```sh
flutter run --dart-define=STAGING_BASE_URL=https://your-staging-host/tecverse
```

Or supply `--dart-define=API_BASE_URL=https://your-staging-host/tecverse/api` to override the full API base URL.

The Spring Boot deployment must point `DB_URL`, `DB_USERNAME`, and `DB_PASSWORD` at the same PostgreSQL database used by the website. Set `MOBILE_TOKEN_SECRET` to a random secret of at least 32 characters on every backend instance. For Flutter Web, set `MOBILE_WEB_ORIGINS` to the exact comma-separated browser origins that host the app. Gate check-in requires an authenticated admin session and CSRF token; do not embed a shared gate credential in the mobile app. Hibernate creates mobile preference, notification, gate check-in, and revoked-session tables in the shared database.

See [`../deployment/staging.env.example`](../deployment/staging.env.example) for the staging backend variable names. It contains placeholders only; configure real database credentials and signing keys in the staging host's secret settings.

## Backend integration status

The mobile JSON APIs live under `/api/mobile/**` and read the same PostgreSQL-backed schedule, important dates, domains, exhibitors, speakers, FAQs, news, and ticket registrations managed by the website. Attendee sign-in verifies the same BCrypt password stored by website ticket registration; the digital pass is derived from that registration. Interests and pass check-ins are persisted in mobile-specific tables linked to the ticket registration. Website HTML admin sessions are not attendee login sessions.

Never place database credentials in the mobile app. Configure database credentials only in the backend's deployment environment.

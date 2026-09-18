# Tawasul School OS — Flutter app

Multi-portal mobile app (Student / Parent / Teacher / Administrator) wired to the
Tawasul (Gibbon fork) REST API. All data is live; there is no mock data.

## Run it

```bash
cd flutter_app
flutter create . --platforms=android,ios   # generates android/ and ios/ folders once
flutter pub get
flutter run
```

The server base URL is set in `lib/core/config.dart`. Override at build time:

```bash
flutter run --dart-define=TAWASUL_BASE_URL=https://se.fiksutilitoimisto.fi/modules/Rest%20API/api.php/v2
```

## How sign-in works

Each person signs in with their own Tawasul username and password.
`POST /auth/login` returns a `tok_...` token which is stored in the device keychain
and sent as `Authorization: Bearer ...` on every request, so the server enforces
that person's real roles and scopes. No shared API key is shipped in the app.

## Layout

```
lib/
  core/          config, HTTP client, token storage, errors, locale + language
  l10n/          Arabic and English strings
  app/           theme, router, role-based portal routing
  features/
    auth/        login, session, /auth/me identity and role resolution
    student/     student portal
    parent/      parent portal
    teacher/     teacher portal
    admin/       administrator portal
  widgets/       shared cards, tiles, states
```

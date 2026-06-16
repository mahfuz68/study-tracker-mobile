# study-tracker-mobile — AGENTS.md

## Commands

| Action | Command |
|--------|---------|
| Get deps | `flutter pub get` |
| Split APKs | `flutter build apk --release --split-per-abi` |
| Universal APK | `flutter build apk --release` |
| Debug APK | `flutter build apk --debug` |
| Lint | `flutter analyze` |
| Tests | `flutter test` |
| Clean | `flutter clean` |

Build commands need `ANDROID_HOME` set. In low-memory environments, add `GRADLE_OPTS="-Dorg.gradle.daemon=false -Dorg.gradle.jvmargs=-Xmx2g"`.

## API base URL

The `API_BASE_URL` is a compile-time env var (`String.fromEnvironment`). The Makefile passes `.env` automatically via `--dart-define-from-file=.env`. Build/run commands in the Makefile already include this flag.

If running `flutter build` manually without Make, add:
```
flutter build apk --release --dart-define-from-file=.env
```

The `.env` file must define `API_BASE_URL` (e.g. `http://10.0.2.2:3000` for Android emulator, or your deployed Next.js URL).

## Architecture

- Entrypoint: `lib/main.dart` → wraps app in `MultiProvider` with 4 providers (Auth, Progress, Mcq, Puzzle).
- Routes defined in `lib/app.dart` — uses named routes with `AppShell` wrapper.
- State: `provider` package with `ChangeNotifier`.
- Data layer: services in `lib/services/` (singleton `ApiClient` via `http` package), models in `lib/models/`.
- Backend: **Next.js web app** (`study-progress-tracker/`) with Prisma + PostgreSQL (Neon).
  Auth uses NextAuth v5 (credentials + JWT). Session cookie is persisted in `SharedPreferences`.

## API client notes

- `ApiClient` (singleton) manages a NextAuth session cookie stored in `SharedPreferences`.
- Login flow: GET `/api/auth/csrf` → POST `/api/auth/callback/credentials` → extract `Set-Cookie`.
- All authenticated requests include the session cookie.
- On 401 responses, the session cookie is cleared automatically.

## Linter

Enforces `prefer_const_constructors` and `prefer_const_declarations`. Avoid non-const method calls (like `.withOpacity()`) inside `const` constructors.

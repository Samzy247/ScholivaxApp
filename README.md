# Scholivax App (Phase 2 — App Shell)

Splash → Select School → Select Role → Login → Dashboard, wired to the
Phase 1 backend endpoints (`/api/schools/list`, `/api/auth/login`).

## What's here
```
app/
  pubspec.yaml       — dependencies (http, shared_preferences, connectivity_plus)
  lib/
    main.dart
    models/          — School, UserSession
    services/        — ApiClient, SchoolService, AuthService, SessionStore
    screens/         — Splash, SchoolSelect, RoleSelect, Login, Dashboard
    widgets/         — NoInternetView (reusable no-connection state)
.github/workflows/build_apk.yml   — builds the APK on GitHub's servers
```

`app/` is **not** a full Flutter project by itself — it's missing the
`android/`, `ios/` native folders on purpose. The GitHub Actions workflow
generates those fresh every build using the real `flutter create` command
(so they're always in sync with whatever current Flutter version GitHub
installs), then drops this `lib/` and `pubspec.yaml` on top. You never
touch native Android files directly.

## How to build the APK

1. Push this whole folder to a GitHub repo (e.g. `ScholivaxApp`) — you can
   do this from Termux with plain `git`:
   ```bash
   cd ~/ScholivaxApp
   git init
   git add .
   git commit -m "Phase 2: app shell"
   git branch -M main
   git remote add origin https://github.com/<you>/ScholivaxApp.git
   git push -u origin main
   ```
2. On GitHub.com, open the repo → **Actions** tab. The "Build Scholivax
   APK" workflow runs automatically on every push to `main` (or trigger it
   manually with the "Run workflow" button).
3. When it finishes (a few minutes), open the completed run → scroll to
   **Artifacts** → download `scholivax-app-release`. That's a zip
   containing `app-release.apk`. Unzip it, copy the APK to your phone,
   install it (you'll need to allow "install unknown apps" once).

## What to test
- Splash shows briefly, then goes to Select School (list from your live
  `/api/schools/list`).
- Search box filters the list as you type.
- Pull down to refresh the school list.
- Tapping a school → Role select → Admin/Teacher or Student.
- Admin/Teacher asks for email; Student asks for Registration Number.
- A correct login goes to the Dashboard and shows your name and role.
- A wrong password shows an inline error, not a crash.
- Turn on Airplane Mode before opening the school list → you should see
  the "No internet connection" screen with a Retry button instead of a
  blank/frozen screen.
- Close and reopen the app after logging in — it should skip straight to
  the Dashboard (session is remembered).
- Tap the logout icon on the Dashboard — should return you to Select School.

## Known gaps (next phases)
- Dashboard is a placeholder — Circulars / Attendance / Marks screens come next.
- No offline SQLite storage yet — that's Phase 3, specifically for the
  attendance-scanning and score-entry screens you asked to work without
  internet.
- Push notifications (FCM) aren't wired into the app yet — the backend
  already sends them; the app just doesn't listen for them yet.
- Parent login (phone number + default password) is intentionally not
  built yet, per your "later update" plan.

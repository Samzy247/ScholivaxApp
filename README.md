# Scholivax App (Phase 2.5 — Modern Dashboard + WebView Portals)

Splash → Select School → Select Role → Login → Dashboard, wired to the
Phase 1 backend endpoints (`/api/schools/list`, `/api/auth/login`).

The Dashboard now has a color-coded header per role (Admin/Teacher/Student/
Parent), "Offline Tools" cards (Circulars, Attendance, Marks — native,
built in Phase 3), and a full grid of cards for every other page of the
website, grouped by section, each opening in an in-app WebView with Home
and Back navigation.

## What's here
```
app/
  pubspec.yaml       — dependencies (http, shared_preferences, connectivity_plus,
                        google_fonts, webview_flutter)
  lib/
    main.dart
    theme/           — AppTheme (Poppins font, brand colors, per-role gradients)
    constants/       — PortalMenu: role → grouped list of website pages
    models/          — School, UserSession
    services/        — ApiClient, SchoolService, AuthService, SessionStore
    screens/         — Splash, SchoolSelect, RoleSelect, Login, Dashboard, WebView
    widgets/         — NoInternetView, PortalSectionView/OfflineQuickActions
.github/workflows/build_apk.yml   — builds the APK on GitHub's servers
backend_fix/controllers/api/Auth.php  — drop-in fix, see "Backend fix" below
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
- No offline SQLite storage yet — that's Phase 3, specifically for the
  attendance-scanning and score-entry screens you asked to work without
  internet. Circulars / Attendance / Marks stay as "Offline Tools" cards
  on the dashboard until then.
- Push notifications (FCM) aren't wired into the app yet — the backend
  already sends them; the app just doesn't listen for them yet. The bell
  icon on the dashboard is currently a placeholder.
- Parent login (phone number + default password) is intentionally not
  built yet, per your "later update" plan.
- **WebView single sign-on**: every portal card opens `https://<subdomain>.scholivax.top/<page>`
  in an in-app WebView, with `app_token`/`app_uid` appended as query params.
  The backend doesn't read those yet, so the *first* visit to any page in a
  session will show the normal website login form. Once you want true
  single sign-on (skip that login), add a small "session bridge" endpoint
  on the backend (mirroring the existing `superadmin_bridge/enter` pattern)
  that trusts `app_token`, looks it up in `api_token`, and sets the same
  session vars `Login_model::loginFunctionForAllUsers()` sets on a normal
  login. Happy to build that next.

## Backend fix included in this update
`application/controllers/api/Auth.php` only checked the `admin`, `teacher`,
`parent`, and `student` tables. The website's own login
(`Login_model::loginFunctionForAllUsers()`) also checks `hrm`, `hostel`,
`accountant`, and `librarian` — so any account in one of those four tables
always got "Invalid login details" from the app, even with the correct
password. Fixed to check the same tables, in the same order, as the web
login. See `backend_fix/controllers/api/Auth.php` — replace your existing
file with it.

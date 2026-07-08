# Scholivax App — Phase 2 (App Shell + WebView Dashboard)

Splash → Select School → Select Role → Login → **your actual website**,
embedded, authenticated, and running as-is — full feature parity with
zero pages rebuilt natively.

## How login → dashboard actually works now
Your web login (`Login::validate_login`) sets a `ci_session` cookie and
already redirects to the right dashboard per role — same field (`email`)
for everyone, including students (checked against `roll` server-side).
So the app:
1. Logs in against the **real website** (`WebSessionService`), the exact
   same way a browser would, and captures that `ci_session` cookie.
2. Also grabs an API token in the background (Phase 1's `/api/auth/login`)
   for the *offline-only* screens coming in Phase 3 — this part is
   best-effort and never blocks login.
3. Hands the cookie to an embedded WebView (`flutter_inappwebview`) and
   loads `https://<subdomain>.scholivax.top/` — your site's own logic
   takes it from there and redirects to the correct dashboard.

Everything on the website — every module, every page — is immediately
available in the app this way, automatically, because it's the same
website. Only two screens will be built natively (Phase 3): attendance
scanning and score entry, specifically because those need to keep working
with no internet.

## What's new in this update
- `flutter_inappwebview` — the embedded browser.
- `google_fonts` — Poppins applied app-wide (native screens use it
  directly via the theme; the WebView also gets a Poppins stylesheet
  injected via JS once each page loads, layered on top of the site's own
  CSS — icon fonts are excluded from the override so icons don't break).
- Pull-to-refresh inside the WebView (native `PullToRefreshController`,
  not just the earlier screens).
- No-internet detection before the WebView loads *and* if it fails mid-load.
- Logout now also clears the WebView's cookies (`CookieManager.deleteAllCookies()`),
  not just the local app session — otherwise the website would silently
  stay logged in next time.

## Known, expected behavior (not a bug)
- If you re-open the app after the 2-hour PHP session expires, the
  WebView will show the site's own login page instead of jumping straight
  to the dashboard — same as what a browser would do. You just log in
  again there.
- The "Coming up next" cards from the old placeholder dashboard are gone —
  replaced by the real thing.

## Build & test — same as before
Push to GitHub, the Action builds the APK, download it from Artifacts.
Test checklist:
- School select, search, pull-to-refresh — unchanged, still works.
- Role select → Login (staff or student) → should land you inside a
  WebView showing your actual admin/teacher/student dashboard, styled in
  Poppins.
- Pull down inside the dashboard WebView → should refresh the page.
- Navigate around inside the WebView (circulars, attendance, marks,
  whatever exists on the site already) — all of it should just work,
  since it's the real site.
- Turn on Airplane Mode, reload → "No internet connection" screen with Retry.
- Logout → back to Select School, and the website itself should also show
  as logged out if you open it in a normal browser.

## Next: Phase 3
- Native, offline-capable attendance scanning + score entry (SQLite +
  background sync using the Phase 1 API token).
- Push notifications for circulars (backend already sends them — app
  doesn't listen yet).
- Parent login (phone number + default password `parent123`) — later,
  per your plan.


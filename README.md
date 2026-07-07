# Scholivax Android App (Phase 1)

Native Kotlin app for teachers, parents, students, and admins, talking to
the REST API added in `php_api_addon/`.

## What works offline
- **Attendance scanning** (teacher): scans a student ID barcode, tries to
  submit live; if there's no connection it's queued on-device and flushed
  automatically the moment connectivity returns (via WorkManager).
- **Score entry** (teacher): once a score sheet has been opened while
  online, it's cached locally — you can open the app with zero signal,
  edit scores, and they'll sync automatically later.
- **Circulars**: cached locally after the first load, viewable offline.

## What needs a connection
- Logging in (first time on a device)
- Parent's live "has my child been marked today" check
- Anything not yet visited/cached once

## Push notifications
- Parent gets a push the moment their child's attendance is marked (teacher
  side) or a new circular is posted (admin side), via Firebase Cloud
  Messaging. Tapping it opens the Circulars/notifications screen.

## Don't have Android Studio? Build it in the cloud with GitHub Actions

This project includes `.github/workflows/build-apk.yml`, which tells
GitHub's free servers to build a debug APK for you automatically — you
never need Android Studio, Gradle, or an SDK on your own device.

### Step 1 — Get the project into a GitHub repository
**If you have access to a computer, even briefly:**
1. Create a free account at github.com if you don't have one.
2. Click "+" → "New repository". Name it e.g. `scholivax-app`, keep it
   Private if you prefer, don't add a README (we already have one).
3. On the new repo's page, click "uploading an existing file", then drag
   the **entire unzipped `ScholivaxApp` folder** into the browser window
   (Chrome/Edge on desktop preserve the folder structure when you drag a
   folder in, not just files — this matters, don't zip it back up first).
4. Commit the upload.

**If you truly only have a phone:**
1. Install **Termux** (from F-Droid, not the outdated Play Store version).
2. In Termux: `pkg install git` then set up a
   [personal access token](https://github.com/settings/tokens) on GitHub
   (Settings → Developer settings → Personal access tokens → generate one
   with "repo" permission).
3. Unzip the project on your phone, then from Termux:
   ```
   cd /path/to/ScholivaxApp
   git init
   git add .
   git commit -m "Initial commit"
   git branch -M main
   git remote add origin https://YOUR_TOKEN@github.com/YOUR_USERNAME/scholivax-app.git
   git push -u origin main
   ```

### Step 2 — Let it build
As soon as you push, GitHub automatically starts the build. Go to your
repo's **Actions** tab in a browser — you'll see "Build Debug APK" running
(takes a few minutes). If you ever want to re-run it without changing
anything, use the "Run workflow" button on that same tab (that's what
`workflow_dispatch` in the file enables).

### Step 3 — Download the APK
Once it finishes (green check), click into that run, scroll to
**Artifacts**, and download `scholivax-debug-apk`. It's a zip containing
`app-debug.apk` — unzip it on your phone.

### Step 4 — Install it
Debug builds are signed with a default debug key, so they install fine —
you just need to allow it: Settings → Apps → (your browser/file manager) →
"Install unknown apps" → allow. Then open the downloaded APK to install.

**Before your first build**, you still need to do two things or the build
will fail:
1. Replace the placeholder `app/google-services.json` with your real one
   from Firebase (see Setup step 1 above) — do this before pushing, or
   push again after adding it.
2. Set your real `BASE_URL` in `app/build.gradle.kts` (see Setup step 2
   above).

## Setup before you can build this

1. **Firebase project**
   - Create a project in the [Firebase console](https://console.firebase.google.com).
   - Add an Android app with package name `com.scholivax.app`.
   - Download the real `google-services.json` and replace
     `app/google-services.json` (currently a placeholder — **the build will
     fail until you do this**).
   - See `php_api_addon/README_BACKEND_SETUP.md` step 4 for the server side
     of FCM setup (service account key).

2. **Point the app at your backend**
   - In `app/build.gradle.kts`, change:
     ```kotlin
     buildConfigField("String", "BASE_URL", "\"https://yourdomain.com/\"")
     ```
     to your real domain (must end with a `/`, must be HTTPS — cleartext
     HTTP is disabled by default in the manifest).

3. **Open in Android Studio**
   - File → Open → select this `ScholivaxApp` folder.
   - Let it sync Gradle (it will generate the wrapper jar automatically;
     if it doesn't, run `gradle wrapper --gradle-version 8.7` once with a
     local Gradle install).
   - Build → Make Project, then Run on a device/emulator.

## What each role sees today (Phase 1 scope)
- **Teacher**: attendance scanning, score entry, circulars.
- **Parent**: today's attendance status for each linked child, circulars,
  push notifications.
- **Student / Admin**: login + circulars for now (view-only placeholders) —
  this is a first pass. Tell me which admin/student features matter most
  (e.g. admin: managing circulars from the app; student: viewing grades,
  timetable) and I'll build those next against the same offline-first
  pattern used above.

## Known simplifications to revisit
- Login uses the same email+password every user already has; there's no
  "forgot password" flow in the app yet (use the website for that).
- Marks Entry currently asks for exam/class/subject IDs directly rather
  than friendly dropdowns — fine to use, but a phase-2 item to replace
  with proper pickers once we wire up `/api/classes`, `/api/subjects`
  endpoints (not built yet).
- Barcode format assumed to be whatever's already printed on your student
  ID cards / already used by the existing web-based scanner (roll number
  as plain text/CODE128/QR — ML Kit reads all common formats).
- No automated tests included yet.

import 'package:firebase_core/firebase_core.dart';

/// Firebase client config for the Android app.
///
/// ⚠️ PLACEHOLDER VALUES — replace before push notifications will work.
///
/// This project already has server-side Firebase set up (the Admin SDK
/// service account used by `fcm_helper.php` to *send* pushes). This file
/// is the other half: the public client config the *app* needs to
/// register with that same Firebase project and *receive* them.
///
/// Where to get these values — Firebase Console → your project (the same
/// one `fcm_service_account.json` belongs to) → ⚙️ Project settings →
/// scroll to "Your apps". If there's no Android app listed yet, add one
/// (package name: com.scholivax.scholivax_scaffold — matches what the
/// CI workflow's `flutter create --org com.scholivax` generates). Once
/// added, either:
///   a) copy the 4 values below out of the config snippet shown there, or
///   b) download google-services.json and send it over — either way
///      works, this file just needs the real values instead of these.
class DefaultFirebaseOptions {
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_WITH_ANDROID_API_KEY',
    appId: 'REPLACE_WITH_ANDROID_APP_ID', // looks like 1:1234567890:android:abcdef123456
    messagingSenderId: 'REPLACE_WITH_SENDER_ID', // the "project number"
    projectId: 'REPLACE_WITH_PROJECT_ID', // same project as fcm_service_account.json
  );
}

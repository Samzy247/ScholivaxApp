import 'package:firebase_core/firebase_core.dart';

/// Firebase client config for the Android app — from the project's
/// google-services.json (Firebase project "scholivax", Android app
/// package com.scholivax.app). The CI workflow forces the built APK's
/// applicationId to match that package exactly (see build_apk.yml).
class DefaultFirebaseOptions {
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAJT9_e0WpSAnOGVDZxnIOQLDHfaUuJpzs',
    appId: '1:422625183071:android:c950f861284e7ad63a62ea',
    messagingSenderId: '422625183071',
    projectId: 'scholivax',
    storageBucket: 'scholivax.firebasestorage.app',
  );
}


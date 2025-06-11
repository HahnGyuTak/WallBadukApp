import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/user_service.dart';
import '../l10n/app_localizations.dart';

class AuthService {

  static Future<String> signInAnonymouslyAndGetUid() async {
    final userCredential = await FirebaseAuth.instance.signInAnonymously();
    return userCredential.user?.uid ?? '';
  }

  /// Sign in with Google and register to Firebase Authentication
  static Future<User?> signInWithGoogle() async {
    try {
      // Trigger the Google Sign-In flow
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        debugPrint('❌ Google Sign-In was cancelled by user');
        return null;
      }

      // Obtain the auth details from the request
      final googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google user credential
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      debugPrint('✅ Google Sign-In successful, UID: ${userCredential.user?.uid}');
      return userCredential.user;
    } catch (e) {
      debugPrint('❌ Google Sign-In error: $e');
      return null;
    }
  }
}

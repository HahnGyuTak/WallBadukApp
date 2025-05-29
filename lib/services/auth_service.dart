// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static Future<String> signInAnonymouslyAndGetUid() async {
    final auth = FirebaseAuth.instance;
    final userCredential = await auth.signInAnonymously();
    await FirebaseAuth.instance.authStateChanges().first;
    final user = userCredential.user;

    if (user != null) {
      print("✅ 로그인 완료: ${user.uid}");
      return user.uid;
    } else {
      throw Exception("❌ 로그인 실패");
    }
  }

  // ✅ 현재 로그인된 UID를 쉽게 가져올 수 있도록 getter 추가
  static String get uid => FirebaseAuth.instance.currentUser!.uid;
}
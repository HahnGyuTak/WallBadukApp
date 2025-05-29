import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/main_menu_page.dart';
import 'firebase_options.dart'; // 자동 생성됨
import 'screens/room_mode_page.dart'; // 새로 만든 페이지
import '../services/auth_service.dart';
import '../services/user_service.dart';

Future<void> initializeUser(BuildContext context) async {
  final uid = await AuthService.signInAnonymouslyAndGetUid();
  final exists = await UserService.documentExists(uid);

  if (!exists) {
    final nickname = await showDialog<String>(
      context: context,
      builder: (context) {
        String tempNickname = '';
        return AlertDialog(
          title: Text('닉네임을 입력하세요'),
          content: TextField(
            onChanged: (value) => tempNickname = value,
            decoration: InputDecoration(hintText: '예: 벽마스터123'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(tempNickname),
              child: Text('확인'),
            ),
          ],
        );
      },
    );

    if (nickname != null && nickname.isNotEmpty) {
      await UserService.ensureUserDocumentExists(uid, nickname);
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    await AuthService.signInAnonymouslyAndGetUid();
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(WallBaduApp());
}



class WallBaduApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '벽바둑',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        // canvasColor: same, primarySwatch 등…
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => MainMenuPage(),
        '/room': (context) => const RoomModePage(), // 여기에 페이지 import 필요
      },
    );
  }
}

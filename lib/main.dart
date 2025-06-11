import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
// import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'screens/main_menu_page.dart';
import 'firebase_options.dart'; // 자동 생성됨
import 'screens/room_mode_page.dart'; // 새로 만든 페이지


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // FirebaseFunctions.instanceFor(region: 'us-central1')
  //   .useFunctionsEmulator('192.168.35.114', 5001);
  // FirebaseAuth.instance.useAuthEmulator('192.168.35.114', 9099);

  final user = FirebaseAuth.instance.currentUser;
  // if (user != null) {
  //   await user.getIdToken(true);
  //   await Future.delayed(Duration(milliseconds: 1000));
  // }

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
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        // canvasColor: same, primarySwatch 등…
      ),

      // 2) 지원할 언어 리스트
      supportedLocales: const [
        Locale('ko'),
        Locale('en'),
      ],

      // 3) 로컬라이제이션 delegate
      localizationsDelegates: const [
        AppLocalizations.delegate,            // ARB → Dart 자동 생성 번역
        GlobalMaterialLocalizations.delegate, // Material 위젯 기본 번역
        GlobalWidgetsLocalizations.delegate,  // Flutter 위젯 텍스트 번역
        GlobalCupertinoLocalizations.delegate // iOS 환경 번역
      ],

      // 4) 사용자의 기기 언어를 supportedLocales와 비교
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale == null) return supportedLocales.first;
        for (final supported in supportedLocales) {
          if (supported.languageCode == locale.languageCode) {
            return supported;
          }
        }
        return supportedLocales.first;
      },

      initialRoute: '/',
      routes: {
        '/': (context) => MainMenuPage(),
        '/room': (context) => const RoomModePage(), // 여기에 페이지 import 필요
      },
    );
  }
}

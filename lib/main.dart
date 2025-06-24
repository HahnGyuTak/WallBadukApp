import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'dart:io' show Platform;
// import 'package:app_tracking_transparency/app_tracking_transparency.dart';
// import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'l10n/app_localizations.dart';
import 'screens/main_menu_page.dart';
import 'firebase_options.dart'; // 자동 생성됨
import 'screens/room_mode_page.dart'; // 새로 만든 페이지


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, s) {
    debugPrint('🔥 Firebase 초기화 실패: $e\n$s');
  }

  // await _initTracking();

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
  runApp(const WallBaduApp());
}


// Future<void> _initTracking() async {
//   if (!Platform.isIOS) return; // iOS에서만
//   final status = await AppTrackingTransparency.trackingAuthorizationStatus;
//   if (status == TrackingStatus.notDetermined) {
//     await AppTrackingTransparency.requestTrackingAuthorization();
//   }
//   // 여기서 상태를 로그로 찍거나 서버에 보내서 저장해도 됩니다.
//   debugPrint('ATT status: $status');
// }


class WallBaduApp extends StatefulWidget {
  const WallBaduApp({super.key});
  @override
  State<WallBaduApp> createState() => _WallBaduAppState();
}

class _WallBaduAppState extends State<WallBaduApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // _initTracking(); // 앱 시작 시 권한 요청
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // _initTracking(); // 포그라운드 복귀 시 재요청
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
      ),
      supportedLocales: const [
        Locale('ko'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
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
        '/room': (context) => const RoomModePage(),
      },
    );
  }
}


import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:io' show Platform;
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'game_page.dart';
import 'tutorial_page.dart';
import 'leaderboard_page.dart'; // 👈 리더보드 페이지 임포트
import 'matching_page.dart';
import 'settings_page.dart';
import '../main.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';



class MainMenuPage extends StatefulWidget {
  const MainMenuPage({super.key});

  @override
  State<MainMenuPage> createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _initialized = false;

  Future<bool> _isConnected() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  void _showNetworkSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('네트워크 연결이 필요합니다.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _playButtonSound() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('soundEnabled') ?? true;
    double value = prefs.getDouble('soundVolume') ?? 0.5;
    if (!enabled) return;
    _audioPlayer.setVolume(value);
    await _audioPlayer.play(AssetSource('button.mp3'));
  }

  Future<void> _initialize() async {
    await initializeUser(context);
    // Remove splash after user initialization
    // ignore: use_build_context_synchronously
    FlutterNativeSplash.remove();
    if (mounted) {
      setState(() {
        _initialized = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isEnLocale = Localizations.localeOf(context).languageCode == 'en';
    final _imgSuffix = isEnLocale ? '_en' : '';

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Color.fromARGB(255, 64, 63, 60)), 
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        // iconTheme: IconThemeData(color: Color(0xFFD4AF37)), 
        // backgroundColor: const Color.fromARGB(255, 57, 34, 17),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            tooltip: AppLocalizations.of(context)!.settingsTooltip,
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (context) => SizedBox(
                  height: MediaQuery.of(context).size.height * 0.85,
                  child: const SettingsPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.leaderboard),
            tooltip: AppLocalizations.of(context)!.leaderboardTooltip,
            onPressed: () async {
              if (!await _isConnected()) {
                _showNetworkSnackBar();
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => LeaderboardPage()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.menu_book),
            tooltip: AppLocalizations.of(context)!.gameRulesTooltip,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => RuleTutorialPage()),
              );
            },
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('lib/img/text/title$_imgSuffix.png', width: _imgSuffix == '_en' ? 320 : 280),
            const SizedBox(height: 60),
            GestureDetector(
              onTap: () async {
                _playButtonSound();
                final prefs = await SharedPreferences.getInstance();
                final _selectedThemeIndex = prefs.getInt('selectedThemeIndex') ?? 0;
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => GamePage(mode: GameMode.vsBot, selectedThemeIndex: _selectedThemeIndex)),
                );
              },
              child: Image.asset('lib/img/button/ai_button$_imgSuffix.png', width: 150),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () async {
                _playButtonSound();
                final prefs = await SharedPreferences.getInstance();
                final _selectedThemeIndex = prefs.getInt('selectedThemeIndex') ?? 0;
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => GamePage(mode: GameMode.local2P, selectedThemeIndex: _selectedThemeIndex)),
                );
              },
              child: Image.asset('lib/img/button/2p_button$_imgSuffix.png', width: 150),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () async {
                if (!await _isConnected()) {
                  _showNetworkSnackBar();
                  return;
                }
                _playButtonSound();
                final prefs = await SharedPreferences.getInstance();
                final selectedThemeIndex = prefs.getInt('selectedThemeIndex') ?? 0;
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MatchingPage(selectedThemeIndex: selectedThemeIndex)),
                );
              },
              child: Image.asset('lib/img/button/online_button$_imgSuffix.png', width: 150),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () async {
                if (!await _isConnected()) {
                  _showNetworkSnackBar();
                  return;
                }
                _playButtonSound();
                Navigator.pushNamed(context, '/room'); // /room 라우트는 아래 참고
              },
              child: Image.asset('lib/img/button/roomCreate_button$_imgSuffix.png', width: 150),
            ),
          ],
        ),
      ),
    );
  }
}



Future<void> initializeUser(BuildContext context) async {
  // 헬퍼: 닉네임 길이 계산
  int _nicknameScore(String s) {
    var total = 0;
    for (final rune in s.runes) {
      final char = String.fromCharCode(rune);
      if (RegExp(r'^[\uAC00-\uD7AF]$').hasMatch(char)) {
        total += 2;
      } else {
        total += 1;
      }
    }
    return total;
  }

  // 헬퍼: 닉네임 유효성 검사
  String? _validateNickname(String s) {
    if (s.trim().isEmpty) return AppLocalizations.of(context)!.pleaseEnterNickname;
    const maxScore = 20;
    final score = _nicknameScore(s);
    if (score > maxScore) {
      final maxEng = maxScore;
      final maxHan = maxScore ~/ 2;
      return AppLocalizations.of(context)!.nicknameTooLong(maxHan, maxEng);
    }
    return null;
  }

  User? user = FirebaseAuth.instance.currentUser;

  // Check Google sign-in status
  final googleSignIn = GoogleSignIn();
  final isGoogleSignedIn = await googleSignIn.isSignedIn();

  // Check Apple sign-in by provider data
  final isAppleSignedIn = user?.providerData.any((p) => p.providerId == 'apple.com') ?? false;

  // 이미 로그인된 경우 처리 (익명: expireAt 갱신)
  if (user != null) {
    if (user.isAnonymous) {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final expireDate = DateTime.now().add(const Duration(days: 30));
      await userRef.set({'expireAt': expireDate}, SetOptions(merge: true));
      return;
    }
    // Google 또는 Apple 로그인 상태면 리턴
    if (isGoogleSignedIn || isAppleSignedIn) {
      return;
    }
  }

  // -------- 로그인 루프 (성공할 때까지 반복) --------
  String? loginMethod;
  while (user == null) {
    loginMethod = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: const Color(0xFF1E1A17),
          title: Text(
            AppLocalizations.of(context)!.loginMethodTitle,
            style: const TextStyle(
              fontFamily: 'ChungjuKimSaeng',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD4AF37),
              shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
            ),
          ),
          content: DefaultTextStyle(
            style: const TextStyle(
              fontFamily: 'ChungjuKimSaeng',
              fontSize: 16,
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 게스트(익명) 버튼
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3A2C1A),
                    foregroundColor: const Color(0xFFD4AF37),
                    fixedSize: const Size(240, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Color(0xFFD4AF37)),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: 'ChungjuKimSaeng',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          backgroundColor: const Color(0xFF1E1A17),
                          title: Text(
                            AppLocalizations.of(context)!.guestLoginWarnTitle,
                            style: const TextStyle(
                              fontFamily: 'ChungjuKimSaeng',
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Color(0xFFD4AF37),
                              shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                            ),
                          ),
                          content: DefaultTextStyle(
                            style: const TextStyle(
                              fontFamily: 'ChungjuKimSaeng',
                              fontSize: 13,
                              color: Colors.white,
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.guestLoginWarnText,
                            ),
                          ),
                          actions: [
                            TextButton(
                              style: TextButton.styleFrom(
                                textStyle: const TextStyle(
                                  fontFamily: 'ChungjuKimSaeng',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                foregroundColor: const Color(0xFFD4AF37),
                              ),
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text(AppLocalizations.of(context)!.no),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                textStyle: const TextStyle(
                                  fontFamily: 'ChungjuKimSaeng',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                foregroundColor: const Color(0xFFD4AF37),
                              ),
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Text(AppLocalizations.of(context)!.yes),
                            ),
                          ],
                        );
                      },
                    );
                    if (confirm == true) {
                      Navigator.of(context).pop('anonymous');
                    }
                  },
                  child: Text(AppLocalizations.of(context)!.continueAsGuest),
                ),
                const SizedBox(height: 8),
                // 구글 버튼
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF202124),
                    side: const BorderSide(color: Color(0xFFDADCE0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    elevation: 1,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    fixedSize: const Size(240, 48),
                  ),
                  onPressed: () => Navigator.of(context).pop('google'),
                  icon: Image.asset(
                    'assets/google_logo.png',
                    width: 18,
                    height: 18,
                  ),
                  label: Text(
                    AppLocalizations.of(context)!.signInWithGoogle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (Platform.isIOS)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      fixedSize: const Size(240, 48),
                    
                    ),
                    onPressed: () => Navigator.of(context).pop('apple'),
                    icon: Image.asset(
                      'assets/apple_logo.png',
                      width: 20,
                      height: 20,
                    ),
                    label: Text(
                      AppLocalizations.of(context)!.signInWithApple,
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );

    // 실제 로그인 수행
    if (loginMethod == 'google') {
      // 로그인 중 안내 스낵바
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.googleLoggingIn),
          duration: const Duration(seconds: 2),
        ),
      );
      user = await AuthService.signInWithGoogle();
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.googleLoginFailed),
            duration: const Duration(seconds: 2),
          ),
        );
        continue;
      } else {
        // 로그인 성공 후 이메일 안내 스낵바
        final email = user.email ?? '';
        if (email.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.welcomeWithEmail(email)),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } else if (loginMethod == 'apple') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.googleLoggingIn),
          duration: const Duration(seconds: 2),
        ),
      );
      user = await AuthService.signInWithApple?.call();
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.googleLoginFailed),
            duration: const Duration(seconds: 2),
          ),
        );
        continue;
      } else {
        final email = user.email ?? '';
        if (email.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.welcomeWithEmail(email)),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } else if (loginMethod == 'anonymous') {
      final uid = await AuthService.signInAnonymouslyAndGetUid();
      user = FirebaseAuth.instance.currentUser;
      if (user?.uid != uid) {
        user = null;
        continue;
      }
    } else {
      // 다이얼로그 취소 → 앱 종료/메인 이동 등
      return;
    }
  }

  // -------------------- 유저 문서 체크 & 생성 ---------------------
  final uid = user.uid;
  final exists = await UserService.documentExists(uid);

  if (!exists) {
    String? nickname;
    while (nickname == null || nickname.isEmpty) {
      nickname = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          String tempNickname = '';
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: const Color(0xFF1E1A17),
            title: Text(
              AppLocalizations.of(context)!.enterNickname,
              style: const TextStyle(
                fontFamily: 'ChungjuKimSaeng',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD4AF37),
                shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
              ),
            ),
            content: DefaultTextStyle(
              style: const TextStyle(
                fontFamily: 'ChungjuKimSaeng',
                fontSize: 16,
                color: Colors.white,
              ),
              child: TextField(
                onChanged: (value) => tempNickname = value,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.nicknameHint,
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                ),
                style: const TextStyle(
                  fontFamily: 'ChungjuKimSaeng',
                  color: Colors.white,
                ),
              ),
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  textStyle: const TextStyle(
                    fontFamily: 'ChungjuKimSaeng',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  foregroundColor: const Color(0xFFD4AF37),
                ),
                onPressed: () {
                  final error = _validateNickname(tempNickname);
                  if (tempNickname.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppLocalizations.of(context)!.pleaseEnterNickname)),
                    );
                    return;
                  }
                  if (error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error)),
                    );
                    return;
                  }
                  Navigator.of(context).pop(tempNickname);
                },
                child: Text(AppLocalizations.of(context)!.confirm),
              ),
            ],
          );
        },
      );
    }
    await UserService.ensureUserDocumentExists(
      uid,
      nickname,
      loginMethod: loginMethod == 'google'
          ? 'google'
          : loginMethod == 'apple'
              ? 'apple'
              : 'anonymous',
    );
  }
  
  // 로그인 완료 알림
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(AppLocalizations.of(context)!.loginComplete)),
  );
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:wall_badu_app/screens/legal_info_page.dart';
import '../services/auth_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../l10n/app_localizations.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:wall_badu_app/services/user_service.dart';
// If using Apple Sign-In:
// import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _soundEnabled = true;
  double _soundVolume = 0.5;
  String _nickname = '';
  int _selectedThemeIndex = 0;
  String _appVersion = '';

  final TextEditingController _nicknameController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();

  late User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _currentUser = FirebaseAuth.instance.currentUser;
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    // Fetch package info for version
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = 'v${packageInfo.version}';
    });
    int storedIndex = prefs.getInt('selectedThemeIndex') ?? 0;
    // 현재 DropdownMenuItem 개수
    const int themeCount = 2;
    if (storedIndex < 0 || storedIndex >= themeCount) {
      storedIndex = 0;
      await prefs.setInt('selectedThemeIndex', 0);
    }
    // Fetch nickname from Firestore if user is logged in
    String nickname = '';
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      nickname = userDoc.data()?['nickname'] ?? '';
    }
    setState(() {
      _soundEnabled = prefs.getBool('soundEnabled') ?? true;
      _soundVolume = prefs.getDouble('soundVolume') ?? 0.5;
      _nickname = nickname;
      // _nicknameController.text = _nickname;
      _selectedThemeIndex = prefs.getInt('selectedThemeIndex') ?? 0;
    });
  }

  Future<void> _updateThemeIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selectedThemeIndex', index);
    setState(() {
      _selectedThemeIndex = index;
    });
  }

  Future<void> _updateSoundEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('soundEnabled', value);
    setState(() {
      _soundEnabled = value;
    });
    debugPrint("설정 변경 : 효과음 ${_soundEnabled ? "켜기" : "끄기"}");
    if (_soundEnabled) {
      _audioPlayer.setVolume(_soundVolume);
      _audioPlayer.play(AssetSource('player.mp3'));
    }
  }

  Future<void> _updateSoundVolume(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('soundVolume', value);
    setState(() {
      _soundVolume = value;
    });
    if (_soundEnabled) {
      _audioPlayer.setVolume(_soundVolume);
      _audioPlayer.play(AssetSource('player.mp3'));
    }
  }

  Future<void> _updateNickname(String value) async {
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.setString('nickname', value); // No longer needed, nickname is now in Firestore only
    setState(() {
      _nickname = value;
    });
    // Firestore update
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'nickname': value});
    }
  }

    // Nickname validation helpers
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

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1A17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1A17),
        iconTheme: const IconThemeData(color: Color(0xFFD4AF37)),
        title: Text(
          AppLocalizations.of(context)!.settingsTitle,
          style: const TextStyle(
            fontFamily: 'ChungjuKimSaeng',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFFD4AF37),
            shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            SwitchListTile(
              title: Text(
                AppLocalizations.of(context)!.toggleSound,
                style: const TextStyle(
                  fontFamily: 'ChungjuKimSaeng',
                  color: Colors.white,
                ),
              ),
              value: _soundEnabled,
              onChanged: (value) => _updateSoundEnabled(value),
              activeColor: const Color(0xFFD4AF37),
            ),
            ListTile(
              title: Text(
                AppLocalizations.of(context)!.soundVolume,
                style: const TextStyle(
                  fontFamily: 'ChungjuKimSaeng',
                  color: Colors.white,
                ),
              ),
              subtitle: Slider(
                value: _soundVolume,
                onChanged: _soundEnabled ? (value) => _updateSoundVolume(value) : null,
                min: 0,
                max: 1,
                divisions: 10,
                label: '${(_soundVolume * 100).round()}%',
                activeColor: const Color(0xFFD4AF37),
                inactiveColor: Colors.brown.shade700,
              ),
            ),
            Divider(color: Colors.brown.shade700),
            ListTile(
              title: Text(
                AppLocalizations.of(context)!.themeSelection,
                style: const TextStyle(
                  fontFamily: 'ChungjuKimSaeng',
                  color: Colors.white,
                ),
              ),
              subtitle: DropdownButton<int>(
                value: _selectedThemeIndex,
                dropdownColor: const Color(0xFF1E1A17),
                isExpanded: false,
                items: [
                  DropdownMenuItem(value: 0, 
                    child: Row(
                      children: [
                        Image.asset(
                            'lib/img/theme/theme1/playerA.png',
                            width: 24,
                            height: 24,
                          ),
                          const SizedBox(width: 8),
                          Image.asset(
                            'lib/img/theme/theme1/playerB.png',
                            width: 24,
                            height: 24,
                          ),
                      ],
                    )
                  ),
                  DropdownMenuItem(value: 1, 
                    child: Row(
                      children: [
                        Image.asset(
                            'lib/img/theme/theme2/playerA.png',
                            width: 24,
                            height: 24,
                          ),
                          const SizedBox(width: 8),
                          Image.asset(
                            'lib/img/theme/theme2/playerB.png',
                            width: 24,
                            height: 24,
                          ),
                      ],
                    )
                  ),
                ],
                onChanged: (value) {
                  if (value != null) _updateThemeIndex(value);
                },
              ),
            ),
            ListTile(
              title: Text(
                AppLocalizations.of(context)!.changeNickname,
                style: const TextStyle(
                  fontFamily: 'ChungjuKimSaeng',
                  color: Colors.white,
                ),
              ),
              subtitle: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nicknameController,
                      decoration: InputDecoration(
                        hintText: _nickname,
                        hintStyle: TextStyle(
                          fontFamily: 'ChungjuKimSaeng',
                          color: Colors.white.withOpacity(0.4),
                        ),
                      ),
                      style: const TextStyle(
                        fontFamily: 'ChungjuKimSaeng',
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3A2C1A),
                      foregroundColor: const Color(0xFFD4AF37),
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
                      final error = _validateNickname(_nicknameController.text);
                      if (_nicknameController.text.trim().isEmpty) {
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
                      await _updateNickname(_nicknameController.text);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context)!.nicknameChanged)),
                      );
                    },
                    child: Text(AppLocalizations.of(context)!.save),
                  ),
                ],
              ),
            ),
            Divider(color: Colors.brown.shade700),
            // Account Management Section
            ListTile(
              title: Text(
                AppLocalizations.of(context)!.accountSectionTitle,
                style: const TextStyle(
                  fontFamily: 'ChungjuKimSaeng',
                  // fontSize: 18,
                  // fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            if (_currentUser != null && _currentUser!.isAnonymous) ...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF202124),
                  side: const BorderSide(color: Color(0xFFDADCE0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  elevation: 1,
                  // padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  fixedSize: const Size(120, 48),
                ),
                onPressed: () async {
                  final currentUser = FirebaseAuth.instance.currentUser;
                  if (currentUser == null || !currentUser.isAnonymous) return;

                  // Save anonymous UID
                  final anonUid = currentUser.uid;

                  try {
                    // Google Sign-In flow
                    final googleUser = await GoogleSignIn().signIn();
                    if (googleUser == null) return;
                    
                    final googleAuth = await googleUser.authentication;
                    final credential = GoogleAuthProvider.credential(
                      accessToken: googleAuth.accessToken,
                      idToken: googleAuth.idToken,
                    );

                    // Try linking anonymous account with Google credential
                    UserCredential userCred = await currentUser.linkWithCredential(credential);

                    // Update local user
                    setState(() => _currentUser = userCred.user);

                    // update Firestore metadata
                    final userRef = FirebaseFirestore.instance
                        .collection('users')
                        .doc(_currentUser!.uid);
                    // Merge login metadata without expireAt
                    await userRef.set({
                      'loginMethod': 'google',
                      'lastLoginAt': FieldValue.serverTimestamp(),
                    }, SetOptions(merge: true));
                    // Remove the expireAt field so TTL no longer applies
                    await userRef.update({'expireAt': FieldValue.delete()});
                    // Reload nickname from Firestore so hintText updates
                    await _loadSettings();
                    // Clear controller to show new hint
                    _nicknameController.clear();
                  } on FirebaseAuthException catch (e) {
                    if (e.code == 'credential-already-in-use') {
                      // Google account already linked to another user
                      // Sign in to that Google account
                      final googleUser = await GoogleSignIn().signIn();
                      if (googleUser == null) return;

                      final googleAuth = await googleUser.authentication;
                      final credential = GoogleAuthProvider.credential(
                        accessToken: googleAuth.accessToken,
                        idToken: googleAuth.idToken,
                      );

                      // Sign in existing Google user
                      UserCredential userCred = await FirebaseAuth.instance.signInWithCredential(credential);
                      final googleUid = userCred.user?.uid;
                      if (googleUid == null) return;

                      // Merge anonymous data into Google user document and do not delete anon document
                      await UserService.mergeAnonymousData(
                        fromUid: anonUid,
                        toUid: googleUid,
                      );

                      // update Firestore metadata for Google user
                      final userRef = FirebaseFirestore.instance
                          .collection('users')
                          .doc(googleUid);
                      // Merge login metadata without expireAt
                      await userRef.set({
                        'loginMethod': 'google',
                        'lastLoginAt': FieldValue.serverTimestamp(),
                      }, SetOptions(merge: true));
                      // Remove the expireAt field so TTL no longer applies
                      await userRef.update({'expireAt': FieldValue.delete()});

                      // Update local user
                      setState(() => _currentUser = userCred.user);
                      // Reload nickname from Firestore so hintText updates
                      await _loadSettings();
                      // Clear controller to show new hint
                      _nicknameController.clear();
                    } else {
                      debugPrint('❌ Google link error: ${e.code}');
                    }
                  } catch (e) {
                    debugPrint('❌ Unexpected error during Google link: $e');
                  }
                },
                icon: Image.asset(
                  'assets/google_logo.png',
                  width: 18,
                  height: 18,
                ),
                label: Text(
                  AppLocalizations.of(context)!.linkGoogle,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              // Uncomment for Apple:
              // ElevatedButton(
              //   onPressed: () async {
              //     final appleCredential = await SignInWithApple.getAppleIDCredential(
              //       scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
              //     );
              //     final oauthCredential = OAuthProvider("apple.com").credential(
              //       idToken: appleCredential.identityToken,
              //       accessToken: appleCredential.authorizationCode,
              //     );
              //     await FirebaseAuth.instance.currentUser!
              //       .linkWithCredential(oauthCredential);
              //     setState(() => _currentUser = FirebaseAuth.instance.currentUser);
              //   },
              //   style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
              //   child: Text(AppLocalizations.of(context)!.linkApple),
              // ),
            ] else ...[
              ListTile(
                title: Text(
                  AppLocalizations.of(context)!.loggedInAs(
                    _currentUser?.email ?? _currentUser?.displayName ?? AppLocalizations.of(context)!.anonymousUser,
                  ),   
                  style: const TextStyle(color: Colors.white70,fontFamily: 'ChungjuKimSaeng'),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        backgroundColor: const Color(0xFF1E1A17),
                        title: Text(
                          AppLocalizations.of(context)!.logoutConfirm,
                          style: const TextStyle(
                            fontFamily: 'ChungjuKimSaeng',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD4AF37),
                            shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                          ),
                        ),
                        // content: DefaultTextStyle(
                        //   style: const TextStyle(
                        //     fontFamily: 'ChungjuKimSaeng',
                        //     fontSize: 16,
                        //     color: Colors.white,
                        //   ),
                        //   child: Text(
                        //     AppLocalizations.of(context)!.logoutConfirmText ?? '',
                        //   ),
                        // ),
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
                            child: Text(AppLocalizations.of(context)!.cancel),
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
                            child: Text(AppLocalizations.of(context)!.confirm),
                          ),
                        ],
                      );
                    },
                  );
                  if (confirm == true) {
                    await FirebaseAuth.instance.signOut();
                    setState(() => _currentUser = null);
                    if (context.mounted) {
                      await _promptLoginMethod(context);
                      setState(() {
                        _currentUser = FirebaseAuth.instance.currentUser;
                      });
                      // After updating _currentUser, reload settings so _nickname updates from Firestore
                      await _loadSettings();
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3A2C1A),
                  foregroundColor: const Color(0xFFD4AF37),
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
                child: Text(AppLocalizations.of(context)!.logout),
              ),
            ],
            Divider(color: Colors.brown.shade700),
            // 로그아웃 버튼 (소셜 로그인 도입 시 활성화)
            // ListTile(
            //   title: ElevatedButton(
            //     onPressed: () {
            //       // 로그아웃 로직 추가 예정
            //     },
            //     child: const Text('로그아웃'),
            //   ),
            // ),
            ListTile(
              title: Text(
                AppLocalizations.of(context)!.versionInfo,
                style: const TextStyle(
                  fontFamily: 'ChungjuKimSaeng',
                  color: Colors.white,
                ),
              ),
              subtitle: Text(
                _appVersion,
                style: const TextStyle(
                  fontFamily: 'ChungjuKimSaeng',
                  color: Colors.white70,
                ),
              ),
              textColor: Colors.white,
            ),
            ListTile(
              title: Text(
                AppLocalizations.of(context)!.developerInfo,
                style: const TextStyle(
                  fontFamily: 'ChungjuKimSaeng',
                  color: Colors.white,
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LegalInfoPage()),
                );
              },
              textColor: Colors.white,
            ),
            ListTile(
              title: Text(
                AppLocalizations.of(context)!.termsOfService,
                style: const TextStyle(
                  fontFamily: 'ChungjuKimSaeng',
                  color: Colors.white,
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LegalInfoPage()),
                );
              },
              textColor: Colors.white,
            ),
            ListTile(
              title: Text(
                AppLocalizations.of(context)!.privacyPolicy,
                style: const TextStyle(
                  fontFamily: 'ChungjuKimSaeng',
                  color: Colors.white,
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LegalInfoPage()),
                );
              },
              textColor: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _promptLoginMethod(BuildContext context) async {
  User? user;
  String? loginMethod;

  // 닉네임 길이 계산 헬퍼
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

  // 닉네임 유효성 검사 헬퍼
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

  while (user == null) {
    // 1. 로그인 방법 선택 다이얼로그
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
                ElevatedButton(
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
                  child: Text(AppLocalizations.of(context)!.continueAsGuest),
                ),
                const SizedBox(height: 8),
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
              ],
            ),
          ),
        );
      },
    );

    // 2. 로그인 시도
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
    }

    // 3. Firestore 유저 문서 체크/생성
    if (user != null) {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final userDoc = await userRef.get();
      final existingNickname = userDoc.data()?['nickname'] as String?;
      String? nickname = existingNickname;
      if (existingNickname == null || existingNickname.isEmpty) {
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
          user.uid,
          nickname,
          loginMethod: loginMethod == 'google' ? 'google' : 'anonymous',
        );
      }
    }
  }

  // 로그인 완료 알림
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(AppLocalizations.of(context)!.loginComplete)),
  );
}
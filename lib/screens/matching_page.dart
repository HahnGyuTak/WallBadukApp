import 'package:flutter/material.dart';
import 'package:wall_badu_app/screens/game_page.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wall_badu_app/services/match_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';



class MatchingPage extends StatefulWidget {
    final int selectedThemeIndex;
  const MatchingPage({super.key, required this.selectedThemeIndex});

  @override
  State<MatchingPage> createState() => _MatchingPageState();
}

class _MatchingPageState extends State<MatchingPage> with WidgetsBindingObserver {
  late final String userId;
  final AudioPlayer _audioPlayer = AudioPlayer();
  Future<void> _playButtonSound() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('soundEnabled') ?? true;
    double value = prefs.getDouble('soundVolume') ?? 0.5;
    if (!enabled) return;
    _audioPlayer.setVolume(value);
    await _audioPlayer.play(AssetSource('button.mp3'));
  }


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ensureLoginAndStartMatching();
  }

  void _ensureLoginAndStartMatching() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      final credential = await FirebaseAuth.instance.signInAnonymously();
      debugPrint('🆕 익명 로그인 완료: ${credential.user?.uid}');
      userId = credential.user!.uid;
    } else {
      debugPrint('✅ 로그인됨: ${user.uid}');
      userId = user.uid;
    }
    _startMatching();
  }

  void _startMatching() async {
    try {
      final (roomId, playerId) = await MatchService.findOrCreateRoom(userId);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => GamePage(
            mode: GameMode.onlineMatching,
            roomId: roomId,
            playerId: playerId,
            selectedThemeIndex: widget.selectedThemeIndex,
          ),
        ),
           );
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'unauthenticated') {
        debugPrint('🚫 인증 오류로 매칭 취소');
        await _cancelMatching();
      } else {
        debugPrint('❌ 매칭 중 오류 발생: $e');
        await _cancelMatching();
      }
    }
  }

  Future<void> _cancelMatching() async {
    await FirebaseFirestore.instance.collection('queue').doc(userId).delete();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _cancelMatching();
        return true;
      },
      child: Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)), // 골드 메탈 색상
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.findingOpponent,
              style: const TextStyle(
                fontFamily: 'ChungjuKimSaeng',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD4AF37), // 골드 텍스트
                shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _playButtonSound();
                _cancelMatching();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3A2C1A), // 다크 브라운 배경
                foregroundColor: const Color(0xFFD4AF37), // 골드 텍스트
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFFD4AF37), width: 2), // 골드 테두리
                ),
                elevation: 4,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: const TextStyle(
                  fontFamily: 'ChungjuKimSaeng',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: Text(AppLocalizations.of(context)!.cancelButton),
            ),
          ],
        ),
      ),
    ),
    );
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // When app goes to background or is detached, cancel matching
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _cancelMatching();
    }
  }
}
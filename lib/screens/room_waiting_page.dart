// lib/screens/room_waiting_page.dart
import 'package:flutter/material.dart';
import 'game_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 추가
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import '../l10n/app_localizations.dart';

class RoomWaitingPage extends StatefulWidget {
  final String roomId;
  final String playerId;
  final int selectedThemeIndex;


  const RoomWaitingPage({required this.roomId, required this.playerId, required this.selectedThemeIndex});

  @override
  State<RoomWaitingPage> createState() => _RoomWaitingPageState();
}
class _RoomWaitingPageState extends State<RoomWaitingPage> {

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
  bool hasNavigated = false; // ✅ 이미 이동했는지 확인하는 플래그
  void initState() {
    super.initState();
    _listenToPlayerCount();

  }

  void _listenToPlayerCount() {
    FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).snapshots().listen((doc) {
      if (!doc.exists || hasNavigated || !mounted) return;
      
      final players = List<String>.from(doc.data()?['players'] ?? []);
      debugPrint('👀 실시간 players 배열: $players');
      if (players.length >= 2 && !hasNavigated && mounted) {
        hasNavigated = true;
        Navigator.pop(context, 'game_started'); // ✅ result를 넘김
        Future.microtask(() {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => GamePage(
                mode: GameMode.onlineManual,
                roomId: widget.roomId,
                playerId: widget.playerId,
                selectedThemeIndex: widget.selectedThemeIndex,
              ),
            ),
          );
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1A17),
      appBar: AppBar(
        iconTheme: IconThemeData(color: Color(0xFFD4AF37)), // ✅ 골드 메탈 색상 적용
        title: Image.asset(
          'lib/img/text/text_room_gold.png',
          height: 32,
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E1A17),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 12),
              child: Text(
                AppLocalizations.of(context)!.waitingForFriend,
                style: const TextStyle(
                  fontFamily: 'ChungjuKimSaeng',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD4AF37),
                  shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF2E2A28),
                border: Border.all(color: const Color(0xFFB68F40), width: 2),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 12,
                    offset: const Offset(4, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppLocalizations.of(context)!.roomCodeLabel,
                    style: const TextStyle(
                      fontFamily: 'ChungjuKimSaeng',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD4AF37),
                      shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SelectableText(
                        widget.roomId,
                        style: const TextStyle(
                          fontFamily: 'ChungjuKimSaeng',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD4AF37),
                          shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.copy, color: Color(0xFFD4AF37)),
                        tooltip: AppLocalizations.of(context)!.copyTooltip,
                        onPressed: () {
                          _playButtonSound();
                          Clipboard.setData(ClipboardData(text: widget.roomId));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(AppLocalizations.of(context)!.roomCodeCopied)),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      _playButtonSound();
                      Share.share('WallBaduk 방 코드: ${widget.roomId}');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E2A28),
                        border: Border.all(color: const Color(0xFFB68F40), width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.share, color: Color(0xFFD4AF37)),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context)!.shareRoomCode,
                            style: const TextStyle(
                              fontFamily: 'ChungjuKimSaeng',
                              color: Color(0xFFD4AF37),
                              fontWeight: FontWeight.bold,
                              shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
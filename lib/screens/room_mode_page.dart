import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_page.dart';
import '../services/room_service.dart';
import 'room_waiting_page.dart';

Future<int> getSelectedThemeIndex() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt('selectedThemeIndex') ?? 0;
}


class RoomModePage extends StatefulWidget {
  const RoomModePage({super.key});

  @override
  State<RoomModePage> createState() => _RoomModePageState();
}

class _RoomModePageState extends State<RoomModePage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Future<void> _playButtonSound() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('soundEnabled') ?? true;
    double value = prefs.getDouble('soundVolume') ?? 0.5;
    if (!enabled) return;
    _audioPlayer.setVolume(value);
    await _audioPlayer.play(AssetSource('button.mp3'));
  }
  final _roomCodeController = TextEditingController();
  String? roomCode;
  bool roomCreated = false;

  void initState(){
    super.initState();
  }

  Future<void> _handleManualRoomCreation() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      // handle unauthenticated case if needed
      return;
    }
    final (roomId, playerId) = await RoomService.createManualRoom(currentUser.uid);
    final themeIndex = await getSelectedThemeIndex();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoomWaitingPage(roomId: roomId, playerId: playerId, selectedThemeIndex: themeIndex),
      ),
    );

    // ⚠️ 게임이 정상 시작된 경우는 leaveRoom 호출하지 않음
    if (result != 'game_started') {
      await RoomService.leaveRoom(roomId, playerId);
    }
  }

  Future<void> _joinRoom() async {
    final code = _roomCodeController.text.trim();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    final playerId = currentUser.uid;
    final joinedId = await RoomService.joinExistingRoom(code, playerId);
    final themeIndex = await getSelectedThemeIndex();

    if (joinedId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GamePage(
            mode: GameMode.onlineManual,
            roomId: code,
            playerId: joinedId,
            selectedThemeIndex: themeIndex,
          ),
        ),
      ).then((_) => RoomService.leaveRoom(code, joinedId));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("해당 방이 존재하지 않습니다.")),
      );
    }
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final usableWidth = constraints.maxWidth;
            final buttonWidth = usableWidth * 0.35; // ✅ 너비 줄임 (35%씩)ㄲ
            final sidePadding = (usableWidth - buttonWidth * 2 - 40) / 2;

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: IntrinsicHeight( // ✅ 높이 동기화 핵심
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch, // ✅ 자식들이 가능한 전체 높이 사용
                      children: [
                        // 방 생성 카드
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(20),
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
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text("방 생성", style: const TextStyle(fontFamily: 'ChungjuKimSaeng',fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37), shadows: [Shadow(color: Colors.black54, blurRadius: 4)])),
                                const SizedBox(height: 16),
                                Expanded(
                                  child: Center(
                                    child: GestureDetector(
                                      onTap: () {
                                        _playButtonSound();
                                        _handleManualRoomCreation();
                                      },
                                      child: Image.asset(
                                        'lib/img/button/create_button.png',
                                        fit: BoxFit.contain,
                                        height: 60,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 24),

                        // 방 입장 카드
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(20),
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
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text("방 입장", style: const TextStyle(fontFamily: 'ChungjuKimSaeng',fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37), shadows: [Shadow(color: Colors.black54, blurRadius: 4)])),
                                const SizedBox(height: 16),
                                TextField(
                                  style: const TextStyle(
                                    fontFamily: 'ChungjuKimSaeng',
                                    color: Colors.white, // 입력 텍스트를 흰색으로 조정
                                  ),
                                  controller: _roomCodeController,
                                  decoration: InputDecoration(
                                    labelText: "방 코드 입력",
                                    labelStyle: const TextStyle(
                                      fontFamily: 'ChungjuKimSaeng',
                                      color: Color(0xFFD4AF37), // 원하는 골드 메탈 색상
                                    ),
                                    floatingLabelStyle: const TextStyle(
                                      fontFamily: 'ChungjuKimSaeng',
                                      color: Color(0xFFD4AF37),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFF2E2A28),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(color: Color(0xFFB68F40), width: 2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    hintStyle: const TextStyle(fontFamily: 'ChungjuKimSaeng',color: Color(0xFFBFA662)),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                GestureDetector(
                                  onTap: () {
                                    _playButtonSound();
                                    _joinRoom();
                                  },
                                  child: Image.asset(
                                    'lib/img/button/in_button.png',
                                    fit: BoxFit.contain,
                                    height: 50,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
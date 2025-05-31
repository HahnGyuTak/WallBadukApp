import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_page.dart';
import 'tutorial_page.dart';
import 'leaderboard_page.dart'; // 👈 리더보드 페이지 임포트
import 'matching_page.dart';
import 'settings_page.dart';
import '../services/match_service.dart';
import '../main.dart';

class MainMenuPage extends StatefulWidget {
  const MainMenuPage({super.key});

  @override
  State<MainMenuPage> createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage> {
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
    initializeUser(context); // 여기에 닉네임 입력 로직
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Color.fromARGB(255, 64, 63, 60)), 
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        // iconTheme: IconThemeData(color: Color(0xFFD4AF37)), 
        // backgroundColor: const Color.fromARGB(255, 57, 34, 17),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            tooltip: "설정",
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
            tooltip: '리더보드',
            onPressed: () {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(builder: (_) => LeaderboardPage()),
              // );
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('리더보드는 추후 업데이트될 예정입니다.'),
                    duration: Duration(seconds: 2),
                  ),
                );
            },
          ),
          IconButton(
            icon: Icon(Icons.menu_book),
            tooltip: '게임 규칙',
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
            Image.asset('lib/img/text/title.png', width: 280),
            const SizedBox(height: 60),
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
              child: Image.asset('lib/img/button/2p_button.png', width: 150),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () async {
                _playButtonSound();
                // final prefs = await SharedPreferences.getInstance();
                // final selectedThemeIndex = prefs.getInt('selectedThemeIndex') ?? 0;
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(builder: (_) => MatchingPage(selectedThemeIndex: selectedThemeIndex)),
                // );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('온라인 매칭 기능은 추후 업데이트될 예정입니다.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: Image.asset('lib/img/button/online_button.png', width: 150),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                _playButtonSound();
                Navigator.pushNamed(context, '/room'); // /room 라우트는 아래 참고
              },
              child: Image.asset('lib/img/button/roomCreate_button.png', width: 150),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:wall_badu_app/screens/legal_info_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _soundEnabled = true;
  double _soundVolume = 0.5;
  String _nickname = '';

  final TextEditingController _nicknameController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _soundEnabled = prefs.getBool('soundEnabled') ?? true;
      _soundVolume = prefs.getDouble('soundVolume') ?? 0.5;
      _nickname = prefs.getString('nickname') ?? '';
      _nicknameController.text = _nickname;
    });
  }

  Future<void> _updateSoundEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('soundEnabled', value);
    setState(() {
      _soundEnabled = value;
    });
    print("설정 변경 : 효과음 ${_soundEnabled ? "켜기" : "끄기"}");
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nickname', value);
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
          '설정',
          style: TextStyle(
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
              title: const Text(
                '효과음 켜기/끄기',
                style: TextStyle(
                  fontFamily: 'ChungjuKimSaeng',
                  color: Colors.white,
                ),
              ),
              value: _soundEnabled,
              onChanged: (value) => _updateSoundEnabled(value),
              activeColor: const Color(0xFFD4AF37),
            ),
            ListTile(
              title: const Text(
                '효과음 볼륨 조절',
                style: TextStyle(
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
              title: const Text(
                '닉네임 변경',
                style: TextStyle(
                  fontFamily: 'ChungjuKimSaeng',
                  color: Colors.white,
                ),
              ),
              subtitle: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nicknameController,
                      decoration: const InputDecoration(
                        hintText: '닉네임을 입력하세요',
                        hintStyle: TextStyle(
                          fontFamily: 'ChungjuKimSaeng',
                          color: Colors.white70,
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
                      await _updateNickname(_nicknameController.text);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('닉네임이 변경되었습니다.')),
                      );
                    },
                    child: const Text('변경'),
                  ),
                ],
              ),
            ),
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
              title: const Text(
                '버전 정보',
                style: TextStyle(
                  fontFamily: 'ChungjuKimSaeng',
                  color: Colors.white,
                ),
              ),
              subtitle: const Text(
                'v1.0.0',
                style: TextStyle(
                  fontFamily: 'ChungjuKimSaeng',
                  color: Colors.white70,
                ),
              ),
              textColor: Colors.white,
            ),
            ListTile(
              title: const Text(
                '개발자 정보',
                style: TextStyle(
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
              title: const Text(
                '이용약관',
                style: TextStyle(
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
              title: const Text(
                '개인정보처리방침',
                style: TextStyle(
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
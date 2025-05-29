import 'package:flutter/material.dart';

class RuleTutorialPage extends StatelessWidget {
  final List<Map<String, String>> rules = [
    {
      'title': '1. 말 배치하기',
      'desc': '각 플레이어는 총 4개의 말을 사용합니다.\n•	이 중 2개는 미리 정해진 위치에 자동 배치되고,\n•	나머지 2개는 원하는 칸에 자유롭게 배치합니다.',
      'asset': 'lib/img/tutorial/1.gif',
    },
    {
      'title': '2. 말 이동',
      'desc': '마지막에 말을 배치한 플레이어부터 턴을 시작합니다.\n말은 상하좌우 방향으로 최대 2칸까지 이동할 수 있습니다.\n제자리 이동도 허용됩니다.',
      'asset': 'lib/img/tutorial/2.gif',
    },
    {
      'title': '3. 벽 설치',
      'desc': '말을 이동한 후, 각 말의 주변에 벽 1개씩 설치할 수 있습니다.\n벽으로 막힌 방향으로는 이동할 수 없습니다.\n⏱ 제한 시간 60초 안에 이동과 벽 설치를 완료하지 않으면, 무작위로 벽이 자동 설치됩니다.',
      'asset': 'lib/img/tutorial/3.gif',
    },
    {
      'title': '4. 영역 분리',
      'desc': '벽 설치로 인해 내 말들과 상대방 말들의 영역이 분리되면, 게임은 즉시 종료됩니다.',
      'asset': 'lib/img/tutorial/4.gif',
    },
    {
      'title': '5. 점수 계산',
      'desc': '분리된 각 영역의 칸 개수를 세어 점수를 계산합니다.\n더 많은 영역을 확보한 쪽이 승리합니다.',
      'asset': 'lib/img/tutorial/5.gif',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1A17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1A17),
        iconTheme: const IconThemeData(color: Color(0xFFD4AF37)),
        title: const Text(
          '게임 규칙',
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
        padding: const EdgeInsets.all(16.0),
        child: PageView.builder(
          itemCount: rules.length,
          itemBuilder: (context, index) {
            final rule = rules[index];
            return Column(
              children: [
                Text(rule['title']!,
                    style: const TextStyle(
                      fontFamily: 'ChungjuKimSaeng',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD4AF37),
                    )),
                const SizedBox(height: 12),
                Text(rule['desc']!,
                    style: const TextStyle(
                      fontFamily: 'ChungjuKimSaeng',
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),
                Expanded(
                  child: Center(
                    child: Image.asset(rule['asset']!, fit: BoxFit.contain),
                    // 또는: VideoPlayerController.asset('...') 를 사용한 영상도 가능
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
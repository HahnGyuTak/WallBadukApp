import 'package:flutter/material.dart';
import 'package:wall_badu_app/screens/game_page.dart';
import 'package:wall_badu_app/services/game_themes.dart';
import '../l10n/app_localizations.dart';


class Scoreboard extends StatelessWidget {
  final int seconds;
  final String instruction;
  final GameMode mode;
  final Player currentTurn;
  final Player? myPlayer;
  final int selectedThemeIndex;

  const Scoreboard({
    Key? key,
    required this.seconds,
    required this.instruction,
    required this.mode,
    required this.currentTurn,
    required this.selectedThemeIndex,
    this.myPlayer,
  }) : super(key: key);


  GameTheme get currentTheme => availableThemes[selectedThemeIndex];


  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      // 1) 전광판 외곽
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('lib/img/display_bi.png'),
          fit: BoxFit.cover,
        ),      // 어두운 배경
        border: Border.all(
          color: Color(0xFFB68F40),            // 골드 테두리
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 4,
            offset: Offset(1, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 2) 타이머 숫자
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.access_time, color: Colors.greenAccent, size: 20),
              const SizedBox(width: 6),
              Text(
                '$seconds', 
                style: TextStyle(
                  fontFamily: 'ChungjuKimSaeng',        // Digital7 같은 LED 스타일 폰트
                  fontSize: 36,
                  color: Colors.greenAccent,
                  shadows: [
                    Shadow(
                      color: Colors.greenAccent.withOpacity(0.6), 
                      blurRadius: 12
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 2),
              Text(
                AppLocalizations.of(context)!.secondsSuffix,
                style: TextStyle(
                  fontFamily: 'ChungjuKimSaeng',
                  fontSize: 18,
                  color: Colors.greenAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 3) 안내 문구 with game piece image or turn notice
          Builder(
            builder: (_) {
              final instructionStyle = TextStyle(
                fontFamily: 'ChungjuKimSaeng',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD4AF37),
                shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
              );
              if (mode == GameMode.local2P) {
                final img = currentTurn == Player.A
                  ? currentTheme.playerAImagePath //currentTheme.playerAImagePath
                  : currentTheme.playerBImagePath;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(img, width: 20, height: 20),
                    const SizedBox(width: 6),
                    Text(instruction, style: instructionStyle),
                  ],
                );
              } else {
                final isMyTurn = currentTurn == myPlayer;
                if (!isMyTurn) {
                  return Text(
                    AppLocalizations.of(context)!.opponentTurn,
                    style: TextStyle(
                      fontFamily: 'ChungjuKimSaeng',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD4AF37),
                      shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                    ),
                  );
                }
                final img = myPlayer == Player.A
                  ? currentTheme.playerAImagePath
                  : currentTheme.playerBImagePath;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(img, width: 20, height: 20),
                    const SizedBox(width: 6),
                    Text(instruction, style: instructionStyle),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
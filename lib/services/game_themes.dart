import 'package:flutter/material.dart';

class GameTheme {
  final String name;
  final Color playerAColor;
  final Color playerBColor;
  final String playerAImagePath;
  final String playerBImagePath;
  final String wallARowImagePath;
  final String wallAColImagePath;
  final String wallBRowImagePath;
  final String wallBColImagePath;

  const GameTheme({
    required this.name,
    required this.playerAColor,
    required this.playerBColor,
    required this.playerAImagePath,
    required this.playerBImagePath,
    required this.wallARowImagePath,
    required this.wallAColImagePath,
    required this.wallBRowImagePath,
    required this.wallBColImagePath,
  });
}

final List<GameTheme> availableThemes = [

  GameTheme(
    name: 'theme1',
    playerAColor: Colors.red.shade100, // Example green
    playerBColor: Colors.blue.shade100, // Example brown/red
    playerAImagePath: 'lib/img/theme/theme1/playerA.png',
    playerBImagePath: 'lib/img/theme/theme1/playerB.png',
    wallARowImagePath: 'lib/img/theme/theme1/wallA_row.png',
    wallAColImagePath: 'lib/img/theme/theme1/wallA_col.png',
    wallBRowImagePath: 'lib/img/theme/theme1/wallB_row.png',
    wallBColImagePath: 'lib/img/theme/theme1/wallB_col.png',
  ),
    GameTheme(
    name: 'theme2',
    playerAColor: Color(0xFFE3A857), // Jade-like green
    playerBColor: Color(0xFF8FD9C1), // Amber/Honey-like
    playerAImagePath: 'lib/img/theme/theme2/playerA.png',
    playerBImagePath: 'lib/img/theme/theme2/playerB.png',
    wallARowImagePath: 'lib/img/theme/theme2/wallA_row.png',
    wallAColImagePath: 'lib/img/theme/theme2/wallA_col.png',
    wallBRowImagePath: 'lib/img/theme/theme2/wallB_row.png',
    wallBColImagePath: 'lib/img/theme/theme2/wallB_col.png',
  ),
  //   GameTheme(
  //   name: 'theme1',
  //   playerAColor: Color(0xFF8FD9C1), // Jade-like green
  //   playerBColor: Color(0xFFD4AF37), // Gold
  //   playerAImagePath: 'lib/img/theme/theme3/playerA.png',
  //   playerBImagePath: 'lib/img/theme/theme3/playerB.png',
  //   wallARowImagePath: 'lib/img/theme/theme3/wallA_row.png',
  //   wallAColImagePath: 'lib/img/theme/theme3/wallA_col.png',
  //   wallBRowImagePath: 'lib/img/theme/theme3/wallB_row.png',
  //   wallBColImagePath: 'lib/img/theme/theme3/wallB_col.png',
  // ),
  // GameTheme(
  //   name: 'theme2',
  //   playerAColor: Color(0xFFE3A857), // Amber/Honey-like
  //   playerBColor: Color(0xFF3A3A3A), // Charcoal
  //   playerAImagePath: 'lib/img/theme/theme4/playerA.png',
  //   playerBImagePath: 'lib/img/theme/theme4/playerB.png',
  //   wallARowImagePath: 'lib/img/theme/theme4/wallA_row.png',
  //   wallAColImagePath: 'lib/img/theme/theme4/wallA_col.png',
  //   wallBRowImagePath: 'lib/img/theme/theme4/wallB_row.png',
  //   wallBColImagePath: 'lib/img/theme/theme4/wallB_row.png',
  // ),
];
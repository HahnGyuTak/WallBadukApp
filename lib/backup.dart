// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:collection/collection.dart';

// void main() {
//   runApp(WallBaduApp());
// }

// class WallBaduApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: '벽바둑',
//       home: MainMenuPage(),
//     );
//   }
// }

// class MainMenuPage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               '벽바둑',
//               style: TextStyle(
//                 fontSize: 48,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 60),
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (_) => GamePage()),
//                 );
//               },
//               child: Text('2인 대결'),
//             ),
//             const SizedBox(height: 16),
//             ElevatedButton(
//               onPressed: () {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(content: Text('온라인 대결은 추후 구현 예정입니다.')),
//                 );
//               },
//               child: Text('온라인 대결'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

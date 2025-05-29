import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';

class MatchService {
  static Future<(String roomId, String playerId)> findOrCreateRoom(String userId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw FirebaseFunctionsException(
        code: 'unauthenticated',
        message: '사용자 인증이 필요합니다.',
        details: null,
      );
    }
    else{
      // print("user : $user");
      // ✅ 인증 토큰 강제 갱신
      await user.getIdToken(true);
      
      // ✅ 잠시 대기하여 토큰이 Functions 호출에 반영되도록
      await Future.delayed(Duration(milliseconds: 500));
      await FirebaseAuth.instance.idTokenChanges().first;
      final callable = FirebaseFunctions.instance.httpsCallable('matchUser');
      final result = await callable();

      if (result.data['matched'] == true) {
        final roomId = result.data['roomId'];
        return (roomId as String, userId);
      } else {
        // 매칭 대기 중 → Firestore에서 방 생성을 감지 (지금처럼)
        final completer = Completer<(String, String)>();
        final sub = FirebaseFirestore.instance
            .collection('rooms')
            .where('players', arrayContains: userId)
            .snapshots()
            .listen((snapshot) {
          for (final doc in snapshot.docs) {
            final data = doc.data();
            if ((data['playerA'] != null) && (data['playerB'] != null)) {
              if (!completer.isCompleted) {
                completer.complete((doc.id, userId));
              }
            }
          }
        });

        completer.future.then((_) => sub.cancel());
        return completer.future;
      }
    }
  }
  // static final _db = FirebaseFirestore.instance;
  // static final _uuid = Uuid();

  // static Future<(String roomId, String playerId)> findOrCreateRoom(String userId) async {
  //   final queueRef = _db.collection('queue');
  //   final snapshot = await queueRef.get();

  //   for (var doc in snapshot.docs) {
  //     final opponentId = doc.id;
  //     print('✅ 방 생성 대기 중...');
  //     if (opponentId != userId) {
  //       final roomId = _uuid.v4();
  //       final sorted = [userId, opponentId];
  //       await _db.collection('rooms').doc(roomId).set({
  //         'players': sorted,
  //         'playerA': sorted[0],
  //         'playerB': sorted[1],
  //         'createdAt': FieldValue.serverTimestamp(),
  //         'placementPhase': true,
  //         'turn': 'A',
  //       });
  //       print('🎯 매칭 완료: roomId=$roomId');
  //       await queueRef.doc(opponentId).delete();
  //       await queueRef.doc(userId).delete(); 
  //       return (roomId, userId);
  //     }
  //   }

  //   // 대기열에 자신 등록
  //   await queueRef.doc(userId).set({'timestamp': FieldValue.serverTimestamp()});
  //   print("Queue 등록 완료");

  //   final completer = Completer<(String, String)>();
  //   late final StreamSubscription sub;

  //   sub = _db.collection('rooms')
  //       .where('players', arrayContains: userId)
  //       .snapshots()
  //       .listen((snapshot) {
  //     if (snapshot.docs.isNotEmpty && !completer.isCompleted) {
  //       final doc = snapshot.docs.first;
  //       // ✅ 방이 실제 생성되었는지 확인하는 보조 조건 (playerA 포함 여부 등)
  //       final data = doc.data();
  //       if ((data['playerA'] != null) && (data['playerB'] != null)) {
  //         completer.complete((doc.id, userId));
  //       }
  //     }
  //   });

  //   completer.future.then((_) => sub.cancel());
  //   return completer.future;
  // }
}
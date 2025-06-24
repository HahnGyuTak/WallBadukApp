// lib/services/room_service.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class RoomService {
  /// 단순히 방을 생성하고 방 ID 반환
  static Future<String> createRoom() async {
    final doc = await FirebaseFirestore.instance.collection('rooms').add({
      'players': [],
      'isFull': false,
      'createdAt': FieldValue.serverTimestamp(),
      'expireAt': Timestamp.fromDate(DateTime.now().add(Duration(hours: 1))),
    });
    return doc.id;
  }

  static Future<(String roomId, String playerId)> createManualRoom(String playerId) async {
    final newRoomId = const Uuid().v4().substring(0, 6);

    final docRef = FirebaseFirestore.instance.collection('rooms').doc(newRoomId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      transaction.set(docRef, {
        'players': [playerId],
        'createdAt': FieldValue.serverTimestamp(),
        'expireAt': Timestamp.fromDate(DateTime.now().add(Duration(hours: 1))),
        'placementPhase': true, // 👈 추가
        'turn': 'A',            // 👈 초기 턴 설정
        'playerA': playerId,    // 👈 첫 플레이어를 A로 지정
      });
    });

    return (newRoomId, playerId);
  }

  /// 방에 플레이어 추가 (안전하게 중복 제거 포함)
  static Future<void> joinRoomAsPlayer(String roomId, String playerId) async {
    final ref = FirebaseFirestore.instance.collection('rooms').doc(roomId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final existingPlayers = List<String>.from(snapshot.data()?['players'] ?? []);

      if (!existingPlayers.contains(playerId)) {
        final updatedPlayers = [...existingPlayers, playerId];
        updatedPlayers.sort();

        final playerA = snapshot.data()?['playerA'] ?? updatedPlayers[0];
        final playerB = playerA == updatedPlayers[0] ? updatedPlayers[1] : updatedPlayers[0];

        transaction.update(ref, {
          'players': updatedPlayers,
          'playerA': playerA,
          'playerB': playerB,
        });
      }
    });

    // 디버깅용 로그 출력
    final updated = await ref.get();
    final updatedPlayers = updated.data()?['players'];
    debugPrint('✅ joinRoomAsPlayer: $playerId added to $roomId -> $updatedPlayers');
  }

  /// 온라인 매칭: 대기열이 있으면 방 생성 후 둘 다 입장
  static Future<String> matchOnline(String nickname) async {
    final queueRef = FirebaseFirestore.instance.collection('queue');
    final waiting = await queueRef.orderBy('joinedAt').limit(1).get();

    if (waiting.docs.isEmpty) {
      await queueRef.add({
        'nickname': nickname,
        'joinedAt': FieldValue.serverTimestamp(),
      });
      return 'waiting';
    } else {
      final opponent = waiting.docs.first;
      final opponentNickname = opponent['nickname'];

      // 방 생성
      final roomId = await createRoom();

      // 두 플레이어 입장 처리
      await joinRoomAsPlayer(roomId, opponentNickname);
      await joinRoomAsPlayer(roomId, nickname);

      // 대기열 제거
      await opponent.reference.delete();

      return roomId;
    }
  }

  /// 방에 플레이어가 아무도 없으면 해당 방 삭제
  static Future<void> deleteRoomIfEmpty(String roomId) async {
    final ref = FirebaseFirestore.instance.collection('rooms').doc(roomId);
    final doc = await ref.get();

    if (!doc.exists) return;

    final players = List<String>.from(doc.data()?['players'] ?? []);
    if (players.isEmpty) {
      await ref.delete();
      debugPrint('빈 방 삭제됨: $roomId');
    }
  }

  static Future<String?> joinExistingRoom(String roomCode, String playerId) async {
    final docRef = FirebaseFirestore.instance.collection('rooms').doc(roomCode);

    final docSnapshot = await docRef.get();
    if (!docSnapshot.exists) {
      debugPrint('❌ 존재하지 않는 방 코드: $roomCode');
      return null;
    }

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      final existingPlayers = List<String>.from(snapshot.data()?['players'] ?? []);
      if (!existingPlayers.contains(playerId)) {
        final updatedPlayers = [...existingPlayers, playerId];

        final playerA = snapshot.data()?['playerA'] ?? updatedPlayers[0];
        final playerB = playerA == updatedPlayers[0] ? updatedPlayers[1] : updatedPlayers[0];

        transaction.update(docRef, {
          'players': updatedPlayers,
          'playerA': playerA,
          'playerB': playerB,
        });

        debugPrint('👥 이전 플레이어 목록: $existingPlayers');
        debugPrint('➕ 추가된 플레이어: $playerId');
        debugPrint('📤 최종 players: $updatedPlayers');
      }
    });

    return playerId;
  }

  static Future<void> leaveRoom(String roomId, String playerId) async {
    final roomRef = FirebaseFirestore.instance.collection('rooms').doc(roomId);
    await roomRef.update({
      'players': FieldValue.arrayRemove([playerId])
    });

    final snapshot = await roomRef.get();
    final players = List<String>.from(snapshot.data()?['players'] ?? []);
    if (players.isEmpty) {
      await roomRef.delete();
    }
  }
}

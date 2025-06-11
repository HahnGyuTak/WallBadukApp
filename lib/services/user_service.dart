import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  static Future<void> ensureUserDocumentExists(
    String uid,
    String nickname, {
    String loginMethod = 'anonymous',
  }) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final doc = await userRef.get();

    if (!doc.exists) {
      // Prepare base data
      final data = {
        'nickname': nickname,
        'wins': 0,
        'losses': 0,
        'draw': 0,
        'score': 1000,
        'createdAt': FieldValue.serverTimestamp(),
        'loginMethod': loginMethod,
        'lastLoginAt': FieldValue.serverTimestamp(),
      };
      // Only set expireAt for anonymous users
      if (loginMethod == 'anonymous') {
        data['expireAt'] = DateTime.now().add(const Duration(days: 30));
      }
      await userRef.set(data);
      debugPrint("✅ 사용자 문서 생성 완료");
    } else {
      debugPrint("📄 사용자 문서 이미 존재");
    }
  }

  static Future<bool> documentExists(String uid) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final doc = await userRef.get();
    return doc.exists;
  }

  static Future<void> updateScore(
    String uid, {
      required String result, 
      String? opponentUid,
      int? ownScore,
      int? oppScore,
      }) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final doc = await userRef.get();
    String opponentNickname = 'unknown';
    if (opponentUid != null) {
      final opponentDoc = await FirebaseFirestore.instance.collection('users').doc(opponentUid).get();
      if (opponentDoc.exists) {
        opponentNickname = opponentDoc.data()?['nickname'] ?? 'unknown';
      }
    }
    if (!doc.exists) return;

    final data = doc.data()!;
    
    int currentScore = ownScore ?? 1000;
    int newScore = currentScore;

    // Apply new scoring rules:
    if (result == 'draw') {
      // Rule 3: Draw, both +5
      newScore = currentScore + 5;
    } else if (result == 'win' || result == 'lose') {
      if (opponentUid != null) {
        // Fetch opponent's score

        int opponentScore = oppScore ?? 1000;

        // Determine higher (A) and lower (B)
        int higherScore = currentScore >= opponentScore ? currentScore : opponentScore;
        int lowerScore = currentScore < opponentScore ? currentScore : opponentScore;
        bool isCurrentA = currentScore >= opponentScore;

        if (result == 'win') {
          if (isCurrentA) {
            // Rule 1: Higher (A) wins => +10
            newScore = currentScore + 10;
          } else {
            // Rule 2: Lower (B) wins
            int change = ((higherScore - lowerScore) ~/ 10).clamp(10, higherScore);
            newScore = currentScore + change;
          }
        } else {
          // result == 'lose'
          if (isCurrentA) {
            // Rule 2: Higher (A) loses to lower (B)
            int change = ((higherScore - lowerScore) ~/ 10).clamp(10, higherScore);
            newScore = currentScore - change;
          } else {
            // Rule 1: Lower (B) loses to higher (A) => -10
            newScore = currentScore - 10;
          }
        }
      }
    }

    // Ensure score does not go negative
    if (newScore < 0) newScore = 0;

    await userRef.update({
      'score': newScore,
      if (result == 'win') 'wins': FieldValue.increment(1),
      if (result == 'lose') 'losses': FieldValue.increment(1),
      if (result == 'draw') 'draws': FieldValue.increment(1),
    });

    await userRef.collection('matchHistory').add({
      'result': result,
      'opponent': opponentNickname,
      'timestamp': FieldValue.serverTimestamp(),
      'deltaScore': newScore-currentScore
    });

    // Prune matchHistory to keep only the 10 most recent entries:
    final historyRef = userRef.collection('matchHistory');
    final historySnap = await historyRef.orderBy('timestamp').get();
    final excess = historySnap.docs.length - 10;
    if (excess > 0) {
      for (int i = 0; i < excess; i++) {
        await historyRef.doc(historySnap.docs[i].id).delete();
      }
    }

    debugPrint("📊 점수 및 기록 업데이트 완료 ($result) → $newScore점");
  }

  /// Merge data from an anonymous user document into an existing user document,
  /// then update login metadata on the target user document.
  static Future<void> mergeAnonymousData({
    required String fromUid,
    required String toUid,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final anonRef = firestore.collection('users').doc(fromUid);
    final targetRef = firestore.collection('users').doc(toUid);

    final anonDoc = await anonRef.get();
    if (!anonDoc.exists) return;
    final anonData = anonDoc.data()!;

    final batch = firestore.batch();

    // 1) anonData에서 nickname을 제거한 뒤 머지
    final dataToMerge = Map<String, dynamic>.from(anonData)
      ..remove('nickname');
    batch.set(targetRef, dataToMerge, SetOptions(merge: true));

    // 2) matchHistory 복사
    final anonHistoryRef = anonRef.collection('matchHistory');
    final targetHistoryRef = targetRef.collection('matchHistory');
    final historySnap = await anonHistoryRef.get();
    for (var doc in historySnap.docs) {
      batch.set(targetHistoryRef.doc(doc.id), doc.data());
    }

    // 3) 로그인 메타데이터 업데이트 (이미 구글/애플 사용자라 expireAt은 삭제돼 있습니다)
    batch.set(targetRef, {
      'loginMethod': 'google',            // 또는 'apple'
      'lastLoginAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
    debugPrint('✅ 익명 데이터가 Google/Apple UID로 머지되었습니다.');
  }
}

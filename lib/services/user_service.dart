import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  static Future<void> ensureUserDocumentExists(String uid, String nickname) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final doc = await userRef.get();

    if (!doc.exists) {
      await userRef.set({
        'nickname': nickname,
        'wins': 0,
        'losses': 0,
        'draw' : 0,
        'score': 1000, // 🔥 기본 점수 부여
        'createdAt': FieldValue.serverTimestamp(),
      });
      print("✅ 사용자 문서 생성 완료");
    } else {
      print("📄 사용자 문서 이미 존재");
    }
  }

  static Future<bool> documentExists(String uid) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final doc = await userRef.get();
    return doc.exists;
  }

  static Future<void> updateScore(String uid, {required String result, String? opponentUid}) async {
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
    int currentScore = data['score'] ?? 1000;
    int delta = 0;

    if (result == 'win') delta = 10;
    else if (result == 'lose') delta = -10;
    else if (result == 'draw') delta = 5;

    int newScore = (currentScore + delta).clamp(0, 99999);

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

    print("📊 점수 및 기록 업데이트 완료 ($result) → $newScore점");
  }
}

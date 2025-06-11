const admin = require('firebase-admin');
const { v4: uuidv4 } = require('uuid');
const { onCall } = require('firebase-functions/v2/https');

admin.initializeApp();
const db = admin.firestore();

exports.matchUser = onCall(async (data, context) => {
  console.log('📥 호출됨: matchUser');
  console.log('✅ context.auth:', context.auth);
  console.log('✅ context.rawRequest.headers.authorization:', context.rawRequest?.headers?.authorization);

  try {
    const uid = context.auth?.uid;
    if (!uid) {
        console.log("❌ 인증 실패: context.auth와 토큰 모두 없음");
        throw new functions.https.HttpsError('unauthenticated', '로그인이 필요합니다.');
    }

    const result = await tryMatchUser(uid);
    return result;
  } catch (err) {
    console.error("🔥 Cloud Function 내부 오류:", err);
    throw new functions.https.HttpsError('internal', '서버에서 문제가 발생했습니다.');
  }
});

async function tryMatchUser(uid) {
  const queueRef = db.collection('queue');
  const queueDoc = queueRef.doc(uid);
  const now = admin.firestore.FieldValue.serverTimestamp();

  // Get all users currently in the queue
  const snapshot = await queueRef.get();

  // Try to find an opponent in the queue
  for (const doc of snapshot.docs) {
    const opponentId = doc.id;
    if (opponentId === uid) continue;

    const roomId = uuidv4();
    const players = [uid, opponentId].sort();

    // Create a new room with matched players
    await db.collection('rooms').doc(roomId).set({
      players,
      playerA: players[0],
      playerB: players[1],
      createdAt: now,
      placementPhase: true,
      turn: 'A',
    });

    // Remove both players from the queue
    await Promise.all([
      queueRef.doc(opponentId).delete(),
      queueRef.doc(uid).delete(),
    ]);

    return { matched: true, roomId };
  }

  // No opponent found, add user to the queue
  await queueDoc.set({ timestamp: now });
  return { matched: false };
}
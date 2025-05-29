const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { v4: uuidv4 } = require('uuid');

admin.initializeApp();
const db = admin.firestore();

exports.matchUser = functions.https.onCall(async (data, context) => {
  
  console.log('📥 호출됨: matchUser');
  console.log('✅ context.auth:', context.auth);
  console.log('✅ context.rawRequest.headers.authorization:', context.rawRequest?.headers?.authorization);
  const uid = context.auth?.uid;
  print(context)
  if (!uid) {
    throw new functions.https.HttpsError('unauthenticated', '로그인이 필요합니다.');
  }

  const queueRef = db.collection('queue');
  const queueDoc = queueRef.doc(uid);
  const now = admin.firestore.FieldValue.serverTimestamp();

  const snapshot = await queueRef.get();

  for (const doc of snapshot.docs) {
    const opponentId = doc.id;

    if (opponentId !== uid) {
      const roomId = uuidv4();
      const players = [uid, opponentId].sort();

      await db.collection('rooms').doc(roomId).set({
        players,
        playerA: players[0],
        playerB: players[1],
        createdAt: now,
        placementPhase: true,
        turn: 'A',
      });

      await Promise.all([
        queueRef.doc(opponentId).delete(),
        queueRef.doc(uid).delete(),
      ]);

      return { matched: true, roomId };
    }
  }

  // 상대가 없으면 큐에 본인 등록
  await queueDoc.set({ timestamp: now });
  return { matched: false };
});
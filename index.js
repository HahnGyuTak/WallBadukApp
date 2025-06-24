const express = require("express");
const admin = require("firebase-admin");
const app = express();

// 비공개 키 경로
const serviceAccount = require("./wallbaduk-firebase-adminsdk-fbsvc-4466ff53cc.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});
const db = admin.firestore();

app.get("/", async (req, res) => {
  const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);
  const snapshot = await db.collection("rooms")
    .where("createdAt", "<", admin.firestore.Timestamp.fromDate(oneHourAgo))
    .get();

  for (const doc of snapshot.docs) {
    await admin.firestore().recursiveDelete(doc.ref);
    console.log(`✅ Deleted room ${doc.id} and its subcollections`);
  }

  res.send(`🧹 Deleted ${snapshot.size} expired rooms.`);
});

const PORT = process.env.PORT || 8080;
app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
});
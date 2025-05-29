import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LeaderboardPage extends StatefulWidget {
  @override
  _LeaderboardPageState createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? uid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    uid = FirebaseAuth.instance.currentUser?.uid;
  }

  Widget _buildTopRankersTab() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .orderBy('score', descending: true)
          .limit(50)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(Color(0xFFD4AF37)),
        ));

        final users = snapshot.data!.docs;

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final data = users[index].data() as Map<String, dynamic>;
            final userId = users[index].id;
            final nickname = data['nickname'] ?? '익명';
            final isMe = userId == uid;

            return Container(
              color: isMe ? const Color(0xFF3A2C1A) : null, // dark brown highlight
              child: ListTile(
                tileColor: Colors.transparent,
                leading: Text('#${index + 1}', style: const TextStyle(color: Colors.white)),
                title: DefaultTextStyle.merge(
                  style: const TextStyle(fontFamily: 'ChungjuKimSaeng', color: Colors.white),
                  child: Text('닉네임: $nickname'),
                ),
                subtitle: DefaultTextStyle.merge(
                  style: const TextStyle(fontFamily: 'ChungjuKimSaeng', color: Colors.white),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Wins: ${data['wins']}  Losses: ${data['losses']}  Draws: ${data['draws'] ?? 0}'),
                      Text(
                        '승률: ${((data['wins'] + data['losses'] + (data['draws'] ?? 0)) > 0)
                          ? ((data['wins'] / (data['wins'] + data['losses'] + (data['draws'] ?? 0))) * 100).toStringAsFixed(1)
                          : '0.0'}%',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                trailing: Text('${data['score']}점',
                  style: const TextStyle(
                    fontFamily: 'ChungjuKimSaeng',
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRelativeRankersTab() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .orderBy('score', descending: true)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(Color(0xFFD4AF37)),
        ));

        final users = snapshot.data!.docs;
        final index = users.indexWhere((doc) => doc.id == uid);
        if (index == -1) return const Center(child: Text('자신의 순위를 찾을 수 없습니다.'));

        final start = (index - 50).clamp(0, users.length - 1);
        final end = (index + 50).clamp(0, users.length);
        final range = users.sublist(start, end);

        return ListView.builder(
          itemCount: range.length,
          itemBuilder: (context, i) {
            final user = range[i];
            final data = user.data() as Map<String, dynamic>;
            final userId = user.id;
            final isMe = userId == uid;
            final nickname = data['nickname'] ?? '익명';
            
            return Container(
              color: isMe ? const Color(0xFF3A2C1A) : null, // dark brown highlight
              child: ListTile(
                tileColor: Colors.transparent,
                leading: Text('#${start + i + 1}', style: const TextStyle(color: Colors.white)),
                title: DefaultTextStyle.merge(
                  style: const TextStyle(fontFamily: 'ChungjuKimSaeng', color: Colors.white),
                  child: Text('닉네임: $nickname'),
                ),
                subtitle: DefaultTextStyle.merge(
                  style: const TextStyle(fontFamily: 'ChungjuKimSaeng', color: Colors.white),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Wins: ${data['wins']}  Losses: ${data['losses']}  Draws: ${data['draws'] ?? 0}'),
                      Text(
                        '승률: ${((data['wins'] + data['losses'] + (data['draws'] ?? 0)) > 0)
                          ? ((data['wins'] / (data['wins'] + data['losses'] + (data['draws'] ?? 0))) * 100).toStringAsFixed(1)
                          : '0.0'}%',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                trailing: Text('${data['score']}점',
                  style: const TextStyle(
                    fontFamily: 'ChungjuKimSaeng',
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMyStatsTab() {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(Color(0xFFD4AF37)),
        ));

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        if (data == null) return const Center(child: Text('데이터 없음'));

        final wins = data['wins'] ?? 0;
        final losses = data['losses'] ?? 0;
        final draws = data['draws'] ?? 0;
        final totalGames = wins + losses + draws;
        final winRate = totalGames > 0 ? ((wins / totalGames) * 100).toStringAsFixed(1) : '0.0';
        final nickname = data['nickname'] ?? '익명';
        
        return Column(
          children: [
            const SizedBox(height: 16),
            Card(
              color: const Color(0xFF3A2C1A),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nickname, style: const TextStyle(fontFamily: 'ChungjuKimSaeng', fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 8),
                    Text('점수: ${data['score']}점', style: const TextStyle(fontFamily: 'ChungjuKimSaeng', fontSize: 18, color: Colors.white)),
                    Text('승률: $winRate%  🏆 $wins  ❌ $losses  🤝 $draws', style: const TextStyle(fontFamily: 'ChungjuKimSaeng', color: Colors.white)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('최근 10경기', style: TextStyle(fontFamily: 'ChungjuKimSaeng', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('matchHistory')
                    .orderBy('timestamp', descending: true)
                    .limit(10)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(Color(0xFFD4AF37)),
                  ));

                  final matches = snapshot.data!.docs;
                  if (matches.isEmpty) {
                    return const Center(child: Text('최근 경기가 없습니다.', style: TextStyle(fontFamily: 'ChungjuKimSaeng', color: Colors.white70)));
                  }

                  return ListView.builder(
                    itemCount: min(matches.length, 10),
                    itemBuilder: (context, index) {
                      final match = matches[index].data() as Map<String, dynamic>;
                      final opponent = match['opponent'];
                      final result = match['result'];
                      final timestamp = match['timestamp'] as Timestamp?;
                      final dateStr = timestamp != null
                          ? DateTime.fromMillisecondsSinceEpoch(timestamp.millisecondsSinceEpoch).toLocal().toString().split(' ')[0]
                          : '';

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        color: const Color(0xFF1E1A17),
                        child: ListTile(
                          tileColor: Colors.transparent,
                          title: RichText(
                            text: TextSpan(
                              style: const TextStyle(fontFamily: 'ChungjuKimSaeng', fontSize: 16, color: Colors.white),
                              children: [
                                const TextSpan(text: 'vs '),
                                TextSpan(
                                  text: '$opponent  ',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                TextSpan(
                                  text: result,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: result == 'win'
                                        ? Colors.blue
                                        : result == 'lose'
                                            ? Colors.red
                                            : Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          subtitle: Text(dateStr, style: const TextStyle(fontFamily: 'ChungjuKimSaeng', color: Colors.white70)),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1A17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1A17),
        iconTheme: const IconThemeData(color: Color(0xFFD4AF37)),
        title: const Text(
          '🏆 리더보드',
          style: TextStyle(
            fontFamily: 'ChungjuKimSaeng',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFFD4AF37),
            shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFD4AF37),
          labelColor: const Color(0xFFD4AF37),
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontFamily: 'ChungjuKimSaeng',
            fontWeight: FontWeight.bold,
          ),
          tabs: const [
            Tab(text: '상위 랭커'),
            Tab(text: '내 랭킹 보기'),
            Tab(text: '내 기록'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTopRankersTab(),
          _buildRelativeRankersTab(),
          _buildMyStatsTab(),
        ],
      ),
    );
  }
}
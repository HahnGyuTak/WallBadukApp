import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../l10n/app_localizations.dart';


class LeaderboardPage extends StatefulWidget {
  @override
  _LeaderboardPageState createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? uid;

  final ScrollController _relativeScrollController = ScrollController();
  final GlobalKey _myTileKey = GlobalKey();
  bool _hasScrolledToMe = false;

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
                  child: Text(AppLocalizations.of(context)!.nicknameLabel(nickname)),
                ),
                subtitle: DefaultTextStyle.merge(
                  style: const TextStyle(fontFamily: 'ChungjuKimSaeng', color: Colors.white),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Wins: ${data['wins']}  Losses: ${data['losses']}  Draws: ${data['draws'] ?? 0}'),
                      Text(
                        AppLocalizations.of(context)!.winRateLabel(
                          ((data['wins'] + data['losses'] + (data['draws'] ?? 0)) > 0)
                            ? ((data['wins'] / (data['wins'] + data['losses'] + (data['draws'] ?? 0))) * 100).toStringAsFixed(1)
                            : '0.0'
                        ),
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                trailing: Text(
                  AppLocalizations.of(context)!.scoreLabel(data['score']),
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
        if (index == -1) return Center(child: Text(AppLocalizations.of(context)!.noData));

        final start = (index - 20).clamp(0, users.length - 1);
        final end = (index + 20).clamp(0, users.length);
        final range = users.sublist(start, end);

        // Scroll to my tile once
        if (!_hasScrolledToMe) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_myTileKey.currentContext != null) {
              Scrollable.ensureVisible(
                _myTileKey.currentContext!,
                duration: Duration(milliseconds: 300),
                alignment: 0.5,
              );
            }
          });
          _hasScrolledToMe = true;
        }

        return ListView.builder(
          controller: _relativeScrollController,
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
                key: isMe ? _myTileKey : null,
                tileColor: Colors.transparent,
                leading: Text('#${start + i + 1}', style: const TextStyle(color: Colors.white)),
                title: DefaultTextStyle.merge(
                  style: const TextStyle(fontFamily: 'ChungjuKimSaeng', color: Colors.white),
                  child: Text(AppLocalizations.of(context)!.nicknameLabel(nickname)),
                ),
                subtitle: DefaultTextStyle.merge(
                  style: const TextStyle(fontFamily: 'ChungjuKimSaeng', color: Colors.white),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Wins: ${data['wins']}  Losses: ${data['losses']}  Draws: ${data['draws'] ?? 0}'),
                      Text(
                        AppLocalizations.of(context)!.winRateLabel(
                          ((data['wins'] + data['losses'] + (data['draws'] ?? 0)) > 0)
                            ? ((data['wins'] / (data['wins'] + data['losses'] + (data['draws'] ?? 0))) * 100).toStringAsFixed(1)
                            : '0.0'
                        ),
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                trailing: Text(
                  AppLocalizations.of(context)!.scoreLabel(data['score']),
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
        if (data == null) return Center(child: Text(AppLocalizations.of(context)!.noData));

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
                    Text(
                      AppLocalizations.of(context)!.scoreLabel(data['score']),
                      style: const TextStyle(
                        fontFamily: 'ChungjuKimSaeng',
                        fontSize: 18,
                        color: Colors.white
                      ),
                    ),
                    Text(
                      '${AppLocalizations.of(context)!.winRateLabel(winRate)}  🏆 $wins  ❌ $losses  🤝 $draws',
                      style: const TextStyle(
                        fontFamily: 'ChungjuKimSaeng',
                        color: Colors.white
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.matchesHeading,
              style: const TextStyle(
                fontFamily: 'ChungjuKimSaeng',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white
              ),
            ),
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
                    return Center(child: Text(
                      AppLocalizations.of(context)!.noRecentMatches,
                      style: const TextStyle(fontFamily: 'ChungjuKimSaeng', color: Colors.white70),
                    ));
                  }

                  return ListView.builder(
                    itemCount: min(matches.length, 10),
                    itemBuilder: (context, index) {
                      final match = matches[index].data() as Map<String, dynamic>;
                      final opponent = match['opponent'];
                      final result = match['result'];
                      final deltaScore = match['deltaScore'] as int? ?? 0;
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
                                const TextSpan(text: 'vs   ', style: TextStyle(fontSize: 10)),
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
                                TextSpan(
                                  text: ' (${deltaScore >= 0 ? '+' : ''}$deltaScore)',
                                  style: TextStyle(
                                    fontFamily: 'ChungjuKimSaeng',
                                    fontSize: 14,
                                    color: result == 'win' ? Colors.blue : result == 'lose' ? Colors.red : Colors.green,
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
        title: Text(
          AppLocalizations.of(context)!.leaderboardTitle,
          style: const TextStyle(
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
          tabs: [
            Tab(text: AppLocalizations.of(context)!.topRankersTab),
            Tab(text: AppLocalizations.of(context)!.viewMyRankingTab),
            Tab(text: AppLocalizations.of(context)!.myRecordsTab),
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
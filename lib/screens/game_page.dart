import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:collection/collection.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wall_badu_app/services/game_themes.dart';
import '../l10n/app_localizations.dart';
import '../services/user_service.dart';
import '../widgets/scoreboard.dart';
import 'package:flutter/foundation.dart';
import '../ai/bot_engine.dart';

part 'game_page_bot.dart';

enum GameMode {
  local2P,
  onlineManual,     // 수동 방 생성
  onlineMatching,   // 매칭 기반 게임
  vsBot,            // 로컬 1P vs 간단 AI
}

enum BotDifficulty { easy, medium }

enum Player { none, A, B }

class Piece {
  final Player owner;
  int row;
  int col;

  Piece(this.owner, this.row, this.col);
}

class GamePage extends StatefulWidget {
  final GameMode mode;
  final String? roomId;
  final String? playerId; // 👈 여기 추가
  final int selectedThemeIndex;

  

  const GamePage({required this.mode, this.roomId, this.playerId, required this.selectedThemeIndex});

  @override
  _GamePageState createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with TickerProviderStateMixin {
  late int selectedThemeIndex;
  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> _playPlayerSound() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('soundEnabled') ?? true;
    double value = prefs.getDouble('soundVolume') ?? 0.5;
    if (!enabled) return;
    _audioPlayer.setVolume(value);
    await _audioPlayer.play(AssetSource('player.mp3'));
  }

  Future<void> _playWallSound() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('soundEnabled') ?? true;
    double value = prefs.getDouble('soundVolume') ?? 0.5;
    if (!enabled) return;
    _audioPlayer.setVolume(value);
    await _audioPlayer.play(AssetSource('wall.mp3'));
  }

  String? playerAName = 'unknown';
  String? playerBName = 'unknown';
  int? playerAScore;
  int? playerBScore;

  Future<void> _loadPlayerNames() async {
    final roomDoc = await FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .get();
    String playerA_UID = roomDoc.data()?['playerA'];
    String playerB_UID = roomDoc.data()?['playerB'];
    String ANickName = 'unknown';
    String BNickName = 'unknown';
    int? aScore;
    int? bScore;

    if (playerA_UID != null) {
      final AUserDoc = await FirebaseFirestore.instance.collection('users').doc(playerA_UID).get();
      if (AUserDoc.exists) {
        ANickName = AUserDoc.data()?['nickname'] ?? 'unknown';
        aScore = AUserDoc.data()?['score'] as int?;
      }
    }
    if (playerB_UID != null) {
      final BUserDoc = await FirebaseFirestore.instance.collection('users').doc(playerB_UID).get();
      if (BUserDoc.exists) {
        BNickName = BUserDoc.data()?['nickname'] ?? 'unknown';
        bScore = BUserDoc.data()?['score'] as int?;
      }
    }
    setState(() {
      playerAName = ANickName;
      playerBName = BNickName;
      playerAScore = aScore;
      playerBScore = bScore;
    });
  }

  String? gameResultText;
  int updatedAcount = 0;
  int updatedBcount = 0;

  Map<String, Color> highlightedAreas = {};
  Map<String, double> highlightedOpacity = {};
  late AnimationController highlightController;
  static const int boardSize = 7;
  // Delay before bot acts so player has breathing room

  List<List<Player>> board =
      List.generate(boardSize, (_) => List.filled(boardSize, Player.none));
  // Track all pieces on the board
  List<Piece> pieces = [];

  Player currentTurnPlayer = Player.A;
  int aPiecesPlaced = 2;
  int bPiecesPlaced = 2;
  bool placementPhase = true;
  bool gameStarted = false;
  bool gameEnded = false;   // ➊ 새 플래그

  int? previousScore;
  int? finalScore = null;

  int? selectedRow;
  int? selectedCol;

  // Store wall positions as strings like 'row,col:direction' with owner
  Map<String, Player> walls = {};

  // Store last moved piece's position
  int? lastMovedRow;
  int? lastMovedCol;

  // Timer for move phase
  Timer? moveTimer;
  int remainingTime = 60;

  /// 봇이 수를 두기 전 지연 시간 (난이도별 설정)
  Duration botTurnDelay = const Duration(milliseconds: 3000); // 기본값 (초급)

  bool isAwaitingWall = false;
  // --- Bot visual indicator ---
  int? botPrevRow;
  int? botPrevCol;

  Player? myPlayer;
  BotDifficulty botDifficulty = BotDifficulty.easy;   // default
  
  

  bool get isBotMode => widget.mode == GameMode.vsBot;

  void _startTimer() {
    if (gameEnded) return;

    // 중복 실행 방지
    moveTimer?.cancel();

    moveTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        remainingTime--;

        if (remainingTime <= 0) {
          moveTimer?.cancel();

          if (placementPhase) {
            // 말 배치 시간 초과
            if (isBotMode && currentTurnPlayer != myPlayer) {
              // 봇 차례 – 임의 배치
              _botPlaceInitialPiece();
            } else {
              _placeRandomInitialPiece();
            }
          } else {
            // 이동 + 벽 설치 시간 초과
            if (isBotMode && currentTurnPlayer != myPlayer) {
              _botPlaceRandomWall();
            } else {
              _placeRandomWall();
            }
          }
        }
      });
    });
  }

  void _placeRandomWall() {
    // If there is a last moved piece, attempt to place near it
    if (lastMovedRow != null && lastMovedCol != null) {
      List<String> directions = ['top', 'bottom', 'left', 'right'];
      directions.shuffle();

      for (String dir in directions) {
        final key = wallKey(lastMovedRow!, lastMovedCol!, dir);
        final delta = {
          'top': [-1, 0, 'bottom'],
          'bottom': [1, 0, 'top'],
          'left': [0, -1, 'right'],
          'right': [0, 1, 'left'],
        };
        final d = delta[dir]!;
        int neighborRow = lastMovedRow! + (d[0] as int);
        int neighborCol = lastMovedCol! + (d[1] as int);
        String opposite = d[2] as String;
        final neighborKey = wallKey(neighborRow, neighborCol, opposite);

        bool inBounds = neighborRow >= 0 &&
                        neighborRow < boardSize &&
                        neighborCol >= 0 &&
                        neighborCol < boardSize;
        if (!walls.containsKey(key) &&
            (!inBounds || !walls.containsKey(neighborKey))) {
          isAwaitingWall = false;
          _placeWall(dir);
          return;
        }
      }
    }

    // If no last moved piece or no valid direction from it, pick another piece
    // Gather all pieces of current player that have at least one valid direction for a wall
    List<Piece> candidates = [];
    for (var piece in pieces.where((p) => p.owner == currentTurnPlayer)) {
      int r = piece.row;
      int c = piece.col;
      Map<String, List> delta = {
        'top': [-1, 0, 'bottom'],
        'bottom': [1, 0, 'top'],
        'left': [0, -1, 'right'],
        'right': [0, 1, 'left'],
      };

      bool hasValid = false;
      for (var entry in delta.entries) {
        String dir = entry.key;
        final d = entry.value;
        int nr = r + (d[0] as int);
        int nc = c + (d[1] as int);
        String opp = d[2] as String;
        final key = wallKey(r, c, dir);
        final neighborKey = wallKey(nr, nc, opp);
        bool inBounds = nr >= 0 && nr < boardSize && nc >= 0 && nc < boardSize;
        if (!walls.containsKey(key) &&
            (!inBounds || !walls.containsKey(neighborKey))) {
          hasValid = true;
          break;
        }
      }
      if (hasValid) {
        candidates.add(piece);
      }
    }

    // If no piece can place a wall, do nothing
    if (candidates.isEmpty) return;

    // Randomly select one piece from candidates
    final randomPiece = (candidates..shuffle()).first;
    int pr = randomPiece.row;
    int pc = randomPiece.col;

    // Build valid directions for that piece
    List<String> validDirs = [];
    Map<String, List> delta = {
      'top': [-1, 0, 'bottom'],
      'bottom': [1, 0, 'top'],
      'left': [0, -1, 'right'],
      'right': [0, 1, 'left'],
    };
    for (var entry in delta.entries) {
      String dir = entry.key;
      final d = entry.value;
      int nr = pr + (d[0] as int);
      int nc = pc + (d[1] as int);
      String opp = d[2] as String;
      final key = wallKey(pr, pc, dir);
      final neighborKey = wallKey(nr, nc, opp);
      bool inBounds = nr >= 0 && nr < boardSize && nc >= 0 && nc < boardSize;
      if (!walls.containsKey(key) &&
          (!inBounds || !walls.containsKey(neighborKey))) {
        validDirs.add(dir);
      }
    }

    // Randomly select one valid direction
    validDirs.shuffle();
    final selectedDir = validDirs.first;

    // Update lastMovedRow/Col so _placeWall works correctly
    lastMovedRow = pr;
    lastMovedCol = pc;
    isAwaitingWall = false;
    _placeWall(selectedDir);
  }

  void _debugCheckRoomSubcollections() async {
    final roomId = widget.roomId;
    if (roomId == null) return;

    final movesSnapshot = await FirebaseFirestore.instance
        .collection('rooms')
        .doc(roomId)
        .collection('moves')
        .get();

    final wallsSnapshot = await FirebaseFirestore.instance
        .collection('rooms')
        .doc(roomId)
        .collection('walls')
        .get();

    debugPrint('🧩 moves 개수: ${movesSnapshot.docs.length}');
    for (var doc in movesSnapshot.docs) {
      debugPrint('📦 move: ${doc.data()}');
    }

    debugPrint('🧱 walls 개수: ${wallsSnapshot.docs.length}');
    for (var doc in wallsSnapshot.docs) {
      debugPrint('📦 wall: ${doc.data()}');
    }
  }

  late final GameTheme currentTheme;
  @override
  void initState() {
    super.initState();
    // Load saved theme before any logic
    selectedThemeIndex = widget.selectedThemeIndex;
    highlightController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    currentTheme = availableThemes[selectedThemeIndex];
    if (isBotMode) {
      // ➊ 난이도 → ➋ 말 선택 순서로 진행
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // 난이도 선택
        final diff = await _showDifficultySelectionDialog(context);
        if (!mounted) return;
        setState(() => botDifficulty = diff ?? BotDifficulty.easy);
        setState(() => botTurnDelay = Duration(milliseconds: botDifficulty == BotDifficulty.easy ? 1000 : 100));
        
        // 말 선택
        final choice = await _showSideSelectionDialog(context, currentTheme);
        if (!mounted) return;
        setState(() {
          myPlayer = choice;
          gameStarted = true;
        });
        _placeInitialPieces();
      });
      return; // defer rest of init until after selection
    }
    if (widget.mode != GameMode.local2P && widget.mode != GameMode.vsBot ) {
      _loadPlayerNames();
      _waitForPlayers();
      // Listen for someone leaving immediately
      _listenToPlayerChanges();
    } else {
      gameStarted = true;
      _placeInitialPieces();
    }
  }

  // Wall key generator
  String wallKey(int row, int col, String direction) => '$row,$col:$direction';

  @override
  void _waitForPlayers() async {
    final docRef = FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);

    docRef.snapshots().listen((snapshot) {
      final players = List<String>.from(snapshot.data()?['players'] ?? []);

      if (players.toSet().length == 2 && !gameStarted) {
        final index = players.indexOf(widget.playerId!);
        setState(() {
          myPlayer = index == 0 ? Player.A : Player.B;
          gameStarted = true;
        });
        _placeInitialPieces();
        // _debugCheckRoomSubcollections(); // 👈 디버깅용
        // Start timer immediately after initial pieces placed and game started
        // remainingTime = 60;
        // _startTimer();
      }
    });
  }

  Future<void> _listenToPlayerChanges() async {
    if (widget.roomId == null || widget.playerId == null) return;

    FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;

      final players = List<String>.from(snapshot.data()?['players'] ?? []);
      if (players.length == 1 && players.contains(widget.playerId)) {
        if (finalScore != null) {
          debugPrint('✅ 이미 점수 반영됨 → 퇴장 처리 생략');
          return;
        }
        
        moveTimer?.cancel();
        
        if (widget.mode == GameMode.onlineMatching && widget.playerId != null && myPlayer != null) {
          _handleOpponentLeft();  // 🔁 async 작업을 별도 함수로 분리
        }
        setState(() {
          gameResultText = AppLocalizations.of(context)!.opponentLeft;
        });
      }
    });
  }

  Future<void> _handleOpponentLeft() async {
    final roomRef = FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);
    final data = (await roomRef.get()).data();
    final playerA = data?['playerA'];
    final playerB = data?['playerB'];

    final loserId = playerA == widget.playerId ? playerB : playerA;
    final doc = await FirebaseFirestore.instance.collection('users').doc(widget.playerId).get();
    final previous = doc.data()?['score'] ?? 1000;

    // 퇴장 승리 처리 시, 내 점수 & 상대 점수를 함께 넘김
    if (widget.playerId == playerA) {
      // 내가 A일 때
      await UserService.updateScore(
        playerA!,               // 이긴 쪽 UID
        result: 'win',
        opponentUid: loserId,
        ownScore: playerAScore,         // 내 점수
        oppScore: playerBScore,    // 상대 점수
      );
    } else {
      // 내가 B일 때
      await UserService.updateScore(
        playerB!,               // 이긴 쪽 UID
        result: 'win',
        opponentUid: loserId,
        ownScore: playerBScore,         // 내 점수
        oppScore: playerAScore,    // 상대 점수
      );
    }

    // 패배 처리할 때도 마찬가지로 ownScore, oppScore 넘겨줌
    if (loserId != null) {
      if (loserId == playerA) {
        // A가 패배
        await UserService.updateScore(
          playerA!,
          result: 'lose',
          opponentUid: widget.playerId,
          ownScore: playerAScore,
          oppScore: playerBScore,
        );
      } else {
        // B가 패배
        await UserService.updateScore(
          playerB!,
          result: 'lose',
          opponentUid: widget.playerId,
          ownScore: playerBScore,
          oppScore: playerAScore,
        );
      }
    }
    
    final updatedDoc = await FirebaseFirestore.instance.collection('users').doc(widget.playerId).get();
    final updated = updatedDoc.data()?['score'] ?? previous;

    setState(() {
      previousScore = previous;
      finalScore = updated;
    });

    debugPrint("origin : $previousScore -> after : $finalScore");
  }

  void _listenToTurnChanges() {
    if (widget.roomId == null) return;

    FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;

      final turn = snapshot.data()?['turn'];
      if (turn == 'A' && currentTurnPlayer != Player.A) {
        setState(() => currentTurnPlayer = Player.A);
      } else if (turn == 'B' && currentTurnPlayer != Player.B) {
        setState(() => currentTurnPlayer = Player.B);
      }
    });
  }

  void _listenToOpponentMoves() {
    FirebaseFirestore.instance
      .collection('rooms')
      .doc(widget.roomId)
      .collection('moves')
      .orderBy('timestamp')
      .snapshots()
      .listen((snapshot) {
        for (var doc in snapshot.docChanges) {
          if (doc.type == DocumentChangeType.added) {
            final data = doc.doc.data();
            if (data == null) continue;

            final from = data['from'];
            final to = data['to'];
            final player = data['player'];

            final movingPiece = pieces.firstWhereOrNull((p) =>
                p.owner.name == player &&
                p.row == from[0] &&
                p.col == from[1]);

            if (movingPiece != null) {
              setState(() {
                movingPiece.row = to[0];
                movingPiece.col = to[1];
                isAwaitingWall = true;
                lastMovedRow = to[0];
                lastMovedCol = to[1];
              });
              _playPlayerSound();
            }
          }
        }
      });
  }

  Future<void> _placeInitialPieces() async {
    pieces.addAll([
      Piece(Player.A, 1, 1),
      Piece(Player.A, 5, 5),
      Piece(Player.B, 5, 1),
      Piece(Player.B, 1, 5),
    ]);
    if (isBotMode) {
      playerAName = myPlayer == Player.A ? 'You' : 'Bot';
      playerBName = myPlayer == Player.B ? 'You' : 'Bot';
    }

    // Reset placement counters so each player can add 2 more pieces
    aPiecesPlaced = 2;
    bPiecesPlaced = 2;
    currentTurnPlayer = Player.A;

    if (isBotMode) {
      // 초기 배치 단계도 사용자‑봇이 번갈아 가며 진행
      placementPhase = true;
      currentTurnPlayer = Player.A;      // 항상 A부터 배치

      // 만약 사용자가 B를 선택했다면(A가 봇), 봇이 먼저 두어야 함
      if (myPlayer != Player.A) {
        Future.delayed(botTurnDelay, _botPlaceInitialPiece);
      }
    }

    if (widget.mode != GameMode.local2P && widget.mode != GameMode.vsBot && widget.roomId != null) {
      FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .collection('placements')
        .snapshots()
        .listen((snapshot) {
          for (var doc in snapshot.docChanges) {
            if (doc.type == DocumentChangeType.added) {
              final data = doc.doc.data();
              if (data == null) continue;

              final player = data['player'];
              final row = data['row'];
              final col = data['col'];

              if (!pieces.any((p) => p.row == row && p.col == col)) {
                setState(() {
                  pieces.add(Piece(player == 'A' ? Player.A : Player.B, row, col));
                });
                _playPlayerSound();
              }
            }
          }
        });
    }

    if (widget.mode != GameMode.local2P && widget.mode != GameMode.vsBot && widget.roomId != null) {
      _listenToOpponentMoves();
      FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .collection('walls')
        .orderBy('timestamp')
        .snapshots()
        .listen((snapshot) {
          for (var doc in snapshot.docChanges) {
            if (doc.type == DocumentChangeType.added) {
              final data = doc.doc.data();
              if (data == null) continue;

              final player = data['player'];
              final cell = data['cell'];
              final direction = data['direction'];

              final wallKey1 = wallKey(cell[0], cell[1], direction);

              final delta = {
                'top': [-1, 0, 'bottom'],
                'bottom': [1, 0, 'top'],
                'left': [0, -1, 'right'],
                'right': [0, 1, 'left'],
              };

              final d = delta[direction]!;
              int neighborRow = cell[0] + d[0];
              int neighborCol = cell[1] + d[1];
              String opposite = d[2] as String;
              final wallKey2 = wallKey(neighborRow, neighborCol, opposite);

              setState(() {
                walls[wallKey1] = player == 'A' ? Player.A : Player.B;
                if (neighborRow >= 0 && neighborRow < boardSize && neighborCol >= 0 && neighborCol < boardSize) {
                  walls[wallKey2] = player == 'A' ? Player.A : Player.B;
                }

                selectedRow = null;
                selectedCol = null;
                lastMovedRow = null;
                lastMovedCol = null;
                isAwaitingWall = false;
                // currentTurnPlayer = currentTurnPlayer == Player.A ? Player.B : Player.A; // Handled by Firestore turn listener
                moveTimer?.cancel();
                remainingTime = 60;
                _startTimer();
                _checkGameEnd();
              });
              _playWallSound();
            }
          }
        });
      _listenToTurnChanges();
      _listenToPlacementPhaseChanges();
      // _listenToPlayerChanges();
    }
  }

  Future<void> _handleCellTap(int row, int col) async {
    if (!placementPhase) return;

    bool occupied = pieces.any((p) => p.row == row && p.col == col);
    if (occupied) return;

    if (widget.mode != GameMode.local2P && widget.mode != GameMode.vsBot && widget.roomId != null && myPlayer != null) {
      // 현재 턴이 내 턴인지 확인
      if (myPlayer != currentTurnPlayer) return;

      // 이미 2개 배치했는지 확인
      int placedCount = pieces.where((p) => p.owner == myPlayer).length;
      if (placedCount >= 4) return;
      _playPlayerSound();
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .collection('placements')
          .add({
        'player': myPlayer!.name,
        'row': row,
        'col': col,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 턴 전환
      final nextPlayer = myPlayer == Player.A ? 'B' : 'A';
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .update({'turn': nextPlayer});

      // 배치가 완료되었는지 확인
      final snapshot = await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .collection('placements')
          .get();
      if (snapshot.size >= 4) {
        debugPrint('🎯 배치 완료 감지 - placementPhase 업데이트 시도');
        await FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.roomId)
            .update({
              'placementPhase': false,
              'turn': 'B',
            })
            .then((_) => debugPrint('✅ placementPhase 업데이트 완료'))
            .catchError((e) => debugPrint('❌ placementPhase 업데이트 실패: $e'));
      }
    }

    if (widget.mode == GameMode.local2P || widget.mode == GameMode.vsBot) {
      if ((currentTurnPlayer == Player.A && aPiecesPlaced >= 4) ||
          (currentTurnPlayer == Player.B && bPiecesPlaced >= 4)) return;
      // Bot 모드일 때는 내 차례가 아니면 무시
      if (widget.mode == GameMode.vsBot && currentTurnPlayer != myPlayer) return;
      _playPlayerSound();
      setState(() {
        pieces.add(Piece(currentTurnPlayer, row, col));
        if (currentTurnPlayer == Player.A) {
          aPiecesPlaced++;
        } else {
          bPiecesPlaced++;
        }
      
        // 턴 전환
        currentTurnPlayer = currentTurnPlayer == Player.A ? Player.B : Player.A;

        // Bot 차례가 되면 자동 배치
        if (widget.mode == GameMode.vsBot && currentTurnPlayer != myPlayer) {
          Future.delayed(botTurnDelay, () {
            if (!gameEnded) _botPlaceInitialPiece();
          });
        }
        
        // 모든 말이 배치되면 배치 단계 종료
        if (aPiecesPlaced == 4 && bPiecesPlaced == 4) {
          placementPhase = false;
          currentTurnPlayer = Player.B;
          remainingTime = 60;
          _startTimer();
          // Bot이 B이고 이제 곧바로 이동을 시작해야 하면
          if (widget.mode == GameMode.vsBot && myPlayer != Player.B) {
            Future.delayed(botTurnDelay, () {
              if (!gameEnded) _botMakeMove();
            });
          }
        }
        
      });
    }
  }

  List<List<int>> getMovablePositions(int row, int col) {
    Set<List<int>> moves = {};

    List<List<int>> directions = [
      [-1, 0], // up
      [1, 0],  // down
      [0, -1], // left
      [0, 1],  // right
    ];

    String? wallBetween(int fromRow, int fromCol, int toRow, int toCol) {
      int dRow = toRow - fromRow;
      int dCol = toCol - fromCol;
      if (dRow == -1 && dCol == 0) return 'top';
      if (dRow == 1 && dCol == 0) return 'bottom';
      if (dRow == 0 && dCol == -1) return 'left';
      if (dRow == 0 && dCol == 1) return 'right';
      return null;
    }

    bool isBlocked(int fromRow, int fromCol, int toRow, int toCol) {
      String? dir = wallBetween(fromRow, fromCol, toRow, toCol);
      if (dir == null) return false;
      String fromKey = wallKey(fromRow, fromCol, dir);

      String opposite = dir == 'top'
          ? 'bottom'
          : dir == 'bottom'
              ? 'top'
              : dir == 'left'
                  ? 'right'
                  : 'left';
      String toKey = wallKey(toRow, toCol, opposite);

      return walls.containsKey(fromKey) || walls.containsKey(toKey);
    }

    // 1-step and 2-step straight moves
    for (var dir in directions) {
      for (int step = 1; step <= 2; step++) {
        int newRow = row + dir[0] * step;
        int newCol = col + dir[1] * step;

        if (newRow < 0 || newRow >= boardSize || newCol < 0 || newCol >= boardSize) break;
        if (pieces.any((p) => p.row == newRow && p.col == newCol)) break;

        bool blocked = false;
        for (int i = 1; i <= step; i++) {
          int interRow = row + dir[0] * i;
          int interCol = col + dir[1] * i;
          if (isBlocked(row + dir[0] * (i - 1), col + dir[1] * (i - 1), interRow, interCol)) {
            blocked = true;
            break;
          }
        }

        if (!blocked) moves.add([newRow, newCol]);
      }
    }

    // Return to same cell after moving away (e.g., up then down)
    for (var dir in directions) {
      int midRow = row + dir[0];
      int midCol = col + dir[1];

      if (midRow < 0 || midRow >= boardSize || midCol < 0 || midCol >= boardSize) continue;
      if (pieces.any((p) => p.row == midRow && p.col == midCol)) continue;
      if (isBlocked(row, col, midRow, midCol)) continue;
      if (isBlocked(midRow, midCol, row, col)) continue;

      moves.add([row, col]);
    }

    // L-shape "ㄱ" moves
    for (var dir1 in directions) {
      for (var dir2 in directions) {
        if (dir1 == dir2 || (dir1[0] + dir2[0] == 0 && dir1[1] + dir2[1] == 0)) continue;

        int midRow = row + dir1[0];
        int midCol = col + dir1[1];
        int finalRow = midRow + dir2[0];
        int finalCol = midCol + dir2[1];

        if (finalRow < 0 || finalRow >= boardSize || finalCol < 0 || finalCol >= boardSize) continue;
        if (pieces.any((p) => p.row == midRow && p.col == midCol) ||
            pieces.any((p) => p.row == finalRow && p.col == finalCol)) continue;

        if (isBlocked(row, col, midRow, midCol)) continue;
        if (isBlocked(midRow, midCol, finalRow, finalCol)) continue;

        moves.add([finalRow, finalCol]);
      }
    }

    return moves.toList();
  }

  void _handleMovePhaseTap(int row, int col) {
    // 🔒 내 차례인지 확인 (온라인 모드만)
    if (widget.mode != GameMode.local2P && widget.mode != GameMode.vsBot && currentTurnPlayer != myPlayer) return;

    if (isAwaitingWall) return;
    if (placementPhase) return;

    final selected = selectedRow != null && selectedCol != null;

    if (selected) {
      final movable = getMovablePositions(selectedRow!, selectedCol!);
      // If tapped the same piece again and no moves exist, attempt wall placement or skip if also blocked
      if (row == selectedRow && col == selectedCol && movable.isEmpty) {
        // Check if any wall placement is possible around (row, col)
        final directions = ['top', 'bottom', 'left', 'right'];
        final deltaMap = {
          'top': [-1, 0, 'bottom'],
          'bottom': [1, 0, 'top'],
          'left': [0, -1, 'right'],
          'right': [0, 1, 'left'],
        };
        bool anySpace = false;
        debugPrint("벽 체크 드가자~~~~~");

        for (var dir in directions) {
          final d = deltaMap[dir]!;
          int nr = row + (d[0] as int);
          int nc = col + (d[1] as int);
          final key = wallKey(row, col, dir);
          final neighborKey = wallKey(nr, nc, d[2] as String);
          bool inBounds = nr >= 0 && nr < boardSize && nc >= 0 && nc < boardSize;
          if (!walls.containsKey(key) && (!inBounds || !walls.containsKey(neighborKey))) {
            anySpace = true;
            break;
          }
        }
        debugPrint("벽 체크 끝났다~~~~~  : $anySpace");

        if (!anySpace) {
          // No wall space either: skip wall phase and end turn
          _handleNoWallSpace();
          return;
        }
        // Otherwise, enter wall placement mode
        setState(() {
          lastMovedRow = row;
          lastMovedCol = col;
          isAwaitingWall = true;
        });
        return;
      }
      final isValidMove = movable.any((pos) => pos[0] == row && pos[1] == col);

      if (isValidMove) {
        if (widget.mode != GameMode.local2P && widget.mode != GameMode.vsBot && widget.roomId != null) {
          final piece = pieces.firstWhere(
            (p) => p.row == selectedRow && p.col == selectedCol && p.owner == currentTurnPlayer,
          );
          _playPlayerSound();
          FirebaseFirestore.instance
              .collection('rooms')
              .doc(widget.roomId)
              .collection('moves')
              .add({
            'player': currentTurnPlayer.name,
            'from': [piece.row, piece.col],
            'to': [row, col],
            'timestamp': FieldValue.serverTimestamp(),
          });
        } else {
          // 로컬 2인 대결
          _playPlayerSound();
          setState(() {
            if (!(row == selectedRow && col == selectedCol)) {
              final piece = pieces.firstWhere(
                (p) => p.row == selectedRow && p.col == selectedCol && p.owner == currentTurnPlayer,
              );
              piece.row = row;
              piece.col = col;
            }
            lastMovedRow = row;
            lastMovedCol = col;
            selectedRow = null;
            selectedCol = null;
            isAwaitingWall = true;
          });
        }
        return;
      }
    }
  
    // 🔄 말 선택
    bool canSelect = widget.mode != GameMode.local2P
        ? currentTurnPlayer == myPlayer
        : true;

    if (canSelect && pieces.any((p) => p.row == row && p.col == col && p.owner == currentTurnPlayer)) {
      setState(() {
        selectedRow = row;
        selectedCol = col;
      });
    }
  }
  // 벽 설치 공간이 없을 때 처리용 헬퍼 메서드
  void _handleNoWallSpace() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1A17),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          AppLocalizations.of(context)!.confirmExitTitle,
          style: TextStyle(
            fontFamily: 'ChungjuKimSaeng',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFFD4AF37),
          ),
        ),
        content: Text(
         AppLocalizations.of(context)!.separatedArea,
          style: TextStyle(
            fontFamily: 'ChungjuKimSaeng',
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // 다음 턴 처리 로직 (기존 코드 유지)
              final nextPlayer = currentTurnPlayer == Player.A ? Player.B : Player.A;
              if ((widget.mode == GameMode.onlineManual || widget.mode == GameMode.onlineMatching)
                  && widget.roomId != null) {
                await FirebaseFirestore.instance
                    .collection('rooms')
                    .doc(widget.roomId)
                    .update({
                      'turn': nextPlayer.name,
                      'lastWallPlacedBy': currentTurnPlayer.name,
                    });
              }
              setState(() {
                isAwaitingWall = false;
                lastMovedRow = null;
                lastMovedCol = null;
                selectedRow = null;
                selectedCol = null;
                currentTurnPlayer = nextPlayer;
                if (isBotMode && currentTurnPlayer != myPlayer && !gameEnded) {
                  Future.delayed(botTurnDelay, () {
                    if (!gameEnded) _botMakeMove();
                  });
                }
                moveTimer?.cancel();
                remainingTime = 60;
                _startTimer();
              });
            },
            child: Text(
              AppLocalizations.of(context)!.confirm,
              style: TextStyle(
                fontFamily: 'ChungjuKimSaeng',
                color: Color(0xFFD4AF37),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Place wall in a direction from the last moved piece
  void _placeWall(String direction) {
    if (lastMovedRow == null || lastMovedCol == null) return;
    if ((direction == 'top' && lastMovedRow == 0) ||
        (direction == 'bottom' && lastMovedRow == boardSize - 1) ||
        (direction == 'left' && lastMovedCol == 0) ||
        (direction == 'right' && lastMovedCol == boardSize - 1)) {
      return;
    }

    final key = wallKey(lastMovedRow!, lastMovedCol!, direction);
    final wallOwner = currentTurnPlayer;

    final delta = {
      'top': [-1, 0, 'bottom'],
      'bottom': [1, 0, 'top'],
      'left': [0, -1, 'right'],
      'right': [0, 1, 'left'],
    };

    final d = delta[direction]!;
    int neighborRow = lastMovedRow! + (d[0] as int);
    int neighborCol = lastMovedCol! + (d[1] as int);
    String opposite = d[2] as String;
    final neighborKey = wallKey(neighborRow, neighborCol, opposite);

    bool canPlace = !walls.containsKey(key) &&
      (neighborRow >= 0 && neighborRow < boardSize && neighborCol >= 0 && neighborCol < boardSize
        ? !walls.containsKey(neighborKey)
        : true);

    if (!canPlace) return;

    if (widget.mode != GameMode.local2P && widget.roomId != null) {
      if (currentTurnPlayer != myPlayer) return;
      final nextPlayer = currentTurnPlayer == Player.A ? Player.B : Player.A;
      _playWallSound();
      FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .collection('walls')
        .add({
          'player': wallOwner.name,
          'cell': [lastMovedRow, lastMovedCol],
          'direction': direction,
          'timestamp': FieldValue.serverTimestamp(),
        });
      FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .update({
          'turn': nextPlayer.name,
          'lastWallPlacedBy': currentTurnPlayer.name,
        });

    } else {
      _playWallSound();
      setState(() {
        walls[key] = wallOwner;

        if (widget.mode != GameMode.local2P) {
          if (neighborRow >= 0 && neighborRow < boardSize &&
              neighborCol >= 0 && neighborCol < boardSize) {
            walls[neighborKey] = wallOwner;
          }
        }
        selectedRow = null;
        selectedCol = null;
        lastMovedRow = null;
        lastMovedCol = null;
        isAwaitingWall = false;
        currentTurnPlayer = currentTurnPlayer == Player.A ? Player.B : Player.A;
        // vsBot 모드에서 내 턴이 끝났으면 즉시 봇이 움직인다
        if (isBotMode && currentTurnPlayer != myPlayer && !gameEnded) {
          Future.delayed(botTurnDelay, () {
            if (!gameEnded) _botMakeMove();
          });
        }
        moveTimer?.cancel();
        remainingTime = 60;
        _startTimer();
        _checkGameEnd();
      });
    }
  }

  void _listenToPlacementPhaseChanges() {
    if (widget.roomId == null) return;

    FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;

      final data = snapshot.data();
      final remotePlacement = data?['placementPhase'];
      // if (remotePlacement != false || placementPhase != true) return;
      final turn = data?['turn'];


      if (remotePlacement == false && placementPhase == true) {
        setState(() {
          placementPhase = false;
          currentTurnPlayer = turn == 'A' ? Player.A : Player.B;
          debugPrint("🎮 배치 종료 - 다음 턴: $currentTurnPlayer");
          _startTimer();
        });
      }
      debugPrint("📦 감지된 placementPhase: $remotePlacement, turn: $turn, localPlacementPhase=$placementPhase");
    }, onError: (error) {
      debugPrint("🔥 placementPhase 리스너 오류: $error");
    });
  }

  // Helper function: animate region reveal (per-cell opacity) with wave effect (BFS depth delays)
  Future<void> _startRegionRevealAnimation(List<List<int>> region, Color color, int delayMs) async {
    // BFS to assign depth to each cell in the region
    Map<String, int> cellDepths = {};
    Queue<List<int>> queue = Queue();
    Set<String> visited = {};

    final start = region[0];
    queue.add(start);
    cellDepths['${start[0]},${start[1]}'] = 0;
    visited.add('${start[0]},${start[1]}');

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      final cr = current[0], cc = current[1];
      final currentDepth = cellDepths['$cr,$cc']!;

      for (var dir in [[-1,0],[1,0],[0,-1],[0,1]]) {
        int nr = cr + dir[0], nc = cc + dir[1];
        String key = '$nr,$nc';
        // region.contains([nr, nc]) is slow for lists, so use Set for lookup
        if (!region.any((cell) => cell[0] == nr && cell[1] == nc) || visited.contains(key)) continue;
        queue.add([nr, nc]);
        cellDepths[key] = currentDepth + 1;
        visited.add(key);
      }
    }

    for (var cell in region) {
      final key = '${cell[0]},${cell[1]}';
      final delay = (cellDepths[key] ?? 0) * (delayMs + 40);

      Future.delayed(Duration(milliseconds: delay), () {
        setState(() {
          highlightedAreas[key] = color;
          highlightedOpacity[key] = 0.0;
        });

        Timer.periodic(Duration(milliseconds: 30), (timer) {
          setState(() {
            highlightedOpacity[key] = (highlightedOpacity[key] ?? 0.0) + 0.1;
            if (highlightedOpacity[key]! >= 1.0) {
              highlightedOpacity[key] = 1.0;
              timer.cancel();
            }
          });
        });
      });
    }

    // Wait until the farthest cell's animation ends before continuing
    final maxDepth = cellDepths.values.fold(0, max);
    await Future.delayed(Duration(milliseconds: (maxDepth + 1) * delayMs + 500));
  }

  // 게임 종료 판정: 모든 영역이 한 플레이어의 말만 포함하고, 2개 이상 영역이면 종료
  Future<void> _checkGameEnd() async {
    if (placementPhase) return;

    List<List<bool>> visited = List.generate(boardSize, (_) => List.filled(boardSize, false));
    List<List<List<int>>> regions = [];

    void dfs(int r, int c, List<List<int>> region) {
      visited[r][c] = true;
      region.add([r, c]);

      for (var dir in [
        [-1, 0],
        [1, 0],
        [0, -1],
        [0, 1]
      ]) {
        int nr = r + dir[0];
        int nc = c + dir[1];
        if (nr < 0 || nr >= boardSize || nc < 0 || nc >= boardSize) continue;
        if (visited[nr][nc]) continue;

        String? dirStr;
        if (dir[0] == -1) dirStr = 'top';
        if (dir[0] == 1) dirStr = 'bottom';
        if (dir[1] == -1) dirStr = 'left';
        if (dir[1] == 1) dirStr = 'right';

        String fromKey = wallKey(r, c, dirStr!);
        String opposite = dirStr == 'top'
            ? 'bottom'
            : dirStr == 'bottom'
                ? 'top'
                : dirStr == 'left'
                    ? 'right'
                    : 'left';
        String toKey = wallKey(nr, nc, opposite);

        if (walls.containsKey(fromKey) || walls.containsKey(toKey)) continue;

        dfs(nr, nc, region);
      }
    }

    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        if (!visited[r][c]) {
          List<List<int>> region = [];
          dfs(r, c, region);
          regions.add(region);
        }
      }
    }

    // Each region must contain only one player's pieces or none
    bool hasMixedRegion = false;
    for (var region in regions) {
      Set<Player> players = {};
      for (var cell in region) {
        final piece = pieces.firstWhereOrNull(
            (p) => p.row == cell[0] && p.col == cell[1]);
        if (piece != null) players.add(piece.owner);
      }
      if (players.length > 1) {
        hasMixedRegion = true;
        break;
      }
    }
    int aCount = 0;
    int bCount = 0;
    if (regions.length > 1 && !hasMixedRegion) {
      // ---- Mark game as ended immediately to stop any further bot scheduling ----
      gameEnded = true;
      moveTimer?.cancel();
      // Animated highlight logic before result
      highlightedAreas.clear();
      highlightedOpacity.clear();
      int delayPerCell = 40;
      for (var region in regions) {
        Set<Player> regionPlayers = {};
        for (var cell in region) {
          final piece = pieces.firstWhereOrNull(
              (p) => p.row == cell[0] && p.col == cell[1]);
          if (piece != null) regionPlayers.add(piece.owner);
        }
        Color? color;
        if (regionPlayers.contains(Player.A)) {
          color = currentTheme.playerAColor;
        } else if (regionPlayers.contains(Player.B)) {
          color = currentTheme.playerBColor;
        }
        if (color != null) {
          await _startRegionRevealAnimation(region, color, delayPerCell);
        }
      }
      // Wait before showing result
      await Future.delayed(Duration(milliseconds: 200));

      for (var region in regions) {
        Set<Player> regionPlayers = {};
        for (var cell in region) {
          final piece = pieces.firstWhereOrNull(
              (p) => p.row == cell[0] && p.col == cell[1]);
          if (piece != null) regionPlayers.add(piece.owner);
        }

        if (regionPlayers.contains(Player.A)) {
          aCount += region.length;
        } else if (regionPlayers.contains(Player.B)) {
          bCount += region.length;
        }
      }

      if (widget.mode == GameMode.local2P) {
        setState(() {
          // "영역이 분리되었습니다." 부분은 ARB의 separatedArea 키에서 가져옵니다
          gameResultText =
            '${AppLocalizations.of(context)!.separatedArea}\n($aCount vs $bCount)';
          updatedAcount = aCount;
          updatedBcount = bCount;
        });
      } else {
        debugPrint("A Count : $aCount");
        debugPrint("B Count : $bCount");
        // 승리/무승부 텍스트도 ARB 키를 추가해서 가져옵니다
        final winnerText = aCount > bCount
            ? '$playerAName ${AppLocalizations.of(context)!.victory} ($aCount vs $bCount)'
            : bCount > aCount
                ? '$playerBName ${AppLocalizations.of(context)!.victory} ($bCount vs $aCount)'
                : '${AppLocalizations.of(context)!.draw} ($aCount vs $bCount)';
        setState(() {
          gameResultText =
            '${AppLocalizations.of(context)!.separatedArea}\n$winnerText';
          updatedAcount = aCount;
          updatedBcount = bCount;
        });
      }
      moveTimer?.cancel();
      // ✅ 점수 갱신 (온라인 모드인 경우만)
      if (widget.mode == GameMode.onlineMatching && widget.playerId != null && finalScore == null) {
        final roomDoc = await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).get();
        final playerA = roomDoc.data()?['playerA'];
        final playerB = roomDoc.data()?['playerB'];

        final opponentUid = (widget.playerId == playerA) ? playerB : playerA;

        final doc = await FirebaseFirestore.instance.collection('users').doc(widget.playerId).get();

        // 예: A가 이긴 경우
        if (aCount > bCount) {
          // 현재 내가 A인지 확인
          final amIWinner = (widget.playerId == playerA);
          await UserService.updateScore(
            widget.playerId!,
            result: amIWinner ? 'win' : 'lose',
            opponentUid: opponentUid,
            ownScore: amIWinner ? playerAScore : playerBScore,
            oppScore: amIWinner ? playerBScore : playerAScore,
          );
        }
        // 예: B가 이긴 경우
        else if (bCount > aCount) {
          final amIWinner = (widget.playerId == playerB);
          await UserService.updateScore(
            widget.playerId!,
            result: amIWinner ? 'win' : 'lose',
            opponentUid: opponentUid,
            ownScore: amIWinner ? playerBScore : playerAScore,
            oppScore: amIWinner ? playerAScore : playerBScore,
          );
        }
        // 예: 무승부인 경우
        else {
          await UserService.updateScore(
            widget.playerId!,
            result: 'draw',
            opponentUid: opponentUid,
            ownScore: (widget.playerId == playerA ? playerAScore : playerBScore),
            oppScore: (widget.playerId == playerA ? playerBScore : playerAScore),
          );
        }
        final updatedDoc = await FirebaseFirestore.instance.collection('users').doc(widget.playerId).get();
        setState(() {
          previousScore = doc.data()?['score'] ?? 1000;
          finalScore = updatedDoc.data()?['score'] ?? previousScore;
        });
      }
    }
    
  }

  Future<void> _cleanupOnlineRoom() async {
    if (widget.mode == GameMode.local2P || widget.roomId == null) return;

    try {
      // 방 삭제
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .delete();
    } catch (e) {
      debugPrint('Failed to delete room: $e');
    }
  }

  int _countConnectedArea(Player player) {
    Set<String> visited = {};
    int count = 0;

    void dfs(int r, int c) {
      String key = '$r,$c';
      if (visited.contains(key)) return;
      visited.add(key);
      count++;

      for (var dir in [
        [-1, 0],
        [1, 0],
        [0, -1],
        [0, 1]
      ]) {
        int nr = r + dir[0];
        int nc = c + dir[1];
        if (nr < 0 || nr >= boardSize || nc < 0 || nc >= boardSize) continue;

        String? dirStr;
        if (dir[0] == -1) dirStr = 'top';
        if (dir[0] == 1) dirStr = 'bottom';
        if (dir[1] == -1) dirStr = 'left';
        if (dir[1] == 1) dirStr = 'right';

        String fromKey = wallKey(r, c, dirStr!);
        String opposite = dirStr == 'top'
            ? 'bottom'
            : dirStr == 'bottom'
                ? 'top'
                : dirStr == 'left'
                    ? 'right'
                    : 'left';
        String toKey = wallKey(nr, nc, opposite);

        if (walls.containsKey(fromKey) || walls.containsKey(toKey)) continue;
        // Check if there is a piece of player at (nr, nc) or it's empty
        final piece = pieces.firstWhereOrNull(
            (p) => p.row == nr && p.col == nc);
        if (piece != null && piece.owner != player) continue;

        dfs(nr, nc);
      }
    }

    for (final p in pieces.where((x) => x.owner == player)) {
      dfs(p.row, p.col);
    }

    return count;
  }

  Color _getCellColor(Player player, int row, int col) {
    final key = '$row,$col';
    if (highlightedAreas.containsKey(key)) {
      final base = highlightedAreas[key]!;
      final alpha = highlightedOpacity[key] ?? 0.0;
      return base.withOpacity(alpha);
    }
    if (selectedRow == row && selectedCol == col) return Colors.yellow.shade200;

    final movable = (selectedRow != null && selectedCol != null)
        ? getMovablePositions(selectedRow!, selectedCol!)
        : [];

    if (movable.any((pos) => pos[0] == row && pos[1] == col)) {
      return Colors.white70.withOpacity(0.5);
    }

    // Remove piece color logic from background
    return Colors.transparent;
  }

  // BorderSide wallOrDefault(String direction, int row, int col) {
  //   final key = wallKey(row, col, direction);
  //   if (walls.containsKey(key)) {
  //     final owner = walls[key];
  //     final color = owner == Player.A
  //         ? Colors.red
  //         : owner == Player.B
  //             ? Colors.blue
  //             : Colors.black;
  //     return BorderSide(width: 4, color: color);
  //   } else {
  //     return BorderSide(color: Colors.black);
  //   }
  // }

  // Helper method to convert cell row/col to pixel offset
  Offset _cellOffset(int row, int col, double cellSize) {
    return Offset(col * cellSize, row * cellSize);
  }
  
  Future<bool> _confirmAndLeave() async {
    final mode = widget.mode;
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1A17),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          AppLocalizations.of(context)!.confirm,
          style: TextStyle(
            fontFamily: 'ChungjuKimSaeng',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFFD4AF37),
          ),
        ),

          content: Text(
         mode != GameMode.local2P
             ? AppLocalizations.of(context)!.confirmExitContentOnline
             : AppLocalizations.of(context)!.confirmExitContentLocal,
          style: TextStyle(
            fontFamily: 'ChungjuKimSaeng',
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              AppLocalizations.of(context)!.no,
              style: TextStyle(
                fontFamily: 'ChungjuKimSaeng',
                color: Colors.white,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child:  Text(
              AppLocalizations.of(context)!.yes,
              style: TextStyle(
                fontFamily: 'ChungjuKimSaeng',
                color: Color(0xFFD4AF37),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    if (shouldLeave != true) return false;
    
    // call existing cleanup and pop logic
    return await _handleBackNavigation();
  }

  @override
  void dispose() {
    highlightController.dispose();
    super.dispose();
  }

  Future<bool> _handleBackNavigation() async {
    if (widget.mode != GameMode.local2P && widget.roomId != null && widget.playerId != null) {
      final roomRef = FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);

      // 플레이어 배열에서 현재 유저 제거
      await roomRef.update({
        'players': FieldValue.arrayRemove([widget.playerId]),
      });

      final snapshot = await roomRef.get();
      final players = List<String>.from(snapshot.data()?['players'] ?? []);

      // players가 비어 있으면 서브 컬렉션과 문서 전체 삭제
      if (players.isEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        debugPrint("players가 비어있습니다. 삭제를 진행합니다.");
        // 서브 컬렉션 문서 삭제
        for (final collection in ['placements', 'moves', 'walls']) {
          final subColRef = roomRef.collection(collection);
          final docs = await subColRef.get();
          for (final doc in docs.docs) {
            batch.delete(doc.reference);
          }
        }
        debugPrint("서브컬렉션 삭제 완료");
        // room 문서 삭제
        batch.delete(roomRef);
        await batch.commit();
        debugPrint("방 문서 삭제 완료");

      }
    }

    return true; // 뒤로 가기 허용
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _confirmAndLeave,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: () {
            final isEn = Localizations.localeOf(context).languageCode == 'en';
            if (widget.mode == GameMode.local2P) {
              return isEn
                  ? const Text('2P', style: TextStyle(fontFamily: 'ChungjuKimSaeng',fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black))
                  : Image.asset('lib/img/text/text_2p_black.png', width: 100);
            } else if (widget.mode == GameMode.vsBot) {
              return isEn
                  ? const Text('AI', style: TextStyle(fontFamily: 'ChungjuKimSaeng',fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black))
                  : Image.asset('lib/img/text/text_ai_black.png', width: 100);
            } else {
              return isEn
                  ? const Text('Online Match', style: TextStyle(fontFamily: 'ChungjuKimSaeng',fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black))
                  : Image.asset('lib/img/text/text_online_black.png', width: 100);
            }
          }(),
        ),
        body: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Adapt board size to available width and height
                  // cell 1 edge 0.x 7.x
                  double maxSide = min(constraints.maxWidth, constraints.maxHeight * 0.6);
                  double boardSizePx = maxSide;
                  double edgeRatio = 0.35;
                  double cellSize = boardSizePx / (boardSize+ 2*edgeRatio);
                  // padding inside the board image for border alignment
                  double gridPadding = cellSize * edgeRatio; // adjust factor as needed


                  // New layout: top/bottom LED timers and conditional display
                  return SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      // Scoreboard 호출 직전에
                      if (widget.mode != GameMode.local2P)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Left side: Player A nickname and image, safely truncated, with score
                              Flexible(
                                flex: 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Image.asset(
                                          currentTheme.playerAImagePath,
                                          width: 24, height: 24,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            playerAName!,
                                            style: TextStyle(
                                              fontFamily: 'ChungjuKimSaeng',
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Color.fromARGB(255, 13, 11, 4),
                                              shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (playerAScore != null)
                                      Text(
                                        '▶︎ $playerAScore',
                                        style: TextStyle(
                                              fontFamily: 'ChungjuKimSaeng',
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Color.fromARGB(255, 13, 11, 4),
                                              shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                                            ),
                                      ),
                                  ],
                                ),
                              ),
                              // Insert "vs" text in the middle
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  'vs',
                                  style: TextStyle(
                                    fontFamily: 'ChungjuKimSaeng',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E1A17),
                                    shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                                  ),
                                ),
                              ),
                              // Right side: Player B nickname and image, safely truncated and right aligned, with score
                              Flexible(
                                flex: 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            playerBName!,
                                            style: TextStyle(
                                              fontFamily: 'ChungjuKimSaeng',
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Color.fromARGB(255, 13, 11, 4),
                                              shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.right,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Image.asset(
                                          currentTheme.playerBImagePath,
                                          width: 24, height: 24,
                                        ),
                                      ],
                                    ),
                                    if (playerBScore != null)
                                      Text(
                                        '$playerBScore ◀︎',
                                        style: TextStyle(
                                              fontFamily: 'ChungjuKimSaeng',
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Color.fromARGB(255, 13, 11, 4),
                                              shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                                            ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      Center(
                        child: SizedBox(
                          width: boardSizePx * 0.7,
                          child: Scoreboard(
                            seconds: remainingTime,
                            instruction: placementPhase
                                ? AppLocalizations.of(context)!.placementInstruction
                                : isAwaitingWall
                                    ? AppLocalizations.of(context)!.wallInstruction
                                    : AppLocalizations.of(context)!.moveInstruction,
                            mode: widget.mode,
                            currentTurn: currentTurnPlayer,
                            myPlayer: myPlayer,
                            selectedThemeIndex: widget.selectedThemeIndex,
                          ),
                        ),
                      ),
                      SizedBox(height: constraints.maxHeight * 0.05),
                      // Game board
                      Center(
                        child: SizedBox(
                          width: boardSizePx,
                          height: boardSizePx,
                          child: Stack(
                            children: [
                              // 1) 배경 이미지: 보드 사이즈 딱 맞춤
                              Positioned.fill(
                                child: Image.asset(
                                  'lib/img/gameboard.png',
                                  fit: BoxFit.fill,
                                ),
                              ),
                              // 2) 그리드(칸)과 기타 오버레이
                              Padding(
                                padding: EdgeInsets.all(gridPadding),
                                child: Builder(
                                  builder: (context) {
                                    List<Widget> stackChildren = [];
                                    // Background grid cells
                                    for (int row = 0; row < boardSize; row++) {
                                      for (int col = 0; col < boardSize; col++) {
                                        stackChildren.add(Positioned(
                                          left: col * cellSize,
                                          top: row * cellSize,
                                          width: cellSize,
                                          height: cellSize,
                                          child: GestureDetector(
                                            onTap: () {
                                              if (placementPhase) {
                                                _handleCellTap(row, col);
                                              } else {
                                                _handleMovePhaseTap(row, col);
                                              }
                                            },
                                            child: AnimatedContainer(
                                              duration: Duration(milliseconds: 250),
                                              curve: Curves.easeInOut,
                                              decoration: BoxDecoration(
                                                color: _getCellColor(board[row][col], row, col),
                                                // border: Border.all(color: Colors.grey.shade300, width: 1),
                                              ),
                                            ),
                                          ),
                                        ));
                                      }
                                    }
                                    // Render walls as images
                                    for (var key in walls.keys) {
                                      final parts = key.split(':');
                                      final pos = parts[0].split(',');
                                      final direction = parts[1];
                                      final row = int.parse(pos[0]);
                                      final col = int.parse(pos[1]);
                                      final owner = walls[key];

                                      String imagePath = '';
                                      bool isRowWall = direction == 'top' || direction == 'bottom';
                                      if (isRowWall) {
                                        imagePath = owner == Player.A
                                            ? currentTheme.wallAColImagePath
                                            : currentTheme.wallBColImagePath;
                                      } else {
                                        imagePath = owner == Player.A
                                            ? currentTheme.wallARowImagePath
                                            : currentTheme.wallBRowImagePath;
                                      }

                                      double left = col * cellSize;
                                      double top = row * cellSize;
                                      double width = isRowWall ? cellSize : 6;
                                      double height = isRowWall ? 6 : cellSize;

                                      if (direction == 'top') {
                                        top -= height / 2;
                                        left += (cellSize - width) / 2;
                                      } else if (direction == 'bottom') {
                                        top += cellSize - height / 2;
                                        left += (cellSize - width) / 2;
                                      } else if (direction == 'left') {
                                        left -= width / 2;
                                        top += (cellSize - height) / 2;
                                      } else if (direction == 'right') {
                                        left += cellSize - width / 2;
                                        top += (cellSize - height) / 2;
                                      }

                                      stackChildren.add(Positioned(
                                        left: left,
                                        top: top,
                                        width: width,
                                        height: height,
                                        child: Image.asset(imagePath, fit: BoxFit.fill),
                                      ));
                                    }
                                    // Animated pieces
                                    for (final piece in pieces) {
                                      stackChildren.add(AnimatedPositioned(
                                        duration: Duration(milliseconds: 300),
                                        left: piece.col * cellSize,
                                        top: piece.row * cellSize,
                                        width: cellSize,
                                        height: cellSize,
                                        child: GestureDetector(
                                          onTap: () {
                                            if (!placementPhase) _handleMovePhaseTap(piece.row, piece.col);
                                          },
                                          child: Container(
                                            margin: EdgeInsets.all(cellSize * 0.2),
                                            decoration: isBotMode &&
                                                    piece.row == botPrevRow &&
                                                    piece.col == botPrevCol &&
                                                    ((myPlayer == Player.A && piece.owner == Player.B) ||
                                                        (myPlayer == Player.B && piece.owner == Player.A))
                                                ? BoxDecoration(
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.yellowAccent.withOpacity(0.8),
                                                        blurRadius: 12,
                                                        spreadRadius: 4,
                                                      ),
                                                    ],
                                                  )
                                                : null,
                                            child: Image.asset(
                                              piece.owner == Player.A
                                                  ? currentTheme.playerAImagePath
                                                  : currentTheme.playerBImagePath,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                      ));
                                    }
                                    // Show directional wall buttons on valid directions from last moved piece
                                    if (!placementPhase && isAwaitingWall && lastMovedRow != null && lastMovedCol != null &&
                                        (widget.mode == GameMode.local2P || currentTurnPlayer == myPlayer)) {
                                      final delta = {
                                        'top': [-1, 0, 'bottom'],
                                        'bottom': [1, 0, 'top'],
                                        'left': [0, -1, 'right'],
                                        'right': [0, 1, 'left'],
                                      };
                                      for (final entry in delta.entries) {
                                        final dir = entry.key;
                                        final d = entry.value;
                                        // Skip edge walls
                                        if ((dir == 'top' && lastMovedRow == 0) ||
                                            (dir == 'bottom' && lastMovedRow == boardSize - 1) ||
                                            (dir == 'left' && lastMovedCol == 0) ||
                                            (dir == 'right' && lastMovedCol == boardSize - 1)) {
                                          continue;
                                        }
                                        final nr = lastMovedRow! + (d[0] as int);
                                        final nc = lastMovedCol! + (d[1] as int);
                                        final wallKeySelf = wallKey(lastMovedRow!, lastMovedCol!, dir);
                                        final wallKeyNeighbor = wallKey(nr, nc, d[2] as String);
                                        final isValid = !walls.containsKey(wallKeySelf) &&
                                            (nr < 0 || nr >= boardSize || nc < 0 || nc >= boardSize || !walls.containsKey(wallKeyNeighbor));
                                        if (!isValid) continue;

                                        Offset position = _cellOffset(lastMovedRow!, lastMovedCol!, cellSize);
                                        double btnSize = cellSize * 0.4;
                                        double left = position.dx;
                                        double top = position.dy;

                                        if (dir == 'top') {
                                          left += (cellSize - btnSize) / 2;
                                          top -= btnSize / 2;
                                        } else if (dir == 'bottom') {
                                          left += (cellSize - btnSize) / 2;
                                          top += cellSize - btnSize / 2;
                                        } else if (dir == 'left') {
                                          top += (cellSize - btnSize) / 2;
                                          left -= btnSize / 2;
                                        } else if (dir == 'right') {
                                          top += (cellSize - btnSize) / 2;
                                          left += cellSize - btnSize / 2;
                                        }

                                        stackChildren.add(Positioned(
                                          left: left,
                                          top: top,
                                          width: btnSize,
                                          height: btnSize,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                              backgroundColor: Colors.black54,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                            ),
                                            onPressed: () => _placeWall(dir),
                                            child: Icon(Icons.add, size: btnSize * 0.6, color: Colors.white),
                                          ),
                                        ));
                                      }
                                    }
                                    // Show game result overlay if exists
                                    if (gameResultText != null) {
                                      stackChildren.add(Positioned.fill(
                                        child: Container(
                                          alignment: Alignment.center,
                                          color: Colors.black.withOpacity(0.5),
                                          child: Builder(
                                            builder: (context) {
                                              // --- Overlay for result: local2P and online modes ---
                                              // If exit-victory text, show it directly
                                              if (gameResultText == AppLocalizations.of(context)!.opponentLeft) {
                                                return Center(
                                                  child: Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        gameResultText!,
                                                        style: const TextStyle(
                                                          fontFamily: 'ChungjuKimSaeng',
                                                          fontSize: 24,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                        textAlign: TextAlign.center,
                                                      ),
                                                      const SizedBox(height: 16),
                                                      if (widget.mode == GameMode.onlineMatching && previousScore != null && finalScore != null)
                                                        TweenAnimationBuilder<double>(
                                                          tween: Tween<double>(
                                                            begin: previousScore!.toDouble(),
                                                            end: finalScore!.toDouble(),
                                                          ),
                                                          duration: const Duration(milliseconds: 1200),
                                                          builder: (context, value, child) {
                                                            final delta = finalScore! - previousScore!;
                                                            final deltaText = delta >= 0 ? '+$delta' : '$delta';
                                                            return Column(
                                                              children: [
                                                                Text(
                                                                  AppLocalizations.of(context)!.scoreLabel(value.toInt()),
                                                                  style: const TextStyle(
                                                                    fontSize: 20,
                                                                    color: Colors.yellowAccent,
                                                                    fontWeight: FontWeight.bold,
                                                                  ),
                                                                ),
                                                                const SizedBox(height: 4),
                                                                Text(
                                                                  '($deltaText)',
                                                                  style: TextStyle(
                                                                    fontSize: 16,
                                                                    color: delta >= 0 ? const Color.fromARGB(255, 27, 189, 122) : Colors.redAccent,
                                                                    fontWeight: FontWeight.bold,
                                                                  ),
                                                                ),
                                                              ],
                                                            );
                                                          },
                                                        ),
                                                      if (widget.mode == GameMode.onlineMatching)
                                                        const SizedBox(height: 16),
                                                      ElevatedButton(
                                                        onPressed: () async {
                                                          final shouldPop = await _handleBackNavigation();
                                                          if (shouldPop && mounted) {
                                                            Navigator.pop(context);
                                                          }
                                                        },
                                                        child : Text(
                                                          AppLocalizations.of(context)!.gameOverButton,
                                                          style: const TextStyle(fontFamily: 'ChungjuKimSaeng'),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }
                                              // Local 2P: keep legacy block
                                              if (widget.mode == GameMode.local2P && gameResultText != null) {
                                                return Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Image.asset(
                                                          updatedAcount > updatedBcount
                                                              ? currentTheme.playerAImagePath
                                                              : currentTheme.playerBImagePath,
                                                          width: 36,
                                                          height: 36,
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Text(
                                                          updatedAcount == updatedBcount ? AppLocalizations.of(context)!.draw : AppLocalizations.of(context)!.victory,
                                                          style: TextStyle(
                                                            fontSize: 24,
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 12),
                                                    Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Image.asset(
                                                          currentTheme.playerAImagePath,
                                                          width: 28,
                                                          height: 28,
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          '$updatedAcount',
                                                          style: TextStyle(fontSize: 20, color: Colors.white),
                                                        ),
                                                        const SizedBox(width: 10),
                                                        Text(
                                                          'vs',
                                                          style: TextStyle(fontSize: 20, color: Colors.white),
                                                        ),
                                                        const SizedBox(width: 10),
                                                        Text(
                                                          '$updatedBcount',
                                                          style: TextStyle(fontSize: 20, color: Colors.white),
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Image.asset(
                                                          currentTheme.playerBImagePath,
                                                          width: 28,
                                                          height: 28,
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 16),
                                                    ElevatedButton(
                                                      onPressed: () async {
                                                        final shouldPop = await _handleBackNavigation();
                                                        if (shouldPop && mounted) {
                                                          Navigator.pop(context);
                                                        }
                                                      },
                                                      child : Text(
                                                          AppLocalizations.of(context)!.gameOverButton,
                                                          style: const TextStyle(fontFamily: 'ChungjuKimSaeng'),
                                                        ),
                                                    ),
                                                  ],
                                                );
                                              }
                                              // --- Online mode: custom result overlay ---
                                              if (widget.mode != GameMode.local2P) {
                                              
                                                final winner = updatedAcount > updatedBcount ? Player.A : Player.B;
                                                final winnerName = updatedAcount > updatedBcount ? playerAName : playerBName;
                                                final winnerImage = updatedAcount > updatedBcount
                                                    ? currentTheme.playerAImagePath
                                                    : currentTheme.playerBImagePath;
                                                return Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Image.asset(winnerImage, width: 36, height: 36),
                                                        const SizedBox(width: 8),
                                                        Text(
                                                          '$winnerName ${AppLocalizations.of(context)!.victory}',
                                                          style: TextStyle(
                                                            fontSize: 24,
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 12),
                                                    Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Image.asset(currentTheme.playerAImagePath, width: 28, height: 28),
                                                        const SizedBox(width: 4),
                                                        Text('$updatedAcount', style: TextStyle(fontSize: 20, color: Colors.white)),
                                                        const SizedBox(width: 10),
                                                        Text('vs', style: TextStyle(fontSize: 20, color: Colors.white)),
                                                        const SizedBox(width: 10),
                                                        Text('$updatedBcount', style: TextStyle(fontSize: 20, color: Colors.white)),
                                                        const SizedBox(width: 4),
                                                        Image.asset(currentTheme.playerBImagePath, width: 28, height: 28),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 16),
                                                    if (widget.mode == GameMode.onlineMatching && finalScore != null && previousScore != null)
                                                      TweenAnimationBuilder<double>(
                                                        tween: Tween<double>(
                                                          begin: previousScore!.toDouble(),
                                                          end: finalScore!.toDouble(),
                                                        ),
                                                        duration: Duration(milliseconds: 1500),
                                                        builder: (context, value, _) {
                                                          final delta = finalScore! - previousScore!;
                                                          final deltaText = delta >= 0 ? '+$delta' : '$delta';
                                                          return Row(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              Text(
                                                                AppLocalizations.of(context)!.scoreLabel(value.toInt()),
                                                                style: TextStyle(
                                                                  fontSize: 20,
                                                                  color: Colors.yellowAccent,
                                                                  fontWeight: FontWeight.bold,
                                                                ),
                                                              ),
                                                              Text(
                                                                '($deltaText)',
                                                                style: TextStyle(
                                                                  fontSize: 16,
                                                                  color: delta >= 0 ? const Color.fromARGB(255, 27, 189, 122) : Colors.redAccent,
                                                                  fontWeight: FontWeight.bold,
                                                                ),
                                                              ),
                                                            ],
                                                          );
                                                        },
                                                      ),
                                                    const SizedBox(height: 16),
                                                    ElevatedButton(
                                                      onPressed: () async {
                                                        final shouldPop = await _handleBackNavigation();
                                                        if (shouldPop && mounted) {
                                                          Navigator.pop(context);
                                                        }
                                                      },
                                                      child : Text(
                                                          AppLocalizations.of(context)!.gameOverButton,
                                                          style: const TextStyle(fontFamily: 'ChungjuKimSaeng'),
                                                        ),
                                                    ),
                                                  ],
                                                );
                                              }
                                              // --- Default: original block (should not usually reach here) ---
                                              return Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    gameResultText!,
                                                    style: TextStyle(
                                                      fontSize: 24,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  const SizedBox(height: 16),
                                                  ElevatedButton(
                                                    onPressed: () async {
                                                      final shouldPop = await _handleBackNavigation();
                                                      if (shouldPop && mounted) {
                                                        Navigator.pop(context);
                                                      }
                                                    },
                                                    child : Text(
                                                          AppLocalizations.of(context)!.gameOverButton,
                                                          style: const TextStyle(fontFamily: 'ChungjuKimSaeng'),
                                                        ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        ),
                                      ));
                                    }
                                    return Stack(children: stackChildren);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Bottom color bar
                      // Container(
                      //   width: boardSizePx,
                      //   height: 24,
                      //   color: currentTurnPlayer == Player.A
                      //       ? Colors.red.withOpacity(0.4)
                      //       : Colors.blue.withOpacity(0.4),
                      // ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // (Wall overlay buttons are now shown directly on the board as overlays.)
          ],
        ),
      ),
    );
  }

  void _resetGame() {
    setState(() {
      pieces.clear();
      walls.clear();
      currentTurnPlayer = Player.A;
      aPiecesPlaced = 2;
      bPiecesPlaced = 2;
      placementPhase = true;
      selectedRow = null;
      selectedCol = null;
      lastMovedRow = null;
      lastMovedCol = null;
      isAwaitingWall = false;
      gameResultText = null;
      highlightedAreas.clear();
      highlightedOpacity.clear();
      highlightController.reset();
      moveTimer?.cancel();
      _placeInitialPieces();
    });
  }

  // Place a random piece during the placement phase if time runs out
  void _placeRandomInitialPiece() async {
    if (widget.mode != GameMode.local2P && widget.roomId != null && myPlayer != null) {
      int placedCount = pieces.where((p) => p.owner == myPlayer).length;
      if (placedCount >= 4) return;

      List<List<int>> emptyCells = [];
      for (int r = 0; r < boardSize; r++) {
        for (int c = 0; c < boardSize; c++) {
          if (!pieces.any((p) => p.row == r && p.col == c)) {
            emptyCells.add([r, c]);
          }
        }
      }

      if (emptyCells.isEmpty) return;
      final randomCell = (emptyCells..shuffle()).first;

      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .collection('placements')
          .add({
        'player': myPlayer!.name,
        'row': randomCell[0],
        'col': randomCell[1],
        'timestamp': FieldValue.serverTimestamp(),
      });

      final nextPlayer = myPlayer == Player.A ? 'B' : 'A';
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .update({'turn': nextPlayer});

      final snapshot = await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .collection('placements')
          .get();
      if (snapshot.size >= 4) {
        await FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.roomId)
            .update({
          'placementPhase': false,
          'turn': 'B',
        });
      }
    }
  }
}

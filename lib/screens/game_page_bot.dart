part of 'game_page.dart';


/// ---------- Bot (AI) logic extracted ----------
class _BotMove {
  final Piece piece;
  final int toRow;
  final int toCol;
  _BotMove(this.piece, this.toRow, this.toCol);
}

/// Simple snapshot for quick heuristic evaluation
class _BotSnapshot {
  List<Piece> pieces;
  Map<String, Player> walls;
  _BotSnapshot(this.pieces, this.walls);

  _BotSnapshot clone() {
    // Deep‑copy pieces to avoid mutation
    final newPieces = pieces
        .map((p) => Piece(p.owner, p.row, p.col))
        .toList();
    final newWalls = Map<String, Player>.from(walls);
    return _BotSnapshot(newPieces, newWalls);
  }
}

/// Area size reachable by `player` in given snapshot
int _countArea(_BotSnapshot snap, Player player) {
  const size = _GamePageState.boardSize;
  final visited = List.generate(size, (_) => List.filled(size, false));
  final boardPieces =
      List.generate(size, (_) => List<Player>.filled(size, Player.none));

  for (var p in snap.pieces) {
    boardPieces[p.row][p.col] = p.owner;
  }

  int area = 0;
  void dfs(int r, int c) {
    if (visited[r][c]) return;
    visited[r][c] = true;
    area++;
    const dirs = [
      [-1, 0, 'top', 'bottom'],
      [1, 0, 'bottom', 'top'],
      [0, -1, 'left', 'right'],
      [0, 1, 'right', 'left'],
    ];
    for (var d in dirs) {
      final nr = r + (d[0] as int);
      final nc = c + (d[1] as int);
      if (nr < 0 || nr >= size || nc < 0 || nc >= size) continue;
      final k1 = '${r},${c}:${d[2]}';
      final k2 = '${nr},${nc}:${d[3]}';
      if (snap.walls.containsKey(k1) || snap.walls.containsKey(k2)) continue;
      final occ = boardPieces[nr][nc];
      if (occ != Player.none && occ != player) continue;
      dfs(nr, nc);
    }
  }

  for (var p in snap.pieces.where((e) => e.owner == player)) {
    dfs(p.row, p.col);
  }
  return area;
}

extension BotLogic on _GamePageState {
  bool get _isDone => gameEnded;   // ➍ 추가
  Player get _botPlayer => (myPlayer == Player.A) ? Player.B : Player.A;


  int _countRegionArea(_BotSnapshot snap, int startRow, int startCol, Player player) {
    const size = _GamePageState.boardSize;
    final visited = List.generate(size, (_) => List.filled(size, false));
    final boardPieces =
        List.generate(size, (_) => List<Player>.filled(size, Player.none));
    for (var p in snap.pieces) {
      boardPieces[p.row][p.col] = p.owner;
    }

    int area = 0;
    void dfs(int r, int c) {
      if (visited[r][c]) return;
      visited[r][c] = true;
      area++;
      const dirs = [
        [-1, 0, 'top', 'bottom'],
        [1, 0, 'bottom', 'top'],
        [0, -1, 'left', 'right'],
        [0, 1, 'right', 'left'],
      ];
      for (var d in dirs) {
        final nr = r + (d[0] as int);
        final nc = c + (d[1] as int);
        if (nr < 0 || nr >= size || nc < 0 || nc >= size) continue;
        final k1 = '${r},${c}:${d[2]}';
        final k2 = '${nr},${nc}:${d[3]}';
        if (snap.walls.containsKey(k1) || snap.walls.containsKey(k2)) continue;
        final occ = boardPieces[nr][nc];
        // 빈 칸 혹은 같은 player 말만 연결
        if (occ != Player.none && occ != player) continue;
        dfs(nr, nc);
      }
    }

    dfs(startRow, startCol);
    return area;
  }
  /// ------------------------------------------------------------
  ///  Quick trap finder
  ///  If there exists a move+wall that shrinks opponent territory
  ///  to 1~4 cells, return it immediately so the bot plays it
  ///  without running the full search.
  /// ------------------------------------------------------------
  Map<String, dynamic>? _findQuickTrap(_BotSnapshot snap) {
    // --- 0) baseline region sizes for *each* opponent piece ---
    final Map<String, int> baseRegion = {};
    for (final opp in snap.pieces.where((p) => p.owner == myPlayer)) {
      final key = '${opp.row},${opp.col}';
      baseRegion[key] =
          _countRegionArea(snap, opp.row, opp.col, myPlayer!);
    }

    // --- 1) generate candidates (move + wall) ---
    final cands = _generateCandidates(snap, _botPlayer, 208);
    print('[TRAP] total cands : ${cands.length}');
    for (final cand in cands) {
      // 시뮬레이션
      final _BotSnapshot ns =
          _applyMoveWithWall(snap, cand['mv'], cand['dir'], _botPlayer);

      // --- 2) after‑move region sizes ---
      for (final opp in ns.pieces.where((p) => p.owner == myPlayer)) {
        final afterSize = _countRegionArea(ns, opp.row, opp.col, myPlayer!);
        if (afterSize > 4) continue;          
                     // ➊ 아직 5칸 이상 → 트랩 아님
        final key = '${opp.row},${opp.col}';
        final beforeSize = baseRegion[key] ?? 99;
        final tmp = ns.clone();
        tmp.pieces.removeWhere((p) => p.owner == _botPlayer);   // 봇 말 삭제
        final afterSizeTransparent = _countRegionArea(tmp, opp.row, opp.col, myPlayer!);
        // ➋ “새로” 4칸 이하로 줄어든 경우만 인정
        if (beforeSize > afterSize && afterSizeTransparent == afterSize) {
          print("이이이도오오옹 $key,   벽방향 : ${cand["dir"]}    비포 :$beforeSize  ->  애프터 :$afterSizeTransparent");

          return cand; // 트랩 수 발견
        }
      }
    }
    return null; // 트랩 수 없음 → 일반 탐색
  }

  /// true if (row,col) lies on outer border **for the given direction**.
  bool _edgeBlocked(int row, int col, String dir) {
    const max = _GamePageState.boardSize - 1;
    return (dir == 'top'    && row == 0)  ||
           (dir == 'bottom' && row == max)||
           (dir == 'left'   && col == 0)  ||
           (dir == 'right'  && col == max);
  }

  /// Returns `true` if the region reachable from (row,col) contains *any*
  /// opponent piece. If not, the piece is considered already in its own
  /// isolated territory.
  bool _regionContainsOpponent(_BotSnapshot snap, int row, int col, Player owner) {
    const size = _GamePageState.boardSize;
    final visited = List.generate(size, (_) => List.filled(size, false));

    final boardPieces =
        List.generate(size, (_) => List<Player>.filled(size, Player.none));
    for (var p in snap.pieces) {
      boardPieces[p.row][p.col] = p.owner;
    }

    final q = Queue<List<int>>();
    q.add([row, col]);
    visited[row][col] = true;

    const dirs = [
      [-1, 0, 'top', 'bottom'],
      [1, 0, 'bottom', 'top'],
      [0, -1, 'left', 'right'],
      [0, 1, 'right', 'left'],
    ];

    while (q.isNotEmpty) {
      final cur = q.removeFirst();
      final r = cur[0], c = cur[1];

      // If we meet an opponent piece → region is mixed
      final occ = boardPieces[r][c];
      if (occ != Player.none && occ != owner) return true;

      for (var d in dirs) {
        final nr = r + (d[0] as int);
        final nc = c + (d[1] as int);
        if (nr < 0 || nr >= size || nc < 0 || nc >= size) continue;
        if (visited[nr][nc]) continue;

        final k1 = '${r},${c}:${d[2]}';
        final k2 = '${nr},${nc}:${d[3]}';
        if (snap.walls.containsKey(k1) || snap.walls.containsKey(k2)) continue;

        visited[nr][nc] = true;
        q.add([nr, nc]);
      }
    }
    return false; // opponent not found → isolated region
  }

  /// Detects “single‑gap” regions for the given piece.
  /// Returns {gapRow, gapCol, dir} if the region reachable from (row,col)
  /// has exactly one open edge (no wall / board edge) – i.e. placing a wall
  /// there would seal the region. Otherwise returns null.
  Map<String, dynamic>? _regionSingleGap(
      _BotSnapshot snap, int startRow, int startCol, Player owner) {
    const size = _GamePageState.boardSize;
    final visited = List.generate(size, (_) => List.filled(size, false));
    final boardPieces =
        List.generate(size, (_) => List<Player>.filled(size, Player.none));
    for (var p in snap.pieces) {
      boardPieces[p.row][p.col] = p.owner;
    }

    final q = Queue<List<int>>()..add([startRow, startCol]);
    visited[startRow][startCol] = true;

    int openCnt = 0;
    int gapR = -1, gapC = -1;
    String gapDir = 'top';

    const dirs = [
      [-1, 0, 'top', 'bottom'],
      [1, 0, 'bottom', 'top'],
      [0, -1, 'left', 'right'],
      [0, 1, 'right', 'left'],
    ];

    while (q.isNotEmpty) {
      final cur = q.removeFirst();
      final r = cur[0], c = cur[1];

      for (var d in dirs) {
        final nr = r + (d[0] as int), nc = c + (d[1] as int);
        final k1 = '${r},${c}:${d[2]}';
        final k2 = '${nr},${nc}:${d[3]}';
        final blocked = snap.walls.containsKey(k1) || snap.walls.containsKey(k2);

        if (blocked) continue;

        // Out of bounds → open edge to board edge
        if (nr < 0 || nr >= size || nc < 0 || nc >= size) {
          openCnt++;
          gapR = r;
          gapC = c;
          gapDir = d[2] as String;
          if (openCnt > 1) return null;
          continue;
        }

        final occ = boardPieces[nr][nc];
        // Opponent piece or empty cell outside owner’s region → open edge
        if (occ != Player.none && occ != owner) {
          openCnt++;
          gapR = r;
          gapC = c;
          gapDir = d[2] as String;
          if (openCnt > 1) return null;
          continue;
        }

        // Same owner / empty → continue BFS
        if (!visited[nr][nc]) {
          visited[nr][nc] = true;
          q.add([nr, nc]);
        }
      }
    }
    return (openCnt == 1)
        ? {'gapRow': gapR, 'gapCol': gapC, 'dir': gapDir}
        : null;
  }

  /// Heuristic score of a snapshot from 봇 시점 (양수 = 유리)
  double _evaluateSnapshot(_BotSnapshot snap) {
    final myArea  = _countArea(snap, _botPlayer);
    final oppArea = _countArea(snap, myPlayer!);
    final areaDiff = myArea - oppArea;

    final myMob  = this._totalMobility(snap, _botPlayer);
    final oppMob = this._totalMobility(snap, myPlayer!);
    final mobDiff = myMob - oppMob;

    return (areaDiff * 3 + mobDiff).toDouble();   // 간소화 버전
  }

  _BotSnapshot _applyMoveWithWall(
      _BotSnapshot base, _BotMove mv, String dir, Player actor) {
    final snap = base.clone();

    // --- move ---
    final Piece? src = snap.pieces.firstWhereOrNull(
      (p) => p.row == mv.piece.row &&
             p.col == mv.piece.col &&
             p.owner == actor,
    );
    if (src != null) {
      src
        ..row = mv.toRow
        ..col = mv.toCol;
    }

    // --- wall ---
    final key1 = this.wallKey(mv.toRow, mv.toCol, dir);
    final dm = {
      'top':    [-1,0,'bottom'],
      'bottom': [ 1,0,'top'   ],
      'left':   [ 0,-1,'right'],
      'right':  [ 0,1,'left' ],
    }[dir]!;
    final nr = mv.toRow + (dm[0] as int);
    final nc = mv.toCol + (dm[1] as int);
    final opp = dm[2] as String;
    final key2 = this.wallKey(nr, nc, opp);

    snap.walls[key1] = actor;
    if (nr >= 0 && nr < _GamePageState.boardSize &&
        nc >= 0 && nc < _GamePageState.boardSize) {
      snap.walls[key2] = actor;
    }

    return snap;
  }

  List<Map<String,dynamic>> _generateCandidates(
      _BotSnapshot snap, Player who, int limit) {
    final List<_BotMove> pool = [];
    for (final pc in snap.pieces.where((p) => p.owner == who)) {
      // --- Skip pieces that are already in an isolated region (only for BOT) ---
      if (who == _botPlayer &&
          !_regionContainsOpponent(snap, pc.row, pc.col, who)) {
        continue; // skip this piece
      }
      final moves = this.getMovablePositions(pc.row, pc.col);
      for (var m in moves) {
        pool.add(_BotMove(pc, m[0], m[1]));
      }
    }
    pool.shuffle();

    final dirs = ['top','bottom','left','right'];
    final List<Map<String,dynamic>> out = [];

    for (final mv in pool.take(limit)) {
      for (final d in dirs) {
        // skip walls blocked or edge
        if (_edgeBlocked(mv.toRow, mv.toCol, d)) continue;
        final k1 = this.wallKey(mv.toRow, mv.toCol, d);
        if (snap.walls.containsKey(k1)) continue;
        out.add({'mv':mv,'dir':d});
      }
    }
    return out;
  }

  /// Alpha‑beta minimax (maximizing = 봇 차례)
  double _minimax(
      _BotSnapshot snap, int depth, bool maximizing, double alpha, double beta) {
    if (depth == 0) return _evaluateSnapshot(snap);

    final Player who = maximizing ? _botPlayer : myPlayer!;
    // 후보 수를 깊이에 따라 축소 (top‑ply 8, 이후 6)
    final candLimit = (depth == 3) ? 8 : 6;
    final cands = _generateCandidates(snap, who, candLimit);

    // 후보가 없으면 그대로 평가
    if (cands.isEmpty) return _evaluateSnapshot(snap);

    if (maximizing) {
      double best = -1e9;
      for (final c in cands) {
        final nxt = _applyMoveWithWall(snap, c['mv'], c['dir'], who);
        best = max(best, _minimax(nxt, depth - 1, false, alpha, beta));
        alpha = max(alpha, best);
        if (beta <= alpha) break; // pruning
      }
      return best;
    } else {
      double worst = 1e9;
      for (final c in cands) {
        final nxt = _applyMoveWithWall(snap, c['mv'], c['dir'], who);
        worst = min(worst, _minimax(nxt, depth - 1, true, alpha, beta));
        beta = min(beta, worst);
        if (beta <= alpha) break; // pruning
      }
      return worst;
    }
  }
  /// 초기 배치 단계에서 봇이 말을 하나 배치
  void _botPlaceInitialPiece() {
    if (!placementPhase) return;
    if (_isDone) return;
    // 봇 플레이어 결정
    final Player botPlayer = _botPlayer;
    final int placedCnt =
        (botPlayer == Player.A) ? aPiecesPlaced : bPiecesPlaced;
    if (placedCnt >= 4) return;

    // 빈 칸 목록 수집 (테두리(0 혹은 6) 칸은 건너뛴다)
    final List<List<int>> empties = [];
    for (int r = 0; r < _GamePageState.boardSize; r++) {
      for (int c = 0; c < _GamePageState.boardSize; c++) {
        // 테두리(0 혹은 6) 칸은 건너뛴다
        if (r == 0 || r == _GamePageState.boardSize - 1 ||
            c == 0 || c == _GamePageState.boardSize - 1) continue;
        if (!pieces.any((p) => p.row == r && p.col == c)) {
          empties.add([r, c]);
        }
      }
    }
    if (empties.isEmpty) return;

    empties.shuffle();
    final target = empties.first;

    _playPlayerSound();
    setState(() {
      pieces.add(Piece(botPlayer, target[0], target[1]));
      if (botPlayer == Player.A) {
        aPiecesPlaced++;
      } else {
        bPiecesPlaced++;
      }

      // 턴을 사용자에게 넘김
      currentTurnPlayer = myPlayer!;

      // 모든 말이 배치되면 Move 단계로
      if (aPiecesPlaced == 4 && bPiecesPlaced == 4) {
        placementPhase = false;
        currentTurnPlayer = _botPlayer; // 규칙상 B가 선이 아니라 bot이 선
        remainingTime = 60;
        _startTimer();

        // Bot 선공이면 바로 움직이기
        if (currentTurnPlayer != myPlayer) {
          Future.delayed(botTurnDelay, () {
            if (!_isDone) _botMakeMove();
          });
        }
      }
    });
  }
  /// 봇(B) 한 턴 실행: 이동 → (지연 후) 벽 설치
  Future<void> _botMakeMove() async {
    if (!mounted || !gameStarted) return;
    if (_isDone) return;

    // ---------- 0. Quick trap (immediate execution) ----------
    final _BotSnapshot baseSnap = _BotSnapshot(pieces, walls);
    final quick = _findQuickTrap(baseSnap);
    if (quick != null) {
      debugPrint("퀵트랩 성공!");
      final _BotMove mv = quick['mv'];
      final String dir  = quick['dir'];

      // Move piece
      setState(() {
        mv.piece
          ..row = mv.toRow
          ..col = mv.toCol;
        lastMovedRow = mv.toRow;
        lastMovedCol = mv.toCol;
        botPrevRow   = mv.toRow;
        botPrevCol   = mv.toCol;
      });
      _playPlayerSound();

      // Small delay then place the trapping wall
      await Future.delayed(const Duration(milliseconds: 350));
      _botPlaceWallExact(dir);
      return; // turn done
    }
    debugPrint("퀵트랩 실패!");

    // 1) 이동 후보 수집 
    final myPieces = pieces.where((p) => p.owner == _botPlayer).toList();
    final List<_BotMove> movePool = [];
    for (var piece in myPieces) {
      final moves = getMovablePositions(piece.row, piece.col);
      for (var m in moves) {
        movePool.add(_BotMove(piece, m[0], m[1]));
      }
    }
    if (movePool.isEmpty) {
      _botPlaceRandomWall();
      return;
    }

    movePool.shuffle();
    final int limit = (botDifficulty == BotDifficulty.easy) ? 75 : 150;
    final candidates = movePool.take(limit).toList();

    const dirs = ['top', 'bottom', 'left', 'right'];
    _BotMove? bestMove;
    String? bestDir;
    double bestScore = -1e9;

    if (botDifficulty == BotDifficulty.medium) {
      // ---------- run heavy AI in background isolate ----------
      final snapshot = BotSnapshot(
        pieces: pieces
            .map((p) => Piece(p.owner, p.row, p.col))
            .toList(growable: false),
        walls: Map<String, Player>.from(walls),
        bot: _botPlayer,
        me: myPlayer!,
      );

      final decision =
          await compute<BotSnapshot, BotDecision>(chooseBestMove, snapshot);

      // reflect move
      final srcPiece = pieces.firstWhere((p)=>
          p.row==decision.fromRow && p.col==decision.fromCol && p.owner==_botPlayer);
      setState(() {
        srcPiece..row = decision.toRow ..col = decision.toCol;
        lastMovedRow = decision.toRow;
        lastMovedCol = decision.toCol;
        botPrevRow = decision.toRow;
        botPrevCol = decision.toCol;
      });
      _playPlayerSound();

      await Future.delayed(const Duration(milliseconds:350));
      _botPlaceWallExact(decision.wallDir);
      return; // done
    } else {
      // ---- 기존 1‑ply 평가 (초급) ----
      for (var mv in candidates) {
        for (var dir in dirs) {
          final score = _evaluateMoveWithWall(mv, dir);
          if (score > bestScore) {
            bestScore = score;
            bestMove = mv;
            bestDir  = dir;
          }
        }
      }
    }

    // Fallback
    bestMove ??= candidates.first;
    bestDir ??= dirs.firstWhere((d) => true);

    // Remember the location of bot's moved piece for UI highlight
    botPrevRow = bestMove!.toRow;
    botPrevCol = bestMove!.toCol;
    // --- 수행 단계 ---
    setState(() {
      bestMove!.piece
        ..row = bestMove!.toRow
        ..col = bestMove!.toCol;
      lastMovedRow = bestMove!.toRow;
      lastMovedCol = bestMove!.toCol;
    });
    _playPlayerSound();

    await Future.delayed(const Duration(milliseconds: 350));
    _botPlaceWallExact(bestDir!);
  }

  int _totalMobility(_BotSnapshot snap, Player who) {
    int mob = 0;
    for (var p in snap.pieces.where((e) => e.owner == who)) {
      mob += getMovablePositions(p.row, p.col).length;
    }
    return mob;
  }

  double _evaluateMoveWithWall(_BotMove mv, String dir) {
    // --- 0)  가장자리에서는 벽 금지 ----
    if (_edgeBlocked(mv.toRow, mv.toCol, dir)) return -1e9;

    /* -------------------------------------------------------------
       A)  기존/수정 스냅샷 준비
    ------------------------------------------------------------- */
    final baseSnap = _BotSnapshot(pieces, walls);

    /* -------------------------------------------------------------
       B)  gap‑거리 보너스 (초급 전용)
           - 상황 A(열린 면 1개) 영역이면, gap 칸에 가까워질수록 가산
    ------------------------------------------------------------- */
    double gapBonus = 0.0;
    if (botDifficulty == BotDifficulty.easy) {
      final gapInfo = _regionSingleGap(
          baseSnap, mv.piece.row, mv.piece.col, _botPlayer);
      if (gapInfo != null) {
        print("상황 A(열린 면 1개) 영역이면, gap 칸에 가까워질수록 가산!");
        final dist = (gapInfo['gapRow'] - mv.toRow).abs() +
            (gapInfo['gapCol'] - mv.toCol).abs();
        gapBonus = (10 - dist) * 20; // 20은 조정 가능
      }
    }

    /* -------------------------------------------------------------
       C)  벽 중복 여부 사전 체크 – 이미 존재→ 극페널티
    ------------------------------------------------------------- */
    final wallKeySelf = wallKey(mv.toRow, mv.toCol, dir);
    final deltaMap = {
      'top':    [-1, 0, 'bottom'],
      'bottom': [ 1, 0, 'top'   ],
      'left':   [ 0,-1, 'right' ],
      'right':  [ 0, 1, 'left'  ],
    };
    final d = deltaMap[dir]!;
    final nr = mv.toRow + (d[0] as int);
    final nc = mv.toCol + (d[1] as int);
    final oppDir = d[2] as String;
    final wallKeyNeigh = wallKey(nr, nc, oppDir);

    final bool selfBlocked = walls.containsKey(wallKeySelf);
    final bool neighBlocked = (nr >= 0 &&
        nr < _GamePageState.boardSize &&
        nc >= 0 &&
        nc < _GamePageState.boardSize) &&
        walls.containsKey(wallKeyNeigh);
    if (selfBlocked || neighBlocked) {
      return -1e9; // 중복 패널티
    }

    /* -------------------------------------------------------------
       D)  수정 스냅샷 적용
    ------------------------------------------------------------- */
    final temp = baseSnap.clone();

    // apply move
    final Piece ref = mv.piece;
    final Piece? tp = temp.pieces.firstWhere(
      (e) => e.row == ref.row && e.col == ref.col && e.owner == ref.owner,
      orElse: () => Piece(Player.A, -1, -1), // 더미 Piece 객체 반환
    );
    tp!
      ..row = mv.toRow
      ..col = mv.toCol;

    // apply wall (both sides)
    temp.walls[wallKeySelf] = _botPlayer;
    if (nr >= 0 &&
        nr < _GamePageState.boardSize &&
        nc >= 0 &&
        nc < _GamePageState.boardSize) {
      temp.walls[wallKeyNeigh] = _botPlayer;
    }

    /* -------------------------------------------------------------
       E)  휴리스틱 계산
    ------------------------------------------------------------- */
    final beforeMyArea  = _countArea(baseSnap, _botPlayer);
    final beforeOppArea = _countArea(baseSnap, myPlayer!);
    final myArea   = _countArea(temp, _botPlayer);
    final oppArea  = _countArea(temp, myPlayer!);
    final areaDiff = myArea - oppArea;

    final beforeMyMob  = _totalMobility(baseSnap, _botPlayer);
    final beforeOppMob = _totalMobility(baseSnap, myPlayer!);
    final afterMyMob   = _totalMobility(temp, _botPlayer);
    final afterOppMob  = _totalMobility(temp, myPlayer!);
    final mobilityDiff = (afterMyMob - afterOppMob);
    final oppMobReduction = beforeOppMob - afterOppMob;

    double score = (areaDiff * 3) +
                   mobilityDiff +
                   (oppMobReduction * 2) +
                   gapBonus;      // ★ gap‑거리 보너스 포함

    // ---------- Smart trapping heuristic ----------
    final bool regionShrank = oppArea < beforeOppArea;
    if (regionShrank) {
      if (oppArea < myArea) {
        score += 500;
      } else {
        score -= 100;
      }
    }

    // ---------- Self‑area loss penalty ----------
    final int selfLoss = beforeMyArea - myArea;
    if (selfLoss > 0) score -= selfLoss * 2;

    // isolated wall small penalty
    final isolatedPenalty = (afterMyMob == beforeMyMob) ? 2 : 0;
    score -= isolatedPenalty;

    return score.toDouble();
  }

  /// 벽 방향을 지정해 즉시 설치 (유효성 스킵, 이미 검증된 dir만 호출)
  void _botPlaceWallExact(String dir) {
    if (_edgeBlocked(lastMovedRow!, lastMovedCol!, dir)) return;
    if (lastMovedRow == null || lastMovedCol == null) return;
    if (_isDone) return;

    final key = wallKey(lastMovedRow!, lastMovedCol!, dir);
    final delta = {
      'top':    [-1, 0, 'bottom'],
      'bottom': [ 1, 0, 'top'   ],
      'left':   [ 0,-1, 'right' ],
      'right':  [ 0, 1, 'left'  ],
    }[dir]!;
    final nr = lastMovedRow! + (delta[0] as int);
    final nc = lastMovedCol! + (delta[1] as int);
    final opp = delta[2] as String;
    final neighKey = wallKey(nr, nc, opp);

    setState(() {
      walls[key] = _botPlayer;
      if (nr >= 0 &&
          nr < _GamePageState.boardSize &&
          nc >= 0 &&
          nc < _GamePageState.boardSize) {
        walls[neighKey] = _botPlayer;
      }

      selectedRow = selectedCol = null;
      lastMovedRow = lastMovedCol = null;
      isAwaitingWall = false;
      currentTurnPlayer = myPlayer!; // 사용자에게 턴 넘김 (myPlayer is non‑null in bot mode)

      moveTimer?.cancel();
      remainingTime = 60;
      _startTimer();
    });
    _playWallSound();
    _checkGameEnd();
  }

  /// 마지막 이동 말 주변 임의 방향에 벽 설치
  void _botPlaceRandomWall() {
    if (lastMovedRow == null || lastMovedCol == null) return;
    if (_isDone) return;

    final dirs = ['top', 'bottom', 'left', 'right']
        .where((d) => !_edgeBlocked(lastMovedRow!, lastMovedCol!, d))
        .toList()
      ..shuffle();
    if (dirs.isEmpty) return;
    for (final dir in dirs) {
      final key = wallKey(lastMovedRow!, lastMovedCol!, dir);
      final delta = {
        'top':    [-1, 0, 'bottom'],
        'bottom': [ 1, 0, 'top'   ],
        'left':   [ 0,-1, 'right' ],
        'right':  [ 0, 1, 'left'  ],
      }[dir]!;
      final nr = lastMovedRow! + (delta[0] as int);
      final nc = lastMovedCol! + (delta[1] as int);
      final opp = delta[2] as String;
      final neighKey = wallKey(nr, nc, opp);

      // `_boardSize` is a static constant on the state class.
      final inBounds = nr >= 0 &&
                       nr < _GamePageState.boardSize &&
                       nc >= 0 &&
                       nc < _GamePageState.boardSize;
      final can = !walls.containsKey(key) &&
                  (!inBounds || !walls.containsKey(neighKey));
      if (!can) continue;

      // 실제 배치
      _playWallSound();
      setState(() {
        walls[key] = _botPlayer;
        if (inBounds) walls[neighKey] = _botPlayer;

        // 상태 초기화·턴 넘김
        selectedRow = selectedCol = null;
        lastMovedRow = lastMovedCol = null;
        isAwaitingWall = false;
        currentTurnPlayer = myPlayer!; // 사용자에게 턴 넘김

        moveTimer?.cancel();
        remainingTime = 60;
        _startTimer();
      });
      _checkGameEnd();
      return;
    }
  }
}
/// ---------- End Bot logic ----------
/// 


// --- Difficulty selection dialog for Bot mode ---
Future<BotDifficulty?> _showDifficultySelectionDialog(BuildContext ctx) async {
  return await showDialog<BotDifficulty>(
    context: ctx,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF2B2520),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      actionsAlignment: MainAxisAlignment.center,
      title: Text(
        AppLocalizations.of(context)!.difficultySelectionTitle,
        style: const TextStyle(
          fontFamily: 'ChungjuKimSaeng',
          fontSize: 20,
          color: Colors.white,
        ),
      ),
      // content: Text(
      //   AppLocalizations.of(context)!.difficultySelectionContent,
      //   style: const TextStyle(
      //     fontFamily: 'ChungjuKimSaeng',
      //     color: Colors.white70,
      //   ),
      // ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(BotDifficulty.easy),
          child: Text(
            AppLocalizations.of(context)!.difficultyEasy,
            style: const TextStyle(
              fontFamily: 'ChungjuKimSaeng',
              color: Color(0xFFD4AF37),
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(BotDifficulty.medium),
          child: Text(
            AppLocalizations.of(context)!.difficultyMedium,
            style: const TextStyle(
              fontFamily: 'ChungjuKimSaeng',
              color: Color(0xFFD4AF37),
            ),
          ),
        ),
      ],
    ),
  );
}

Future<Player> _showSideSelectionDialog(BuildContext ctx, currentTheme) async {
  return await showDialog<Player>(
    context: ctx,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        backgroundColor: const Color(0xFF2B2520),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          AppLocalizations.of(context)!.sideSelectionTitle,
          style: const TextStyle(
            fontFamily: 'ChungjuKimSaeng',
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        // content: Text(
        //   AppLocalizations.of(context)!.sideSelectionContent,
        //   style: const TextStyle(
        //     fontFamily: 'ChungjuKimSaeng',
        //     color: Colors.white70,
        //   ),
        // ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(Player.A),
            child: Row(
              children: [
                Image.asset(currentTheme.playerAImagePath, width: 28, height: 28),
                const SizedBox(width: 6),
                Text(
                  AppLocalizations.of(context)!.sideSelectionOptionA,
                  style: const TextStyle(
                    fontFamily: 'ChungjuKimSaeng',
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(Player.B),
            child: Row(
              children: [
                Image.asset(currentTheme.playerBImagePath, width: 28, height: 28),
                const SizedBox(width: 6),
                Text(
                  AppLocalizations.of(context)!.sideSelectionOptionB,
                  style: const TextStyle(
                    fontFamily: 'ChungjuKimSaeng',
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    },
  ) ?? Player.A; // default to A if somehow null
}

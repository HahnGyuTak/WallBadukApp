import 'dart:collection';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../screens/game_page.dart' ;

String wallKey(int row, int col, String direction) => '$row,$col:$direction';

// Helper: Returns true if the region reachable from (row,col) contains any opponent piece.
bool _regionContainsOpponentBot(BotSnapshot snap, int row, int col, Player owner) {
  final visited = List.generate(_boardSize, (_) => List.filled(_boardSize, false));
  final occ = List.generate(_boardSize, (_) => List<Player>.filled(_boardSize, Player.none));
  for (var p in snap.pieces) {
    occ[p.row][p.col] = p.owner;
  }
  final q = Queue<List<int>>();
  q.add([row, col]);
  visited[row][col] = true;
  while (q.isNotEmpty) {
    final cur = q.removeFirst();
    final r = cur[0], c = cur[1];
    final o = occ[r][c];
    if (o != Player.none && o != owner) return true;
    for (var d in _dirs) {
      final nr = r + (d[0] as int), nc = c + (d[1] as int);
      if (nr < 0 || nr >= _boardSize || nc < 0 || nc >= _boardSize) continue;
      if (visited[nr][nc]) continue;
      final k1 = _wallKey(r, c, d[2] as String);
      final k2 = _wallKey(nr, nc, d[3] as String);
      if (snap.walls.containsKey(k1) || snap.walls.containsKey(k2)) continue;
      visited[nr][nc] = true;
      q.add([nr, nc]);
    }
  }
  return false;
}


/// --------------------  Data DTOs  --------------------
class BotSnapshot {
  final List<Piece> pieces;
  final Map<String, Player> walls;
  final Player bot; // AI side
  final Player me;  // human

  BotSnapshot({
    required this.pieces,
    required this.walls,
    required this.bot,
    required this.me,
  });

  BotSnapshot clone() => BotSnapshot(
        pieces: pieces.map((p) => Piece(p.owner, p.row, p.col)).toList(),
        walls: Map<String, Player>.from(walls),
        bot: bot,
        me: me,
      );
}

class BotDecision {
  final int fromRow, fromCol, toRow, toCol;
  final String wallDir;
  const BotDecision(
      this.fromRow, this.fromCol, this.toRow, this.toCol, this.wallDir);
}

/// Directions helper
const _dirs = [
  [-1, 0, 'top', 'bottom'],
  [1, 0, 'bottom', 'top'],
  [0, -1, 'left', 'right'],
  [0, 1, 'right', 'left'],
];

const _boardSize = 7; // fixed 7x7

// ---------- Utility (board key) ----------
String _wallKey(int r, int c, String dir) => '$r,$c:$dir';

// ---------- Reachable area ----------
int _countArea(BotSnapshot snap, Player who) {
  final visited = List.generate(_boardSize, (_) => List.filled(_boardSize, false));
  final occ = List.generate(_boardSize, (_) => List<Player>.filled(_boardSize, Player.none));
  for (var p in snap.pieces) occ[p.row][p.col] = p.owner;

  int area = 0;
  void dfs(int r, int c) {
    if (visited[r][c]) return;
    if (occ[r][c] != Player.none && occ[r][c] != who) return; // Skip if occupied by opponent
    visited[r][c] = true;
    area++;
    for (var d in _dirs) {
      final nr = r + (d[0] as int), nc = c + (d[1] as int);
      if (nr < 0 || nr >= _boardSize || nc < 0 || nc >= _boardSize) continue;
      final k1 = _wallKey(r, c, d[2] as String);
      final k2 = _wallKey(nr, nc, d[3] as String);
      if (snap.walls.containsKey(k1) || snap.walls.containsKey(k2)) continue;
      dfs(nr, nc);
    }
  }

  for (var p in snap.pieces.where((p) => p.owner == who)) dfs(p.row, p.col);
  return area;
}

// ---------- Mobility ----------
int _mobility(BotSnapshot snap, int r, int c) {
  int m = 0;
  for (var d in _dirs) {
    for (int step = 1; step <= 2; step++) {
      final nr = r + (d[0] as int) * step, nc = c + (d[1] as int) * step;
      if (nr < 0 || nr >= _boardSize || nc < 0 || nc >= _boardSize) break;
      if (snap.walls.containsKey(_wallKey(r + (d[0] as int) * (step - 1),
              c + (d[1] as int) * (step - 1), d[2] as String))) break;
      if (snap.pieces.any((p) => p.row == nr && p.col == nc)) break;
      m++;
    }
  }
  return m;
}

int _totalMobility(BotSnapshot snap, Player who) {
  int total = 0;
  for (var p in snap.pieces.where((p) => p.owner == who)) {
    if (!_regionContainsOpponentBot(snap, p.row, p.col, who)) continue;
    total += _mobility(snap, p.row, p.col);
  }
  return total;
}

// ---------- Single-gap region detection for bot engine ----------
/// Returns gap info if (row,col) owner’s region has exactly ONE open edge.
Map<String, dynamic>? _regionSingleGapBot(
    BotSnapshot snap, int startRow, int startCol, Player owner) {
  final visited = List.generate(_boardSize, (_) => List.filled(_boardSize, false));
  final occ = List.generate(_boardSize, (_) => List<Player>.filled(_boardSize, Player.none));
  for (var p in snap.pieces) occ[p.row][p.col] = p.owner;

  final q = Queue<List<int>>()..add([startRow, startCol]);
  visited[startRow][startCol] = true;

  int openCnt = 0;
  int gapR = -1, gapC = -1;
  String gapDir = 'top';

  for (;;) {
    if (q.isEmpty) break;
    final cur = q.removeFirst();
    final r = cur[0], c = cur[1];
    for (var d in _dirs) {
      final nr = r + (d[0] as int), nc = c + (d[1] as int);
      final k1 = _wallKey(r, c, d[2] as String), k2 = _wallKey(nr, nc, d[3] as String);
      final blocked = snap.walls.containsKey(k1) || snap.walls.containsKey(k2);

      if (blocked) continue;

      if (nr < 0 || nr >= _boardSize || nc < 0 || nc >= _boardSize) {
        openCnt++; gapR = r; gapC = c; gapDir = d[2] as String;
        if (openCnt > 1) return null;
        continue;
      }

      final o = occ[nr][nc];
      if (o != Player.none && o != owner) {
        openCnt++; gapR = r; gapC = c; gapDir = d[2] as String;
        if (openCnt > 1) return null;
        continue;
      }

      if (!visited[nr][nc]) {
        visited[nr][nc] = true;
        q.add([nr, nc]);
      }
    }
  }
  return (openCnt == 1) ? {'gapRow': gapR, 'gapCol': gapC, 'dir': gapDir} : null;
}

// ---------- Generate moves ----------
Iterable<Map<String, dynamic>> _candidates(
    BotSnapshot snap, 
    Player who, 
    int limit
  ) sync* {
  final pool = <Map<String, dynamic>>[];
  for (var p in snap.pieces.where((e) => e.owner == who)) {
    // Skip pieces already in isolated territory (no opponent reachable)
    if (!_regionContainsOpponentBot(snap, p.row, p.col, who)) continue;
    final moves = <List<int>>[];
    for (var d in _dirs) {
      for (int step = 1; step <= 2; step++) {
        final nr = p.row + (d[0] as int) * step, nc = p.col + (d[1] as int) * step;
        if (nr < 0 || nr >= _boardSize || nc < 0 || nc >= _boardSize) break;
        final k = _wallKey(
            p.row + (d[0] as int) * (step - 1), p.col + (d[1] as int) * (step - 1), d[2] as String);
        if (snap.walls.containsKey(k)) break;
        if (snap.pieces.any((pp) => pp.row == nr && pp.col == nc)) break;
        moves.add([nr, nc]);
      }
    }
    for (var m in moves) {
      pool.add({'mv': Piece(p.owner, p.row, p.col), 'to': m});
    }
  }
  pool.shuffle();
  for (var e in pool.take(limit)) {
    final row = (e['to'] as List<int>)[0];
    final col = (e['to'] as List<int>)[1];

    for (var d in ['top', 'bottom', 'left', 'right']) {
      // --- 1. Edge check ----------------------------------------------------
      if ((d == 'top'    && row == 0) ||
          (d == 'bottom' && row == _boardSize - 1) ||
          (d == 'left'   && col == 0) ||
          (d == 'right'  && col == _boardSize - 1)) continue;

      // --- 2. Duplicate wall check (self & neighbor) ------------------------
      final selfKey = _wallKey(row, col, d);
      if (snap.walls.containsKey(selfKey)) continue;

      const deltaMap = {
        'top':    [-1, 0, 'bottom'],
        'bottom': [ 1, 0, 'top'   ],
        'left':   [ 0,-1, 'right' ],
        'right':  [ 0, 1, 'left'  ],
      };
      final delta = deltaMap[d]!;
      final nr = row + (delta[0] as int);
      final nc = col + (delta[1] as int);
      final neighKey = _wallKey(nr, nc, delta[2] as String);

      if (nr >= 0 &&
          nr < _boardSize &&
          nc >= 0 &&
          nc < _boardSize &&
          snap.walls.containsKey(neighKey)) continue;

      // --- Passed all checks: yield candidate -------------------------------
      // Replace _singleGap with _regionSingleGapBot
      final gap = _regionSingleGapBot(snap, row, col, who);
      if (gap != null) {
        // ① gap칸 reachable in this turn ?
        final moves = getMovablePositions_bot(row, col, snap.pieces, snap.walls);
        final canReach = moves.any((m) => m[0]==gap['gapRow'] && m[1]==gap['gapCol']);
        e['gap'] = gap;
        e['canReachGap'] = canReach;
      }
      yield {'piece': e['mv'], 'to': e['to'], 'dir': d, 'gap': gap};
    }
  }
}

// ---------- Apply move ----------
BotSnapshot _apply(BotSnapshot snap, Piece src, List<int> to, String dir, Player actor) {
  final ns = snap.clone();
  // move
  final Piece mp = ns.pieces.firstWhere((p) => p.row == src.row && p.col == src.col && p.owner == actor);
  mp
    ..row = to[0]
    ..col = to[1];
  // wall
  ns.walls[_wallKey(to[0], to[1], dir)] = actor;
  final delta = {
    'top': [-1, 0, 'bottom'],
    'bottom': [1, 0, 'top'],
    'left': [0, -1, 'right'],
    'right': [0, 1, 'left']
  }[dir]!;
  final nr = to[0] + (delta[0] as int), nc = to[1] + (delta[1] as int);
  if (nr >= 0 && nr < _boardSize && nc >= 0 && nc < _boardSize) {
    ns.walls[_wallKey(nr, nc, delta[2] as String)] = actor;
  }
  return ns;
}

// ---------- Evaluate snapshot ----------
double _score(BotSnapshot snap, Map<String, dynamic> cand) {

  final gap = cand['gap'];

  final myArea  = _countArea(snap, snap.bot);
  final oppArea = _countArea(snap, snap.me);

  double myWeight = 3.0;
  double oppWeight = 3.0;
  final areaDiff = myWeight * myArea - oppWeight * oppArea;          // 기존
  final mobDiff  =
      _totalMobility(snap, snap.bot) - _totalMobility(snap, snap.me);


  double score = areaDiff + mobDiff.toDouble();

  // --- Gap proximity heuristic (if gap info is available) ---
  // (This section is illustrative; in actual move selection, pass gap & to info if available)
  // Updated gap penalty/reward logic:
  // You must define gap before using it.
  // (The following code expects 'to' to be in cand)
  if (gap != null && cand.containsKey('to')) {
    final to = cand['to'] as List<int>;
    final dist = ((gap['gapRow'] as int) - to[0]).abs() + ((gap['gapCol'] as int) - to[1]).abs();
    if (dist == 1) {
      score += 30; // 1칸 진출 시 가점
    } else if (dist >= 2) {
      score -= 20; // 2칸 이상 진출 시 감점
    }
  }

  return score;
}

// ---------- Minimax depth‑limited ----------
double _minimax(BotSnapshot snap, int depth, bool maxing, double a, double b) {
  if (depth == 0) return _score(snap, {}); // Pass an empty cand if not available
  final player = maxing ? snap.bot : snap.me;
  final cand = _candidates(
      snap, player, depth == 3 ? 12 : (depth == 2 ? 8 : 6));
  if (maxing) {
    double best = -1e9;
    for (var c in cand) {
      final ns = _apply(snap, c['piece'], c['to'], c['dir'], player);
      best = max(best, _minimax(ns, depth - 1, false, a, b));
      a = max(a, best);
      if (b <= a) break;
    }
    return best;
  } else {
    double worst = 1e9;
    for (var c in cand) {
      final ns = _apply(snap, c['piece'], c['to'], c['dir'], player);
      worst = min(worst, _minimax(ns, depth - 1, true, a, b));
      b = min(b, worst);
      if (b <= a) break;
    }
    return worst;
  }
}

/// ----------- PUBLIC ENTRY ------------
Future<BotDecision> chooseBestMove(BotSnapshot snap) async {
  Piece? bestPiece;
  List<int>? bestTo;
  String bestDir = 'top';
  double bestVal = -1e9;

  // Gather and score all candidates first
  final candidates = _candidates(snap, snap.bot, 150).toList();
  final List<Map<String, dynamic>> scoredCandidates = [];
  for (var cand in candidates) {

    final originalMyArea = _countArea(snap, snap.bot);
    final ns = _apply(
        snap, cand['piece'], cand['to'], cand['dir'], snap.bot);
    double v = _minimax(ns, 2, false, -1e9, 1e9); // 3‑ply search

    if (v <= -0.9e9 || v >= 0.9e9) {
      // perform a direct snapshot evaluation to avoid -1e9 or +1e9 results
      final myArea0  = _countArea(ns, snap.bot);
      final oppArea0 = _countArea(ns, snap.me);
      final areaDiff0 = myArea0 - oppArea0;
      final mobDiff0  = _totalMobility(ns, snap.bot) - _totalMobility(ns, snap.me);
      // include self-area bonus similar to Medium heuristic
      const selfAreaWeight0 = 1.0;
      final selfAreaBonus0 = myArea0 * selfAreaWeight0;
      v = (areaDiff0 * 3 + mobDiff0 + selfAreaBonus0).toDouble();
    }
    final afterMyArea = _countArea(ns, snap.bot);

    // 1. 영역 차이 
    final selfLoss = afterMyArea - originalMyArea;
    v += selfLoss * 2;
    
    // Gap heuristic (medium level)
    if (cand['gap'] != null) {
      final gap = cand['gap'] as Map<String,dynamic>;
      final canReach = cand['canReachGap'] as bool? ?? false;
      // Use bestTo if available, otherwise cand['to']
      final to = bestTo ?? (cand['to'] as List<int>);
      if (!canReach) {
        // 거리 보너스 toward gap
        final dist = ((gap['gapRow'] as int) - to[0]).abs() +
             ((gap['gapCol'] as int) - to[1]).abs();
        v += (10 - dist) * 10;        // 동일 가중치 10
      } else {
        // If crossing gap enlarges bot area, give extra
        final diffGain = _countArea(ns, snap.bot) - _countArea(snap, snap.bot);
        v += diffGain * 5;            // 가중치 5
      }
    }

    // --- Gap proximity reward: encourage moves closer to the gap
    if (cand.containsKey('gap')) {
      final gap = cand['gap'];
      if (gap != null) {
        final to = cand['to'] as List<int>;
        final dist = (gap['gapRow'] - to[0]).abs() + (gap['gapCol'] - to[1]).abs();
        v += (30 - dist * 5).clamp(0, 30);  // gap에 가까울수록 가산점
      }
    }

    cand['score'] = v;
    scoredCandidates.add(cand);
    if (v > bestVal) {
      bestVal = v;
      bestPiece = cand['piece'];
      bestTo = cand['to'];
      bestDir = cand['dir'];
    }
  }

  // 디버깅용: 상위 5개 수 출력
  final sorted = scoredCandidates.toList()
    ..sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
  debugPrint('🔍 Top 5 candidate moves (score descending):');
  for (int i = 0; i < sorted.length && i < 5; i++) {
    final c = sorted[i];
    debugPrint('  #$i → From: ${c['piece'].row},${c['piece'].col} To: ${c['to']}, Dir: ${c['dir']}, Score: ${c['score']}');
  }

  // fallback (shouldn't happen)
  bestPiece ??= snap.pieces.firstWhere((p) => p.owner == snap.bot);
  bestTo ??= [bestPiece.row, (bestPiece.col + 1) % _boardSize];

  return BotDecision(
      bestPiece.row, bestPiece.col, bestTo[0], bestTo[1], bestDir);
}

List<List<int>> getMovablePositions_bot(int row, int col, List<Piece> pieces, Map<String, dynamic> walls,) {
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

        if (newRow < 0 || newRow >= _boardSize || newCol < 0 || newCol >= _boardSize) break;
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

      if (midRow < 0 || midRow >= _boardSize || midCol < 0 || midCol >= _boardSize) continue;
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

        if (finalRow < 0 || finalRow >= _boardSize || finalCol < 0 || finalCol >= _boardSize) continue;
        if (pieces.any((p) => p.row == midRow && p.col == midCol) ||
            pieces.any((p) => p.row == finalRow && p.col == finalCol)) continue;

        if (isBlocked(row, col, midRow, midCol)) continue;
        if (isBlocked(midRow, midCol, finalRow, finalCol)) continue;

        moves.add([finalRow, finalCol]);
      }
    }

    return moves.toList();
  }
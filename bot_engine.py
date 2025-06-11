import numpy as np
from collections import deque
from tqdm import tqdm

# 상태 복사용 스냅샷 클래스
class BotSnapshot:
    def __init__(self, pieces, walls, turn, steps, board_size=7):
        self.pieces = {
            1: [tuple(pos) for pos in pieces[1]],
            -1: [tuple(pos) for pos in pieces[-1]]
        }
        self.walls = set(walls)
        self.turn = turn
        self.steps = steps
        self.board_size = board_size

    def clone(self):
        return BotSnapshot(self.pieces, self.walls, self.turn, self.steps, self.board_size)

# 영역 격리 필터: 특정 말 영역에 상대가 포함되어 있는지
def region_contains_opponent(snapshot, start_r, start_c, owner):
    visited = set()
    stack = [(start_r, start_c)]
    while stack:
        r, c = stack.pop()
        if (r, c) in visited:
            continue
        visited.add((r, c))
        for player, pts in snapshot.pieces.items():
            if (r, c) in pts and player != owner:
                return True
        for dr, dc in [(-1,0),(1,0),(0,-1),(0,1)]:
            nr, nc = r+dr, c+dc
            if 0<=nr<snapshot.board_size and 0<=nc<snapshot.board_size:
                if abs(dr)+abs(dc)==1 and ((r, c, 'top') in snapshot.walls if dr==-1 else \
                   (r, c, 'left') in snapshot.walls if dc==-1 else \
                   (nr, nc, 'top') in snapshot.walls if dr==1 else \
                   (nr, nc, 'left') in snapshot.walls if dc==1 else False):
                    continue
                stack.append((nr, nc))
    return False

# 단일 출구(gap) 탐색
def find_single_gap(snapshot, start_r, start_c, owner):
    visited = [[False]*snapshot.board_size for _ in range(snapshot.board_size)]
    occ = [[0]*snapshot.board_size for _ in range(snapshot.board_size)]
    for player, piece_list in snapshot.pieces.items():
        for pr, pc in piece_list:
            occ[pr][pc] = player
    q = deque([(start_r, start_c)])
    visited[start_r][start_c] = True
    open_cnt = 0
    gap_r = gap_c = -1
    gap_dir = 'top'
    dirs = [(-1,0,'top','bottom'),(1,0,'bottom','top'),(0,-1,'left','right'),(0,1,'right','left')]
    while q:
        r, c = q.popleft()
        for dr, dc, d1, d2 in dirs:
            nr, nc = r+dr, c+dc
            blocked = (r,c,d1) in snapshot.walls or (nr,nc,d2) in snapshot.walls
            if blocked: continue
            if not (0<=nr<snapshot.board_size and 0<=nc<snapshot.board_size):
                open_cnt += 1; gap_r, gap_c, gap_dir = r, c, d1
                if open_cnt>1: return None
                continue
            o = occ[nr][nc]
            if o!=0 and o!=owner:
                open_cnt += 1; gap_r, gap_c, gap_dir = r, c, d1
                if open_cnt>1: return None
                continue
            if not visited[nr][nc]:
                visited[nr][nc] = True
                q.append((nr,nc))
    return {'gapRow':gap_r,'gapCol':gap_c,'dir':gap_dir} if open_cnt==1 else None

# 상대 영역 크기 계산 (DFS)
def count_region_area(snapshot, owner):
    """
    해당 플레이어(owner)가 도달 가능한 영역 크기를 계산합니다.
    상대 플레이어의 말이 있는 칸은 영역에서 제외합니다.
    """
    # 맵 상의 말 점유 정보 생성
    occ = {(r, c): pl for pl, lst in snapshot.pieces.items() for (r, c) in lst}
    visited = set()
    area = 0
    for pr, pc in snapshot.pieces[owner]:
        stack = [(pr, pc)]
        while stack:
            r, c = stack.pop()
            if (r, c) in visited:
                continue
            # 상대 말이 있으면 제외
            if occ.get((r, c)) is not None and occ[(r, c)] != owner:
                continue
            visited.add((r, c))
            area += 1
            for dr, dc in [(-1,0),(1,0),(0,-1),(0,1)]:
                nr, nc = r + dr, c + dc
                # 범위 확인
                if not (0 <= nr < snapshot.board_size and 0 <= nc < snapshot.board_size):
                    continue
                # 벽 확인
                if (r, c, 'top') in snapshot.walls and dr == -1:
                    continue
                if (r, c, 'left') in snapshot.walls and dc == -1:
                    continue
                if (nr, nc, 'top') in snapshot.walls and dr == 1:
                    continue
                if (nr, nc, 'left') in snapshot.walls and dc == 1:
                    continue
                # 이동 가능하면 스택에 추가
                stack.append((nr, nc))
    return area

# 빠른 함정 탐지: quick trap 여부 판단
def find_quick_trap(snapshot, snap2):
    owner = snapshot.turn
    opp = -owner
    before_size = count_region_area(snapshot, opp)
    after_size = count_region_area(snap2, opp)
    # 투명 영역: 봇 말 제거
    tsnap = snap2.clone()
    tsnap.pieces[owner] = []
    after_trans = count_region_area(tsnap, opp)
    return (before_size > after_size) and (after_trans == after_size) and (after_size <= 4)

def is_blocked(snapshot, r1, c1, r2, c2):
    dr = r2 - r1
    dc = c2 - c1
    # 인접 칸이 아닌 경우 고려하지 않음
    if abs(dr) + abs(dc) != 1:
        return False
    # 위로 이동: 출발칸의 top 또는 도착칸의 bottom 검사
    if dr == -1 and ((r1, c1, 'top') in snapshot.walls or (r2, c2, 'bottom') in snapshot.walls):
        return True
    # 아래로 이동: 출발칸의 bottom 또는 도착칸의 top 검사
    if dr == 1 and ((r1, c1, 'bottom') in snapshot.walls or (r2, c2, 'top') in snapshot.walls):
        return True
    # 왼쪽 이동: 출발칸의 left 또는 도착칸의 right 검사
    if dc == -1 and ((r1, c1, 'left') in snapshot.walls or (r2, c2, 'right') in snapshot.walls):
        return True
    # 오른쪽 이동: 출발칸의 right 또는 도착칸의 left 검사
    if dc == 1 and ((r1, c1, 'right') in snapshot.walls or (r2, c2, 'left') in snapshot.walls):
        return True
    return False

# 이동 유효성 검사 함수
# 1칸, 2칸 직선, 대각선 이동 시 경로상의 기물 및 벽 검사 포함
def is_valid_move(snapshot, r, c, nr, nc):
    dr = nr - r
    dc = nc - c
    board = snapshot.board_size
    # 범위 검사
    if not (0 <= nr < board and 0 <= nc < board):
        return False
    
     # 제자리
    if dr == 0 and dc == 0:
        return True
    
    # 1칸 이동
    if abs(dr) + abs(dc) == 1:
        return not is_blocked(snapshot, r, c, nr, nc)
    # 2칸 직선 점프
    if abs(dr) == 2 and dc == 0:
        mid_r = (r + nr) // 2
        # 중간 칸 기물 검사
        if any((mid_r, c) in lst for lst in snapshot.pieces.values()):
            return False
        return (not is_blocked(snapshot, r, c, mid_r, c)
                and not is_blocked(snapshot, mid_r, c, nr, nc))
    if abs(dc) == 2 and dr == 0:
        mid_c = (c + nc) // 2
        if any((r, mid_c) in lst for lst in snapshot.pieces.values()):
            return False
        return (not is_blocked(snapshot, r, c, r, mid_c)
                and not is_blocked(snapshot, r, mid_c, nr, nc))
    # 대각선 이동
    if abs(dr) == 1 and abs(dc) == 1:
        # 경로1: 수직 → 수평
        mid1 = (r + dr, c)
        ok1 = (not any((mid1 in lst) for lst in snapshot.pieces.values()) and
               not is_blocked(snapshot, r, c, mid1[0], mid1[1]) and
               not is_blocked(snapshot, mid1[0], mid1[1], nr, nc))
        # 경로2: 수평 → 수직
        mid2 = (r, c + dc)
        ok2 = (not any((mid2 in lst) for lst in snapshot.pieces.values()) and
               not is_blocked(snapshot, r, c, mid2[0], mid2[1]) and
               not is_blocked(snapshot, mid2[0], mid2[1], nr, nc))
        return ok1 or ok2
   
    # 그 외 불가
    return False

#상대 이동 가능한 수 체크
def count_movable(snapshot, me):
    deltas=[(-1,0),(1,0),(0,-1),(0,1),(-2,0),(2,0),(0,-2),(0,2),(-1,-1),(-1,1),(1,-1),(1,1),(0,0)]
    cnt = 0
    for i,(r,c) in enumerate(snapshot.pieces[me]):
        if not region_contains_opponent(snapshot,r,c, me): continue

        for mi,(dr,dc) in enumerate(deltas):
            nr,nc = r+dr,c+dc
            if not (0<=nr<snapshot.board_size and 0<=nc<snapshot.board_size): continue
            if not (dr == dc == 0) and any((nr,nc) in pts for pts in snapshot.pieces.values()): continue
            if not is_valid_move(snapshot, r, c, nr, nc):
                continue
            cnt += 1
    return cnt
            

# 후보 생성: 영역 격리 + gap 정보
def generate_candidates_with_gap(snapshot, max_candidates=150):
    directions=['top','bottom','left','right']
    deltas=[(-1,0),(1,0),(0,-1),(0,1),(-2,0),(2,0),(0,-2),(0,2),(-1,-1),(-1,1),(1,-1),(1,1),(0,0)]
    cand=[]; seen=set()
    for i,(r,c) in enumerate(snapshot.pieces[snapshot.turn]):
        if not region_contains_opponent(snapshot,r,c,snapshot.turn): continue
        gap = find_single_gap(snapshot,r,c,snapshot.turn)
        for mi,(dr,dc) in enumerate(deltas):
            nr,nc = r+dr,c+dc
            if not (0<=nr<snapshot.board_size and 0<=nc<snapshot.board_size): continue
            if (not dr==dc==0) and any((nr,nc) in pts for pts in snapshot.pieces.values()): continue
            if not is_valid_move(snapshot, r, c, nr, nc):
                continue
            
            for wd in directions:
                key=(nr,nc,wd)
                if key in snapshot.walls or (i,mi,wd) in seen: continue
                if (wd == 'top'    and nr == 0) or \
                    (wd == 'bottom' and nr == snapshot.board_size - 1) or \
                    (wd == 'left'   and nc == 0) or \
                    (wd == 'right'  and nc == snapshot.board_size - 1):
                    continue
                seen.add((i,mi,wd))
                item=(i,(nr,nc),wd)
                if gap: item += (gap,)
                cand.append(item)
    if len(cand)>max_candidates:
        np.random.shuffle(cand); cand=cand[:max_candidates]
    return cand

# 후보 적용 함수
def apply_move_with_wall(snapshot,piece_index,target_pos,wall_dir):
    new=snapshot.clone(); new.pieces[new.turn][piece_index]=target_pos
    r,c=target_pos
    if 0<=r<new.board_size and 0<=c<new.board_size: new.walls.add((r,c,wall_dir))
    new.turn*=-1; new.steps+=1; return new

# 휴리스틱 평가
def evaluate_snapshot(snapshot, turn):
    size=lambda owner:count_region_area(snapshot,owner)
    area1, area2 = size(turn), size(-turn)
    area_diff = area1 - area2
    # 기동성 단순화
    opp_move_cnt, my_move_cnt = count_movable(snapshot, -turn), count_movable(snapshot, turn)
    mob_diff = my_move_cnt - opp_move_cnt
    return area_diff*3.0 + mob_diff *1.0 + area1

# 미니맥스
def minimax(snapshot,depth,maximizing,alpha,beta, turn):
    if depth==0: return evaluate_snapshot(snapshot, turn),None
    best=None
    cands=generate_candidates_with_gap(snapshot, max_candidates= 100 if depth == 2 else 10)
    if maximizing:
        maxv=-np.inf
        for cand in cands:
            if len(cand) == 3 :i,pos,wd = cand
            elif len(cand) == 4 :i,pos,wd, _ = cand
            v,_=minimax(apply_move_with_wall(snapshot,i,pos,wd),depth-1,False,alpha,beta,turn)
            if v>maxv: maxv,best=v,(i,pos,wd)
            alpha=max(alpha,v)
            if beta<=alpha: break
        return maxv,best
    else:
        minv=np.inf
        for cand in cands:
            if len(cand) == 3 :i,pos,wd = cand
            elif len(cand) == 4 :i,pos,wd, _ = cand
            v,_=minimax(apply_move_with_wall(snapshot,i,pos,wd),depth-1,True,alpha,beta,turn)
            if v<minv: minv,best=v,(i,pos,wd)
            beta=min(beta,v)
            if beta<=alpha: break
        return minv,best

# 최종 선택: gap, quick trap 포함
import random
def choose_best_move_with_gap(snapshot,depth=2, mode = 'train'):
    cands=generate_candidates_with_gap(snapshot)
    best_val=-np.inf; best_act=None
    tmp = [] 
    if mode == 'debug' :  cands = tqdm(cands)
    for c in cands:
        if len(c)==4: i,pos,wd,g=c
        else: i,pos,wd,g=c[0],c[1],c[2],None
        orig=count_region_area(snapshot,snapshot.turn)
        ns=apply_move_with_wall(snapshot,i,pos,wd)
        v,_=minimax(ns,depth,False,-np.inf,np.inf, snapshot.turn)
        if abs(v)>=0.9e9: v=evaluate_snapshot(ns, snapshot.turn)
        loss=orig-count_region_area(ns, snapshot.turn)
        if loss>0: v-=loss*4

        # Gap heuristic
        if g:
            gr, gc = g['gapRow'], g['gapCol']
            dist=abs(pos[0]-gr)+abs(pos[1]-gc)
            if dist == 1: v+=30
            elif dist == 2 : v+=10

        # Quick trap 보너스
        if find_quick_trap(snapshot,ns): v+=50
        if mode == 'debug' : tmp.append(((i,pos,wd), v))
        if v>best_val: best_val,best_act=v,(i,pos,wd)
    if mode == 'debug' : return best_act, sorted(tmp, key=lambda x:x[1], reverse=True)[:5]
    # best_act = random.choice(sorted(tmp, key=lambda x:x[1], reverse=True)[:2])
    return best_act#, sorted(tmp, key=lambda x:x[1], reverse=True)

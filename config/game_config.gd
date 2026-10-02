class_name GameConfig
extends RefCounted
## 조절용 수치를 모두 모아 둔 곳. 조작감·밸런스는 이 파일만 고쳐서 맞춘다.
## (임시 도형의 생김새 치수는 각 그림 스크립트에 둔다. 그림이 들어오면 사라질 값이라서.)

# ─── 쿼터뷰 ──────────────────────────────────────
## 타일 한 칸의 화면 크기(px). 가로:세로 = 2:1 마름모.
const TILE_SIZE := Vector2(128, 64)

# ─── 필드 ────────────────────────────────────────
## 필드 크기(칸 수).
const FIELD_CELLS := Vector2i(28, 28)
## 장식물 배치용 난수 씨앗. 같은 값이면 매번 같은 자리에 놓인다.
const FIELD_SEED := 20261002
const FIELD_TREE_COUNT := 36
const FIELD_ROCK_COUNT := 20
## 시작 지점 주변 몇 칸은 장식물 없이 비워 둔다.
const FIELD_SPAWN_CLEAR_CELLS := 3.0

# ─── 주인공 이동 ──────────────────────────────────
## 이동 속력(px/초). 화면 가로로 걸을 때 기준.
const PLAYER_SPEED := 240.0
## 화면 세로로 걸을 때의 속력 비율.
## 0.5 = 2:1 타일에 맞춘 쿼터뷰 원근(어느 방향이든 칸을 지나는 시간이 같다).
## 1.0 = 화면 기준으로 모든 방향이 같은 속력. 세로가 답답하면 0.6~0.7로 올려 본다.
const MOVE_VERTICAL_RATIO := 0.5
## 이 비율보다 덜 기울이면 움직이지 않는다(조이스틱 손떨림 방지). 넘는 부분은 0~1로 다시 펴서 쓴다.
const MOVE_DEADZONE := 0.15

# ─── 카메라 ──────────────────────────────────────
## 1보다 크면 확대, 작으면 축소.
const CAMERA_ZOOM := 1.0
## 카메라가 주인공을 따라가는 빠르기. 클수록 바짝, 작을수록 느긋하게 따라온다.
const CAMERA_SMOOTHING_SPEED := 6.0
## 카메라가 필드 바깥(바다)을 얼마나 보여 줄 수 있나(px).
const CAMERA_LIMIT_MARGIN := 160.0

# ─── 가상 조이스틱 ────────────────────────────────
## 화면 왼쪽 몇 비율을 누르면 조이스틱이 그 자리에 뜨나. 0.5 = 왼쪽 절반.
const JOYSTICK_ZONE_WIDTH := 0.5
## 쉬는 위치: 화면 왼쪽·아래 가장자리에서 떨어진 거리(px). 노치를 피해 안쪽에 둔다.
const JOYSTICK_REST_MARGIN := Vector2(190, 170)
## 받침 반지름(px). 손잡이를 이만큼 끌면 최대 속력.
const JOYSTICK_RADIUS := 90.0
const JOYSTICK_KNOB_RADIUS := 38.0

# ─── 사냥 방식 버튼 · 공격 버튼 (화면 오른쪽 아래) ──────
## 사냥 방식 버튼 줄: 화면 오른쪽·아래 가장자리에서 떨어진 거리(px)와 버튼 하나의 크기. 노치를 피해 안쪽에 둔다.
const MODE_BUTTONS_MARGIN := Vector2(64, 32)
const MODE_BUTTON_SIZE := Vector2(84, 40)
## 공격 버튼(수동일 때만 보임): 원의 중심이 화면 오른쪽·아래 가장자리에서 떨어진 거리(px)와 반지름.
const ATTACK_BUTTON_MARGIN := Vector2(150, 170)
const ATTACK_BUTTON_RADIUS := 56.0

# ─── 사냥 방식 / 손대면 수동 ───────────────────────
## 처음 켤 때의 사냥 방식(풀오토 · 세미오토 · 수동). 저장 기능이 생기면 마지막 선택을 기억한다.
const START_CONTROL_MODE := AutoControl.Mode.FULL_AUTO
## 손을 뗀 뒤 몇 초 지나면 자동으로 돌아오나. 0 = 손 떼는 즉시 자동.
## 사용자 결정(2026-10-02): 바로 자동으로 돌아온다(기획서의 3·5·10초 대기 대신 0).
const MANUAL_RETURN_SECONDS := 0.0

# ─── 전투 (프로토타입 2 임시값, 레벨·스킬·접미사 없음) ──────
## 체력, 공격력, 공격 간격(초), 사거리(땅 위 px), 회복량, 회복 간격(초).
## 모든 헨치는 기본 공격을 한다. 역할은 "잘하는 것"이고 차이는 나중에 스킬로 드러낸다(사용자 결정 2026-10-02).
## 밸런스는 프로토타입이 어느 정도 완성된 뒤 잡는다.
const PLAYER_STATS := {"hp": 300.0, "attack": 12.0, "attack_interval": 1.0, "attack_range": 60.0}
## 헨치 역할별 능력치. 종마다 다른 값은 나중에 data/의 도감 데이터로 옮긴다.
const ROLE_STATS := {
	"tank": {"hp": 260.0, "attack": 6.0, "attack_interval": 1.2, "attack_range": 56.0},
	"melee": {"hp": 160.0, "attack": 11.0, "attack_interval": 0.9, "attack_range": 56.0},
	"ranged": {"hp": 130.0, "attack": 9.0, "attack_interval": 1.1, "attack_range": 230.0},
	"healer": {"hp": 140.0, "attack": 4.0, "attack_interval": 1.5, "attack_range": 210.0, "heal": 18.0, "heal_interval": 1.5},
}
## 사거리가 이보다 길면 투사체를 쏜다(짧으면 몸으로 부딪쳐 때린다).
const MELEE_RANGE_MAX := 90.0
const PROJECTILE_SPEED := 700.0
## 힐러는 체력이 이 비율 아래로 떨어진 동료부터 회복한다.
const HEAL_THRESHOLD := 0.75
## 탱커가 때리면 위협 점수를 몇 배로 얻나(야생 헨치가 탱커를 노리게).
const TANK_THREAT_SCALE := 3.0
## 개인 공간(땅 위 px): 유닛끼리 이보다 가까우면 서로 살짝 밀어낸다(겹쳐서 이름표가 안 보이는 것 방지).
## 근접 사거리보다 작아야 밀려나도 공격이 끊기지 않는다.
const PERSONAL_SPACE := 44.0
## 밀어내는 힘의 최대치(이동 입력 길이 기준 0~1).
const PERSONAL_SPACE_PUSH := 0.6

# ─── 내 파티 ─────────────────────────────────────
## 함께 다니는 헨치 3마리(data/henches.json의 id).
const PARTY_HENCHES := ["sotmabaem", "haemapo", "jinjuryong"]
## 헨치 이동 속력. 주인공보다 조금 빨라야 뒤처지지 않는다.
const HENCH_SPEED := 250.0
## 따라다닐 때 주인공 기준 자리(화면 px). PARTY_HENCHES 순서대로.
const FOLLOW_SLOTS := [Vector2(-70, 26), Vector2(70, 26), Vector2(0, 56)]
## 자리에서 이만큼(땅 위 px) 벗어나면 다시 따라간다.
const FOLLOW_SLACK := 30.0
## 주인공과 이만큼 멀어지면 빨리 달려 따라잡는다.
const FOLLOW_CATCHUP_DISTANCE := 260.0
const FOLLOW_CATCHUP_SPEED_SCALE := 1.4
## 주인공에게서 이보다 먼 적은 쫓지 않는다(땅 위 px).
const PARTY_LEASH := 420.0
## 쓰러진 헨치가 다시 일어나기까지(초).
const HENCH_REVIVE_SECONDS := 6.0
## 주인공이 쓰러지면 몇 초 뒤 파티 전체가 시작 지점에서 다시 일어난다(기획서: 패배해도 페널티 없음).
const PLAYER_REVIVE_SECONDS := 3.0

# ─── 야생 헨치 ───────────────────────────────────
## 이 필드(용섬 입문)에 나오는 종.
const WILD_SPECIES := ["sotmabaem", "gochuryong", "haemapo", "jinjuryong"]
## 필드에 동시에 있는 수.
const WILD_COUNT := 14
## 쓰러진 뒤 다른 곳에 새로 나타나기까지(초).
const WILD_RESPAWN_SECONDS := 4.0
## 주인공에게서 최소 몇 칸 떨어진 곳에 나타나나.
const WILD_SPAWN_MIN_CELLS := 6.0
## 야생은 파티보다 약하게: 체력·공격 배율.
const WILD_HP_SCALE := 0.4
const WILD_ATTACK_SCALE := 0.6
## 추격·돌아다닐 때 속력 배율(HENCH_SPEED 기준).
const WILD_CHASE_SPEED_SCALE := 0.7
const WILD_WANDER_SPEED_SCALE := 0.3
## 자기 자리에서 이만큼(px) 안을 돌아다닌다.
const WILD_WANDER_RADIUS := 140.0
## 한 번 걷고 나서 쉬는 시간(초, 최소~최대).
const WILD_WANDER_PAUSE := Vector2(1.5, 4.0)
## 자기 자리에서 이보다 멀어지면 추격을 포기하고 돌아간다(땅 위 px).
const WILD_LEASH := 520.0

# ─── 선공 감지 · 기습 (프로토타입 3, 사용자 결정 2026-10-02) ──────
## 선공 몬스터는 바라보는 방향 기준의 시야로 파티를 알아챈다. 정면은 빨리, 주변시는 늦게, 등 뒤는 못 본다.
## 감지 게이지(머리 위 전구)가 다 차면 덤빈다("!"). 너무 빠르지도 느리지도 않게 아래 값으로 맞춘다.
## 이 거리(땅 위 px) 안에 있어야 보인다.
const DETECT_RANGE := 300.0
## 정면 시야: 바라보는 방향에서 한쪽으로 몇 도까지(양쪽을 합치면 두 배).
const DETECT_FRONT_HALF_ANGLE := 35.0
## 주변시: 한쪽으로 몇 도까지. 이보다 뒤는 등 뒤라 못 본다.
const DETECT_SIDE_HALF_ANGLE := 110.0
## 다 알아채기까지 걸리는 시간(초): 정면 / 주변시.
const DETECT_FRONT_SECONDS := 0.6
const DETECT_SIDE_SECONDS := 1.8
## 시야에서 벗어났을 때 꽉 찬 게이지가 다 빠지기까지(초).
const DETECT_FORGET_SECONDS := 2.0
## 알아챘을 때 그 상대에게 얹는 위협 점수. 작게 둬서, 실제로 때린 상대가 생기면 그쪽을 노린다.
const DETECT_THREAT := 1.0
## 기습 첫 타 배율. 아직 알아채지 못한 적에게, 수동 조작 중에 넣은 첫 타에만(자동 사냥은 없음).
const AMBUSH_SCALE := 1.5
## 머리 위 표시가 떠 있는 시간(초): 알아챔·반격 "!" / 추격 포기(파란 표시)
const ALERT_MARK_SECONDS := 1.0
const GIVE_UP_MARK_SECONDS := 1.4

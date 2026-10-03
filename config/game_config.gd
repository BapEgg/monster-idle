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

# ─── 공격 버튼 · 오토 버튼 · 스킬 칸 · 대상 창 ──────────
## 위치·크기는 여기 두지 않고 scenes/ui/hud.tscn에서 에디터로 끌어서 정한다(사용자 결정 2026-10-02).

# ─── 대상 지정 ──────────────────────────────────
## 화면에서 몹을 누를 때, 몸 가운데에서 이 거리(화면 px) 안을 누르면 그 몹을 대상으로 지정한다.
const TAP_PICK_RADIUS := 34.0
## 공격 버튼을 눌렀는데 대상이 없으면, 이 거리(땅 위 px) 안에서 가장 가까운 적을 대상으로 고른다.
const ATTACK_ASSIST_RANGE := 420.0
## 직접 조작 중에 대상이 이보다 멀어지면(땅 위 px) 대상을 놓는다.
const TARGET_KEEP_RANGE := 800.0
## 같은 몹을 이 시간(초) 안에 두 번 누르면(더블 탭) 공격 버튼 없이 바로 다가가 공격한다.
const DOUBLE_TAP_SECONDS := 0.35
## 체력 바 잔상(방금 깎인 만큼)이 줄어드는 빠르기(1초에 체력 바 비율).
const HP_TRAIL_SPEED := 0.6

# ─── 사냥 방식 / 손대면 수동 ───────────────────────
## 처음 켤 때의 사냥 방식(풀오토 · 세미오토 · 수동, 오토 버튼으로 바꾼다). 그 뒤로는 마지막 선택을 저장해 기억한다.
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
## 이 필드(용섬 입문)에 나오는 종. 기획서 5~6장 서식지에 "용섬 입문"이 있는 종(깡통거북 = 기계섬 입문 · 용섬 입문).
const WILD_SPECIES := ["sotmabaem", "gochuryong", "haemapo", "jinjuryong", "kkangtonggeobuk"]
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

# ─── 코어 드랍 · 가방 (프로토타입 4) ──────────────────────
## 처치했을 때 코어가 떨어질 확률(임시: 프로토타입이라 자주 보이게 높게 둔다.
## 실제 값은 하루 처치 수를 잰 뒤 기획서 8장 공식 "드랍률 = 하루 목표 ÷ 하루 처치 수"로 정한다).
const CORE_DROP_CHANCE := 0.3
## 떨어진 코어가 빛나는 코어일 확률(임시, 기획서 목표는 주 3개).
const SHINING_CORE_CHANCE := 0.1
## 야생 헨치 나이 비율: 어린 · 성체 · 늙은(임시, 기획서는 "랜덤 출현"까지만 정함).
const AGE_WEIGHTS := [0.25, 0.5, 0.25]
## 떨어지는 연출(메이플키우기 방식): 몹 자리에서 튀어 올라(초 · 높이 px · 흩어지는 거리 px) 땅에 잠깐 머물렀다가(초)
## 주인공에게 빨려 들어간다(처음 속력 px/초, 가속 px/초²).
const CORE_POP_SECONDS := 0.45
const CORE_POP_HEIGHT := 40.0
const CORE_POP_SCATTER := 30.0
const CORE_REST_SECONDS := 0.5
const CORE_FLY_SPEED := 150.0
const CORE_FLY_ACCEL := 1500.0
## 야생 헨치 성별: 암컷일 확률(임시).
const FEMALE_CHANCE := 0.5
## 야생 헨치가 변이체일 확률(임시: 기획서 목표는 월 3~4마리지만, 프로토타입이라 가끔 보이게 높게). 변이체는 코어가 반드시 떨어진다.
const VARIANT_CHANCE := 0.03
## 나이에 따른 레벨 보정(기획서 4장: 어린 -2 · 성체 0 · 늙은 +2). 야생 레벨 = 종 레벨대 가운데 + 보정.
const AGE_LEVEL_OFFSETS := [-2, 0, 2]
## 처치 골드(임시)
const GOLD_PER_KILL := 10

# ─── 코어 능력치 (프로토타입 5, 모두 임시 — 밸런스 단계에서 다시 정한다) ─────
## 역할별 1레벨 기본 능력치. 열쇠는 접미사 id와 같다(신속=공격 속도, 강력=공격, 정밀=명중, 날렵=회피,
## 단단=방어, 강인=체력, 충만=마나, 굳건=저항, 행운=드랍·코어 확률). 힐러 공격 < 탱커 < 딜러, 탱커가 가장 튼튼(사용자 결정).
const CORE_BASE_STATS := {
	"tank": {"swift": 8, "mighty": 8, "precise": 8, "nimble": 6, "sturdy": 16, "tough": 16, "abundant": 8, "steadfast": 12, "lucky": 8},
	"melee": {"swift": 14, "mighty": 15, "precise": 12, "nimble": 12, "sturdy": 9, "tough": 10, "abundant": 6, "steadfast": 8, "lucky": 8},
	"ranged": {"swift": 12, "mighty": 13, "precise": 16, "nimble": 10, "sturdy": 7, "tough": 8, "abundant": 10, "steadfast": 8, "lucky": 8},
	"healer": {"swift": 9, "mighty": 6, "precise": 10, "nimble": 10, "sturdy": 9, "tough": 10, "abundant": 16, "steadfast": 13, "lucky": 9},
	"boss": {"swift": 12, "mighty": 14, "precise": 12, "nimble": 10, "sturdy": 16, "tough": 18, "abundant": 14, "steadfast": 14, "lucky": 10},
}
## 레벨이 1 오를 때마다 기본값의 몇 배씩 늘어나나.
const CORE_STAT_GROWTH := 0.08
## 등급 보정(기획서 4장 초안: 등급당 약 +10%).
const CORE_GRADE_BONUS := {"low": 1.0, "mid": 1.1, "high": 1.2, "king": 1.3}
## 나이 보정(기획서 4장: 어린 = 몸↑ 스킬↓, 늙은 = 몸↓ 스킬↑). 몸 능력치에 (1 + 값), 스킬 능력치에 (1 - 값)을 곱한다.
const AGE_STAT_SHIFT := [0.1, 0.0, -0.1]
const AGE_BODY_STATS := ["mighty", "sturdy", "tough"]
const AGE_SKILL_STATS := ["abundant", "steadfast"]
## 접미사가 가리키는 능력치를 이만큼 올린다. 빛나는 코어는 더 크게(기획서 8장: 좋은 접미사).
const SUFFIX_BONUS := 0.2
const SHINING_SUFFIX_BONUS := 0.35
## HP = 체력 × 값, MP = 마나 × 값
const HP_PER_TOUGH := 10
const MP_PER_ABUNDANT := 5
## 믹스로 태어난 코어는 주 코어의 성별에 따라 능력치 경향이 다르다(사용자 결정 2026-10-03, 고른 능력치·배율은 임시).
## 순서 = CoreItem.Gender(0 암컷이 주 코어, 1 수컷이 주 코어). 야생에서 얻은 코어는 받지 않는다.
const MIX_MAIN_GENDER_STATS := [["mighty", "tough", "lucky"], ["swift", "sturdy", "abundant"]]
const MIX_MAIN_GENDER_BONUS := 0.1

# ─── 코어 능력치 → 필드 전투 (모두 임시, 밸런스 단계에서 다시 정한다) ─────
## 파티에 넣은 코어의 헨치는 이 값으로 싸운다(사거리·회복 간격은 역할 표 ROLE_STATS를 따른다).
## 체력 = 코어 HP, 공격 = 강력 × 값, 회복(힐러만) = 충만 × 값,
## 공격 간격 = 역할 간격 × 값 / (값 + 신속) → 신속이 이 값과 같으면 간격이 절반.
const CORE_COMBAT_ATTACK_PER_MIGHTY := 0.75
const CORE_COMBAT_HEAL_PER_ABUNDANT := 0.8
const CORE_COMBAT_SWIFT_HALF := 100.0

# ─── 믹스 · 분해 (프로토타입 5) ─────────────────────
## 결과 미리보기(기획서 4장 초안): 중급 = 공개(이름), 상급 = 힌트(실루엣), 왕 = 비밀(?)
const MIX_REVEAL_BY_GRADE := {"mid": "open", "high": "hint", "king": "secret"}
## 성공 확률(임시). 실패하면 두 재료가 모두 사라진다(사용자 결정 2026-10-02).
const MIX_SUCCESS_BY_GRADE := {"mid": 0.8, "high": 0.6, "king": 0.4}
## 골드 비용(임시). 공식이 없는 조합도 같은 값을 받아 비밀과 구별되지 않게 한다.
const MIX_GOLD_COST_BY_GRADE := {"mid": 100, "high": 400, "king": 1000}
const MIX_GOLD_COST_UNKNOWN := 100
## 새로 태어난 코어의 나이·레벨(임시: 새 몸이라 어린 1레벨). 접미사는 주 코어의 것을 받는다.
const MIX_BORN_AGE := CoreItem.Age.YOUNG
const MIX_BORN_LEVEL := 1
## 분해하면 얻는 코어 조각(임시): 기본 + 빛나는 코어 · 변이 코어 덤
const DISMANTLE_SHARDS := 1
const DISMANTLE_SHARDS_SHINING_BONUS := 2
const DISMANTLE_SHARDS_VARIANT_BONUS := 4

# ─── 저장 (나중에 Firebase로 갈아 끼운다, 코드 규칙 9) ──────
## 기기 안 저장 파일. user:// = Godot가 게임마다 따로 주는 사용자 데이터 폴더
## (에디터 메뉴 "프로젝트 → 사용자 데이터 폴더 열기"로 열린다. 이 파일을 지우면 처음부터 시작).
const SAVE_PATH := "user://save.json"
## 묶어서 저장하기(기획서 9장: 처치마다 저장하면 서버 비용이 폭증한다).
## 바뀐 것이 생기면 이 시간(초) 뒤에 한 번에 저장한다(임시). 처치·골드·코어 줍기가 여기에 묶인다.
const SAVE_INTERVAL_SECONDS := 30.0
## 사용자가 직접 한 일(믹스 · 분해 · 잠금 · 파티 편성 · 사냥 방식)은 이 시간(초) 뒤에 저장한다(임시). 연달아 하면 한 번에 묶인다.
const SAVE_SOON_SECONDS := 2.0

# ─── 개발 확인용 ──────────────────────────────────
## 켜면 저장이 없을 때(처음 켤 때) data/dev_starter.json의 코어와 골드를 가방에 넣는다. 출시 전에 끈다.
const DEV_STARTER_BAG := true

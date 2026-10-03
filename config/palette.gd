class_name Palette
extends RefCounted
## 임시 도형 그림과 UI에 쓰는 색 모음. 장면·스크립트에 색 코드를 박지 말고 여기서 가져다 쓴다.

# ─── 필드 ────────────────────────────────────────
const SEA := Color("5aa9d6")
const GRASS_A := Color("8fcf6a")
const GRASS_B := Color("85c560")
const FIELD_EDGE := Color("5e9a45")
const FIELD_SIDE_LEFT := Color("b08850")
const FIELD_SIDE_RIGHT := Color("94703f")

# ─── 공통 ────────────────────────────────────────
const OUTLINE := Color("2b2b33")
const SHADOW := Color(0, 0, 0, 0.22)

# ─── 주인공 ──────────────────────────────────────
const PLAYER_BODY := Color("3d6fd6")
const PLAYER_SKIN := Color("ffe0c2")
const PLAYER_HAIR := Color("6b4a2f")

# ─── 헨치·전투 ───────────────────────────────────
## 이름표: 내 파티 / 비선공 야생(흰색, 기획서) / 선공 야생(빨강, 기획서)
const NAME_ALLY := Color("9fe3ff")
const NAME_PASSIVE := Color(1, 1, 1)
const NAME_AGGRESSIVE := Color("ff4a3d")
## 머리 위 표시: 알아챔·반격 "!"(빨강, 기획서) / 추격 포기(파랑, 기획서)
const MARK_ALERT := Color("ff3b30")
const MARK_GIVE_UP := Color("4aa3ff")
## 감지 전구: 유리 / 차오르는 색(처음 → 다 찼을 때) / 꼭지
const BULB_GLASS := Color(1, 1, 1, 0.55)
const BULB_FILL_LOW := Color("ffe14d")
const BULB_FILL_HIGH := Color("ff7a1a")
const BULB_SOCKET := Color("9aa0a8")
## 내 파티 헨치 발밑 고리
const ALLY_RING := Color(0.62, 0.89, 1.0, 0.8)
const HIT_FLASH := Color(1, 1, 1)
const HP_BAR_BACK := Color(0, 0, 0, 0.55)
const HP_BAR_PARTY := Color("6fdc6f")
const HP_BAR_WILD := Color("ff6b5b")
## 체력 바: 방금 깎인 만큼 남는 잔상
const HP_BAR_TRAIL := Color(1, 1, 1, 0.75)
## 대상 발밑 고리
const TARGET_RING := Color(1.0, 0.85, 0.2, 0.95)
const PROJECTILE := Color("fff3b0")
## 떠오르는 숫자: 야생에게 준 피해 / 내 파티가 받은 피해 / 회복
const NUMBER_DEALT := Color("fff3b0")
const NUMBER_TAKEN := Color("ff7a6b")
const NUMBER_HEAL := Color("7dff8a")
## 기습 첫 타 숫자
const NUMBER_AMBUSH := Color("ffa53d")

# ─── 코어 · 가방 ──────────────────────────────────
## 코어(임시 도형: 종 색 보석): 테두리 / 반짝이는 면 / 빛나는 코어의 금빛
const CORE_OUTLINE := Color("2b2b33")
const CORE_GLINT := Color(1, 1, 1, 0.75)
const CORE_SHINE := Color("ffd84a")
## 가방 창: 바탕 / 테두리 / 코어 칸 / 빛나는 코어 칸 테두리 / 흐린 글자
const PANEL_BG := Color(0.1, 0.11, 0.14, 0.98)
const PANEL_BORDER := Color(1, 1, 1, 0.25)
const CARD_BG := Color(1, 1, 1, 0.08)
const CARD_BORDER := Color(1, 1, 1, 0.15)
const TEXT_DIM := Color(1, 1, 1, 0.65)
## 코어 정보창: 주 코어 성별 때문에 오른 능력치와 그 설명 줄
const STAT_BOOSTED := Color("8ee28e")
## 가방 버튼
const BAG_BUTTON := Color(0, 0, 0, 0.45)
## 가방 칸: 고른 칸 바탕·테두리
const CARD_SELECTED_BG := Color(1, 1, 1, 0.2)
const CARD_SELECTED_BORDER := Color(1, 1, 1, 0.95)
## 가방 칸 배지: 나이 / 암컷 / 수컷 / 변이 / 잠금 / 파티, 배지 글자
const BADGE_AGE := Color(0.25, 0.27, 0.32, 0.95)
const BADGE_FEMALE := Color("e8558f")
const BADGE_MALE := Color("3f7fe0")
const BADGE_VARIANT := Color("9b5de5")
const BADGE_LOCK := Color(0.45, 0.45, 0.5, 0.95)
const BADGE_PARTY := Color("2a9d8f")
const BADGE_TEXT := Color(1, 1, 1)
## 초상화 틀 바탕
const PORTRAIT_BG := Color(1, 1, 1, 0.06)
## 믹스창: 힌트(실루엣) 색 / 실패 경고 글자 / 성공 글자
const SILHOUETTE := Color(0, 0, 0, 0.9)
const TEXT_WARNING := Color("ff8a7a")
const TEXT_GOOD := Color("7dff8a")

# ─── 장식물 ──────────────────────────────────────
const TREE_TRUNK := Color("8a5a35")
const TREE_LEAF := Color("3f9a4a")
const TREE_LEAF_LIGHT := Color("62bd68")
const ROCK := Color("9aa0a8")
const ROCK_LIGHT := Color("c3c8ce")

# ─── UI ─────────────────────────────────────────
## 조이스틱: *_IDLE = 손 안 댔을 때(흐리게), 나머지 = 누르고 있을 때.
const JOYSTICK_BASE_IDLE := Color(1, 1, 1, 0.08)
const JOYSTICK_RING_IDLE := Color(1, 1, 1, 0.3)
const JOYSTICK_KNOB_IDLE := Color(1, 1, 1, 0.35)
const JOYSTICK_BASE := Color(1, 1, 1, 0.18)
const JOYSTICK_RING := Color(1, 1, 1, 0.6)
const JOYSTICK_KNOB := Color(1, 1, 1, 0.8)
## 오토 버튼: 사냥 방식별 바탕색(AutoControl.Mode 순서: 풀오토, 세미오토, 수동)과 글자색
const AUTO_BUTTON_FILLS := [Color(0.49, 1.0, 0.54, 0.85), Color(1.0, 0.82, 0.37, 0.85), Color(0, 0, 0, 0.4)]
const AUTO_BUTTON_TEXTS := [Color("2b2b33"), Color("2b2b33"), Color(1, 1, 1)]
## 스킬 칸(빈 자리)
const SKILL_SLOT := Color(0, 0, 0, 0.3)
const SKILL_SLOT_BORDER := Color(1, 1, 1, 0.35)
## 공격 버튼: 평소 / 누르는 중
const ATTACK_BUTTON := Color(1, 0.42, 0.33, 0.35)
const ATTACK_BUTTON_DOWN := Color(1, 0.42, 0.33, 0.75)
const ATTACK_BUTTON_RING := Color(1, 1, 1, 0.7)
const MODE_AUTO := Color("7dff8a")
const MODE_MANUAL := Color("ffd25e")
const MODE_DOWN := Color("ff7a6b")
const TEXT := Color(1, 1, 1)
const TEXT_OUTLINE := Color(0, 0, 0, 0.6)

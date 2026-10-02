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
## 이름표: 내 파티 / 비선공 야생(흰색, 기획서) / 선공 야생(빨강, 프로토타입 3)
const NAME_ALLY := Color("9fe3ff")
const NAME_PASSIVE := Color(1, 1, 1)
## 내 파티 헨치 발밑 고리
const ALLY_RING := Color(0.62, 0.89, 1.0, 0.8)
const HIT_FLASH := Color(1, 1, 1)
const HP_BAR_BACK := Color(0, 0, 0, 0.55)
const HP_BAR_PARTY := Color("6fdc6f")
const HP_BAR_WILD := Color("ff6b5b")
const PROJECTILE := Color("fff3b0")
## 떠오르는 숫자: 야생에게 준 피해 / 내 파티가 받은 피해 / 회복
const NUMBER_DEALT := Color("fff3b0")
const NUMBER_TAKEN := Color("ff7a6b")
const NUMBER_HEAL := Color("7dff8a")

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
## 사냥 방식 버튼: 안 고른 것 / 고른 것
const MODE_BUTTON := Color(0, 0, 0, 0.35)
const MODE_BUTTON_ON := Color(1, 1, 1, 0.85)
const MODE_BUTTON_TEXT := Color(1, 1, 1)
const MODE_BUTTON_TEXT_ON := Color("2b2b33")
## 공격 버튼: 평소 / 누르는 중
const ATTACK_BUTTON := Color(1, 0.42, 0.33, 0.35)
const ATTACK_BUTTON_DOWN := Color(1, 0.42, 0.33, 0.75)
const ATTACK_BUTTON_RING := Color(1, 1, 1, 0.7)
const MODE_AUTO := Color("7dff8a")
const MODE_MANUAL := Color("ffd25e")
const MODE_DOWN := Color("ff7a6b")
const TEXT := Color(1, 1, 1)
const TEXT_OUTLINE := Color(0, 0, 0, 0.6)

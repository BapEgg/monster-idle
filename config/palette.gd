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
## 섬의 왕 이름표 · 왕관(임시 도형)
const NAME_BOSS := Color("ffd84a")
const BOSS_CROWN := Color("ffd84a")
## 보스 장판(임시 도형): 바탕 / 차오르는 부분 / 테두리 / 터질 때 번쩍임
const DANGER_FILL := Color(1, 0.2, 0.15, 0.14)
const DANGER_PROGRESS := Color(1, 0.25, 0.15, 0.36)
const DANGER_EDGE := Color(1, 0.3, 0.2, 0.9)
const DANGER_FLASH := Color(1, 0.85, 0.5, 0.7)
## 체력 바 구간 눈금(섬의 왕)
const HP_BAR_MARK := Color(1, 1, 1, 0.85)
## 지휘 버튼(보스전): 바탕 / 누른 동안 / 끌 때 선
const COMMAND_BUTTON := Color(0, 0, 0, 0.5)
const COMMAND_BUTTON_DOWN := Color(0.35, 0.55, 1, 0.6)
const COMMAND_LINE := Color(0.6, 0.8, 1, 0.9)
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
## 창 안을 나누는 경계선(가방 창: 정보창 | 코어 칸)
const PANEL_DIVIDER := Color(1, 1, 1, 0.14)
const CARD_BG := Color(1, 1, 1, 0.08)
const CARD_BORDER := Color(1, 1, 1, 0.15)
const TEXT_DIM := Color(1, 1, 1, 0.65)
## 이름표(라벨) 글자: 연한 회색(숫자는 흰색 굵게, 사용자 결정 2026-10-03)
const TEXT_LABEL := Color(0.72, 0.75, 0.8)
## 코어 정보창: 접미사로 강한 능력치 한 줄만 이 색(강조색 1개). 빛나는 코어의 금빛과 같다.
const STAT_ACCENT := Color("ffd84a")
## 코어 정보창 HP · MP 막대, 막대 바탕
const INFO_HP_BAR := Color("e5534b")
const INFO_MP_BAR := Color("4a8ef0")
const INFO_BAR_BACK := Color(1, 1, 1, 0.1)
## 코어 정보창: 주 코어 성별 때문에 오른 능력치와 그 설명 줄 / 변이라서 오른 능력치와 그 설명 줄
const STAT_BOOSTED := Color("8ee28e")
const STAT_VARIANT := Color("c9a6ff")
## 가방 버튼
const BAG_BUTTON := Color(0, 0, 0, 0.45)
## 가방 칸: 고른 칸 바탕·테두리. 칸 테두리 뜻(사용자 결정 2026-10-03): 노랑 = 빛나는(CORE_SHINE), 흰색 = 고른 칸, 보라 반짝임 = 변이
const CARD_SELECTED_BG := Color(1, 1, 1, 0.16)
const CARD_SELECTED_BORDER := Color(1, 1, 1, 0.95)
## 믹스창: 뒤 어둡게 / 성공 · 실패 번쩍임 / NEW 글자 / 숙련도 막대 / 고를 수 없는 재료 칸 덮개
const MIX_DIM := Color(0, 0, 0, 0.65)
const MIX_FLASH_SUCCESS := Color(1, 0.97, 0.8)
const MIX_FLASH_FAIL := Color(0.85, 0.15, 0.15)
const MIX_NEW := Color("ffd84a")
const MIX_MASTERY_BAR := Color("b98cff")
## 결과 카드에서 하나만 강조하는 버튼(파티에 넣기): 파티 배지와 같은 청록
const MIX_ACCENT_BG := Color("2a9d8f")
const MIX_ACCENT_BORDER := Color("7fe0d2")
## 연성 장치(믹스창 가운데 플라스크 도형): 유리 선 · 반사광 · 유리관 · 거품
const FLASK_GLASS := Color(0.78, 0.92, 1.0, 0.75)
const FLASK_SHINE := Color(1, 1, 1, 0.35)
const FLASK_TUBE := Color(0.78, 0.92, 1.0, 0.4)
## 유리관 안이 비었을 때(회색, 믹스하면 액체가 이 위로 차오른다)
const FLASK_TUBE_EMPTY := Color(0.42, 0.44, 0.48)
const FLASK_BUBBLE := Color(1, 1, 1, 0.8)
## 빈 칸 비커 둘레 깜빡임(누르라고) · 믹스할 수 있는 플라스크 둘레 빛 · 실패한 플라스크의 탁한 액체 · 금 · 눈물
const FLASK_PULSE := Color(1, 1, 1, 0.55)
const FLASK_READY := Color(1, 0.85, 0.3, 0.8)
const FLASK_MURKY := Color(0.35, 0.33, 0.38)
const FLASK_CRACK := Color(0.92, 0.97, 1.0, 0.95)
const TEAR := Color("7fc8ff")
## 실패해 우는 주 코어(플라스크 안 그림을 푸르스름하게)
const CRYING_TINT := Color(0.75, 0.82, 1.0)
## 확률 내역 말풍선 바탕 · 숙련 표에서 지금 단계 줄 · 레시피 창에서 재료가 있는 공식
const MIX_TIP_BG := Color(0.18, 0.2, 0.26, 0.98)
## 서랍이 열렸을 때 그 뒤(연성 장치)를 살짝 가리는 덮개. 누르면 서랍이 닫힌다.
const MIX_DRAWER_SHADE := Color(0, 0, 0, 0.35)
## 스킬 상세 창 뒤를 덮는 어두운 덮개(누르면 닫힘)
const MODAL_SHADE := Color(0, 0, 0, 0.55)
const MIX_TABLE_NOW := Color(1, 1, 1, 0.12)
const MIX_RECIPE_READY := Color("8ee28e")
## 주인공 경험치 막대(왼쪽 위): 바탕 · 찬 부분, 레벨업 글자
const LEVEL_BAR_BG := Color(0, 0, 0, 0.45)
const LEVEL_BAR_FILL := Color("ffd84a")
const LEVEL_UP_TEXT := Color("ffd84a")
## 경험치 조각(주웠을 때 글자 · 먹이기 버튼)
const EXP_SHARD := Color("7fd4ff")
## 화면 오른쪽 위 재화: 골드 동전 · 동전 안쪽 고리
const CURRENCY_GOLD := Color("ffc93c")
const CURRENCY_GOLD_DARK := Color("b8860b")
## 가방의 코어 조각 칸(종마다 n/12, 사용자 결정 2026-10-03: 색 없이 흐리게, 시선이 몰리지 않게):
## 칸 바탕 · 테두리 · 진행 막대 바탕 · 찬 만큼(회색) · 다 모인 칸의 막대와 테두리
const SHARD_CARD_BG := Color(1, 1, 1, 0.03)
const SHARD_CARD_BORDER := Color(1, 1, 1, 0.1)
const SHARD_BAR_BG := Color(1, 1, 1, 0.08)
const SHARD_BAR_FILL := Color(0.62, 0.64, 0.68)
const SHARD_READY := Color("7fe0d2")
const CARD_BLOCKED_SHADE := Color(0.05, 0.06, 0.08, 0.62)
## 변이 칸 테두리: 두 보라 사이를 오가며 반짝인다
const CARD_VARIANT_DIM := Color("7b3fd0")
const CARD_VARIANT_BRIGHT := Color("e2c6ff")
## 가방 칸 배지: 나이 / 암컷 / 수컷 / 변이 / 잠금 / 파티, 배지 글자
const BADGE_AGE := Color(0.25, 0.27, 0.32, 0.95)
const BADGE_FEMALE := Color("e8558f")
const BADGE_MALE := Color("3f7fe0")
const BADGE_VARIANT := Color("9b5de5")
const BADGE_LOCK := Color(0.45, 0.45, 0.5, 0.95)
const BADGE_PARTY := Color("2a9d8f")
const BADGE_TEXT := Color(1, 1, 1)
## 믹스 재료로 고를 수 없는 까닭 배지(같은 성별 · 잠금 · 변이 …)
const BADGE_BLOCKED := Color(0.55, 0.2, 0.22, 0.95)
## 고른 칸 체크 표시(흰 동그라미 안의 체크)
const CHECK_MARK := Color("1b1d24")
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
## 스킬 칸: 쓸 수 있을 때 테두리 / 눌러서 기다리는 중 테두리 / 대기 중 덮개 / 남은 초 글자
const SKILL_SLOT_READY := Color("ffd84a")
const SKILL_SLOT_REQUESTED := Color(1, 1, 1, 0.95)
const SKILL_SLOT_COOLDOWN := Color(0, 0, 0, 0.6)
## 스킬 연출(임시 도형): 효과 종류마다 고리·이름 글자 색
const SKILL_COLORS := {
	"strike": Color("ff9a3d"), "flurry": Color("ffb35c"), "blast": Color("ff6a3d"), "stun": Color("ffe14d"),
	"taunt": Color("5ab8ff"), "heal": Color("7dff8a"), "heal_all": Color("7dff8a"),
}
## 코어 정보창 스킬 카드(눌러서 상세): 바탕 · 마우스를 댔을 때 · 누를 때, 네모 색(패시브 · 변이 · 믹스 계승), 네모 안 글자
const CHIP_BG := Color(1, 1, 1, 0.07)
const CHIP_BG_HOVER := Color(1, 1, 1, 0.12)
const CHIP_BG_DOWN := Color(1, 1, 1, 0.18)
const CHIP_PASSIVE := Color("8fa8c8")
const CHIP_VARIANT := Color("9b5de5")
const CHIP_INHERIT := Color("e0b84a")
const CHIP_GLYPH := Color(0.08, 0.09, 0.12)
## 직업 창: 궁극기 카드 색
const JOB_ULTIMATE := Color("ff5ad0")
## 스킬 상세 창 모션 미리보기(임시 도형): 바닥 · 범위 · 적 · 동료 · 그림자 · 체력 바 · 피해 숫자 · 회복 숫자
const PREVIEW_BG := Color(0.16, 0.2, 0.17)
const PREVIEW_RANGE := Color(1, 1, 1, 0.12)
const PREVIEW_ENEMY := Color("d9574a")
const PREVIEW_ALLY := Color("9fd3a8")
const PREVIEW_SHADOW := Color(0, 0, 0, 0.25)
const PREVIEW_HP_BG := Color(0, 0, 0, 0.5)
const PREVIEW_HP := Color("6fdc6f")
const PREVIEW_DAMAGE := Color("ffd84a")
const PREVIEW_HEAL := Color("7dff8a")
## 주인공 직업 스킬: 머리 위 스킬 이름 · 효과 종류별 범위 연출 색(임시)
const JOB_SKILL_CAST := Color("ffe9a8")
const JOB_EFFECT_COLORS := {
	"hit": Color("ff9a3d"), "area": Color("ff6a3d"), "taunt": Color("5ab8ff"), "shield": Color("8fd3ff"), "dash": Color("c9a6ff"),
	"retreat": Color("9fe0a0"), "pierce": Color("fff07a"), "smoke": Color("a0a4b0"), "heal": Color("7dff8a"), "revive": Color("ffffff"),
	"buff": Color("ffc93c"), "storm": Color("ff5ad0"),
}
## 보호막 막대(체력 바 위) / 기절 별
const SHIELD_BAR := Color("8fd3ff")
const STUN_STAR := Color("ffe14d")
## 공격 버튼: 평소 / 누르는 중
const ATTACK_BUTTON := Color(1, 0.42, 0.33, 0.35)
const ATTACK_BUTTON_DOWN := Color(1, 0.42, 0.33, 0.75)
const ATTACK_BUTTON_RING := Color(1, 1, 1, 0.7)
const MODE_AUTO := Color("7dff8a")
const MODE_MANUAL := Color("ffd25e")
const MODE_DOWN := Color("ff7a6b")
const TEXT := Color(1, 1, 1)
const TEXT_OUTLINE := Color(0, 0, 0, 0.6)

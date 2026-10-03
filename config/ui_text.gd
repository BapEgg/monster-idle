class_name UiText
extends RefCounted
## 화면에 보이는 문구를 모두 모아 둔 곳.
## 코어·헨치·믹스는 가제라 출시 전에 바뀐다. 문구에 직접 쓰지 말고 아래 TERM_* 상수를 이어 붙인다.
## 예) const BAG_TITLE := TERM_CORE + " 가방"

# ─── 가제 용어 ────────────────────────────────────
const TERM_CORE := "코어"
const TERM_HENCH := "헨치"
const TERM_MIX := "믹스"

# ─── 공격 버튼 · 오토 버튼 (화면 오른쪽 아래) ─────────────
## 오토 버튼 글자(AutoControl.Mode 순서)
const CONTROL_MODE_NAMES := ["풀오토", "세미오토", "수동"]
const ATTACK_BUTTON := "공격"

# ─── 대상 창 (화면 위 가운데) ──────────────────────────
## %d / %d = 남은 체력 / 최대 체력
const TARGET_HP := "%d / %d"
## 에디터에서 대상 창 자리를 잡을 때 보이는 예시 이름
const TARGET_PREVIEW_NAME := "대상 이름(에디터 예시)"

# ─── 사냥 상태 ────────────────────────────────────
const MODE_AUTO := "자동 사냥"
## 풀오토에서 조작하는 동안
const MODE_MANUAL := "수동 조작"
const MODE_SEMI_AUTO := "세미오토 · 이동은 직접"
const MODE_FULL_MANUAL := "수동 · 공격도 직접"
## %d = 자동으로 돌아오기까지 남은 초
const MODE_RETURNING := "수동 · %d초 뒤 자동"
const MODE_DOWN := "쓰러짐 · 잠시 후 일어납니다"
## %d = 처치 수
const KILLS := "처치 %d"

# ─── 전투 표시 ────────────────────────────────────
## 기습 첫 타 숫자. %d = 피해량
const AMBUSH_NUMBER := "기습! %d"
## 머리 위 표시: 알아채고 덤빌 때·맞고 반격할 때 / 추격을 포기할 때
const MARK_ALERT := "!"
const MARK_GIVE_UP := "?"

# ─── 역할 한 글자 (헨치 몸에 표시) ─────────────────
const ROLE_SHORT := {"tank": "탱", "melee": "근", "ranged": "원", "healer": "힐"}

# ─── 코어 · 가방 · 사냥 기록 (프로토타입 4) ───────────────
## 나이(CoreItem.Age 순서)
const AGE_NAMES := ["어린", "성체", "늙은"]
## 성별(CoreItem.Gender 순서). 짧은 글자는 가방 칸 배지
const GENDER_NAMES := ["암컷", "수컷"]
# ─── 섬의 왕 보스전 (프로토타입 6, 연습용 임시 보스) ─────
const BOSS_BUTTON := "섬의 왕"
const BOSS_GIVE_UP := "포기"
## %s = 왕 이름
const BOSS_ASK := "섬의 왕 %s에게 도전할까요?\n(연습 · 보상 없음)"
const BOSS_GIVE_UP_ASK := "보스전을 그만둘까요?"
const BOSS_TITLE := "섬의 왕 %s"
const BOSS_WIN := "섬의 왕 %s 해방!\n(연습이라 보상은 없습니다)"
const BOSS_LOSE := "패배…\n(연습이라 잃는 것은 없습니다)"
const BOSS_GAVE_UP := "보스전을 그만두었습니다"
## 장판 이름(보스 머리 위에 뜬다)
const BOSS_PATTERN_NAMES := {"breath": "용의 숨결", "lightning": "낙뢰", "whirl": "용오름"}
const BOSS_PATTERN_CAST := "%s!"
## 다음 체력 구간에 들어설 때
const BOSS_PHASE := "분노!"
## 지휘 버튼(CommandButton.Group 순서)
const COMMAND_NAMES := ["전원", "근접조", "원거리조"]

# ─── 스킬 (스킬 기초) ─────────────────────────────
## 스킬 효과 종류 이름(임시 분류, 정보창에 보인다)
const SKILL_KIND_NAMES := {
	"strike": "강타", "flurry": "연타", "blast": "범위 공격", "stun": "기절",
	"taunt": "도발 + 보호막", "heal": "회복", "heal_all": "범위 회복",
}
## 스킬을 쓸 때 헨치 머리 위. %s = 스킬 이름
const SKILL_CAST := "%s!"
## 보호막이 피해를 모두 막았을 때 숫자 대신
const SHIELD_BLOCK := "막음"
## 스킬 상세 창(사용자 결정 2026-10-03: 롤처럼 스킬을 누르면 설명 · 계수 · 모션 미리보기)
## 맨 위 꼬리표: 고유 액티브 · 효과 종류 / 고유 패시브 / 변이 / 믹스 계승
const SKILL_TAG_ACTIVE := "고유 액티브 · %s"
const SKILL_TAG_PASSIVE := "고유 패시브"
const SKILL_TAG_LEGACY := "유산 패시브 · %s에게서"
const SKILL_TAG_VARIANT := VARIANT
const SKILL_TAG_INHERIT := TERM_MIX + " 계승"
## 효과 종류마다 설명 한 줄(임시 분류 — 종마다 다른 효과는 스킬 단계에서)
const SKILL_DESCRIPTIONS := {
	"strike": "가까운 적에게 다가가 한 번 세게 때립니다.",
	"flurry": "적 하나를 빠르게 여러 번 연달아 때립니다.",
	"blast": "대상 자리에서 터져 둘레의 적 모두에게 피해를 줍니다.",
	"stun": "대상 둘레의 적에게 피해를 주고 잠깐 기절시킵니다.",
	"taunt": "둘레의 적이 나를 노리게 하고, 잠깐 보호막을 두릅니다.",
	"heal": "체력이 가장 낮은 동료 하나를 회복합니다.",
	"heal_all": "둘레의 동료 모두를 한꺼번에 회복합니다.",
}
const SKILL_TARGETS := {
	"strike": "가까운 적 하나", "flurry": "가까운 적 하나", "blast": "대상 둘레의 적 모두", "stun": "대상 둘레의 적 모두",
	"taunt": "내 둘레의 적 모두", "heal": "체력이 가장 낮은 동료 하나", "heal_all": "내 둘레의 동료 모두",
}
## 계수 줄 이름표
const SKILL_ROW_TARGET := "대상"
const SKILL_ROW_HEAL := "회복"
const SKILL_ROW_RADIUS := "범위"
const SKILL_ROW_STUN := "기절"
const SKILL_ROW_SHIELD := "보호막"
const SKILL_ROW_COOLDOWN := "재사용 대기"
const SKILL_ROW_DESIGN := "기획 효과"
const SKILL_ROW_EFFECT := "효과"
const SKILL_ROW_FROM := "원래 주인"
const SKILL_ROW_STATS := "오른 능력치"
const SKILL_ROW_BONUS := "보정"
const SKILL_ROW_MIX := TERM_MIX
const SKILL_ROW_INHERIT := "계승 스탯"
## 피해 줄 이름표: 첫째 계수가 마나(충만)면 마법, 아니면 물리(사용자 결정 2026-10-03: 능력치마다 계수)
const SKILL_ROW_PHYSICAL := "물리 피해"
const SKILL_ROW_MAGIC := "마법 피해"
## 계수 값: 능력치 이름 × %d%%를 " + "로 잇는다(예: 공격 × 180% + 명중 × 80%). 여러 번 때리면 뒤에 " × n번".
## (지금 n) = 이 코어 · 주인공의 지금 값 — 지금 값을 모르면(미리보기) 괄호를 뺀다
const SKILL_COEF_TERM := "%s × %d%%"
const SKILL_COEF_JOIN := " + "
const SKILL_HITS_SUFFIX := " × %d번"
const SKILL_SHIELD_POWER := "최대 체력 × %d%% · %s초"
const SKILL_NOW := "  (지금 %d)"
const SKILL_NOW_EACH := "  (지금 %d씩)"
const SKILL_RADIUS_VALUE := "반지름 %d"
const SKILL_SECONDS := "%s초"
const SKILL_PASSIVE_DESC := "늘 켜져 있는 효과입니다. " + TERM_MIX + "할 때 주 " + TERM_CORE + "의 패시브(유산)로 바꿀 수 있습니다."
const SKILL_VARIANT_DESC := "드롭으로만 얻는 돌연변이입니다. 능력치가 조금 더 높고, 나중에 원종과 다른 공격 패턴 · 스킬을 갖습니다."
const SKILL_VARIANT_MIX := "재료로 못 씀"
const SKILL_INHERIT_DESC := TERM_MIX + "할 때 보조 " + TERM_CORE + "의 접미사 능력치 일부를 고정치로 물려받았습니다."
const SKILL_INHERIT_VALUE := "%s +%d"
const SKILL_NOTE_ACTIVE := "수치 · 효과 종류는 임시입니다. 그림 단계에서 종마다 다른 모션으로 바뀝니다."
const SKILL_NOTE_PASSIVE := "패시브 수치는 아직 없습니다(스킬 단계에서 정함)."
const SKILL_MOTION_CAPTION := "모션 미리보기(임시 도형)"
const SKILL_CLOSE := "닫기"
## 레벨이 올라 직업 스킬을 새로 배울 수 있게 됐을 때(주인공 머리 위, 직업 창에서 배운다). %s = 스킬 이름
const JOB_LEARNABLE := "배울 수 있어요: %s"
## 직업 창(기획서 3장, 직업 1차)
const JOB_BUTTON := "직업"
const JOB_TITLE := "직업 · 스킬"
const JOB_POINTS := "스킬 포인트 %d"
const JOB_CLOSE := "닫기"
## 직업 이름 아래: 역할 · 기본 무기
const JOB_KIND := "%s · %s"
## 왼쪽 능력치(사용자 결정 2026-10-03: 주인공도 코어와 같은 능력치 9종 — 장비가 이 값을 올린다): HP · MP + 9종 표, 아래 전투 값 한 줄
const JOB_SHEET_HP := "HP"
const JOB_SHEET_MP := "MP"
const JOB_COMBAT_LINE := "공격력 %d · 공격 간격 %s초 · 사거리 %d"
const JOB_MODS_LINE := "패시브 보정: %s"
const JOB_SWITCH := "직업 바꾸기(개발용 · 출시 전엔 프롤로그에서 한 번 고름)"
const JOB_SWITCH_ASK := "%s(으)로 바꿀까요?\n배운 스킬과 장착이 처음으로 돌아갑니다(개발용)."
## 직업 창 섹터 제목 · 오른쪽 작은 줄(장착 수 / 칸 수)
const JOB_SECTION_TITLES := {"active": "액티브", "passive": "패시브", "ultimate": "궁극기"}
const JOB_SECTION_INFO := {"active": "장착 %d/%d · 스킬 칸 4~6", "passive": "장착 %d/%d · 칸은 Lv 10 · 30에 열림", "ultimate": "장착 %d/%d · 궁극기 칸"}
## 섹터 왼쪽 장착 칸 아래 글(%d = 칸 번호) · 아직 안 열린 칸
const JOB_SLOT_CAPTION := "%d번 칸"
const JOB_SLOT_ULTIMATE := "궁극기 칸"
const JOB_SLOT_LOCKED := "Lv %d에 열림"
## 장착한 궁극기 칸의 배지(액티브 · 패시브는 칸 번호)
const JOB_EQUIPPED_BADGE := "장착"
## 아래 행동 줄: 아무것도 안 골랐을 때 안내 · 고른 스킬의 상태 줄
const JOB_HINT := "스킬을 누르면 여기서 배우기 · 장착 · 레벨 올리기(한 번 더 누르면 미리보기)"
const JOB_STATUS_EQUIPPED := "%s · Lv %d/%d · %s에 장착"
const JOB_STATUS_FREE := "%s · Lv %d/%d · 장착 안 함"
const JOB_STATUS_LEARNABLE := "%s · 배울 수 있음(Lv %d 해금)"
const JOB_STATUS_LOCKED := "%s · Lv %d에 배울 수 있음"
const JOB_PICK_SLOT := "바꿀 칸을 누르세요"
## 스킬 칸 아래 작은 줄: 배운 스킬 레벨 / 배울 수 있음
const JOB_TILE_LEVEL := "Lv %d/%d"
const JOB_TILE_LEARNABLE := "배울 수 있음"
## 스킬 상세 창의 스킬 레벨 줄(레벨은 됐는데 안 배움)
const JOB_LEVEL_LEARNABLE := "배울 수 있음(Lv %d 해금)"
## 직업 창 아래 행동 줄 버튼(스킬 상세 창은 보기 전용, 사용자 결정 2026-10-03)
const JOB_ACT_PREVIEW := "미리보기"
const JOB_ACT_LEARN := "배우기"
const JOB_ACT_LOCKED := "Lv %d에 배움"
const JOB_ACT_EQUIP := "장착"
const JOB_ACT_UNEQUIP := "해제"
const JOB_ACT_LEVEL := "레벨 올리기 · 포인트 1"
const JOB_ACT_NO_POINTS := "스킬 포인트 없음"
const JOB_ACT_MAX := "최고 레벨"
## 스킬 칸(궁극기 칸)이 아직 열리지 않았을 때
const SKILL_SLOT_LOCKED := "Lv %d"
## 직업 스킬 상세(직업 창 · 스킬 상세 창): 꼬리표 · 계수 줄
const JOB_TYPE_NAMES := {"active": "액티브", "passive": "패시브", "ultimate": "궁극기"}
const JOB_SKILL_TAG := "%s · %s 스킬"
const JOB_ROW_LEVEL := "스킬 레벨"
const JOB_LEVEL_VALUE := "%d / %d"
const JOB_LEVEL_LOCKED := "Lv %d에 배움"
const JOB_ROW_LEVEL_BONUS := "레벨 효과"
const JOB_LEVEL_BONUS_VALUE := "스킬 레벨 1당 +%d%%"
const JOB_ROW_TARGET := "대상"
const JOB_ROW_MOVE := "움직임"
const JOB_ROW_LENGTH := "길이"
const JOB_ROW_REVIVE := "일으키기"
const JOB_ROW_BUFF := "강화"
const JOB_ROW_DEBUFF := "약화"
const JOB_ROW_SMOKE := "연막"
const JOB_ROW_CLEANSE := "정화"
const JOB_TARGETS := {"self": "나", "party": "파티 모두", "lowest": "체력이 가장 낮은 동료 하나", "area": "내 둘레의 동료 모두", "target": "대상 둘레의 적 모두", "around": "내 둘레의 적 모두", "one": "대상 하나", "line": "일직선의 적 모두"}
const JOB_DASH_VALUE := "대상 곁으로 순간 이동(최대 %d)"
const JOB_RETREAT_VALUE := "때린 뒤 %d만큼 물러남"
const JOB_LENGTH_VALUE := "%d · 폭 %d"
const JOB_REVIVE_VALUE := "쓰러진 헨치 %d명까지 · 체력 %d%%"
const JOB_REVIVE_ALL := "쓰러진 헨치 모두 · 체력 %d%%"
const JOB_VULNERABLE_VALUE := "받는 피해 +%d%% · %s초"
const JOB_SMOKE_VALUE := "%s초 동안 아무것도 못 하고 나를 놓침"
const JOB_CLEANSE_VALUE := "기절 풀기"
const JOB_TAUNT_VALUE := "반지름 %d 안의 적이 나를 노림"
const JOB_BUFF_PARTS := {"attack": "공격 +%d%%", "speed": "공격 속도 +%d%%", "guard": "받는 피해 −%d%%"}
const JOB_SECONDS_SUFFIX := " · %s초"
## 패시브 보정 이름(값 = %d%%)
const JOB_MOD_NAMES := {
	"hp": "체력 +%d%%", "damage_taken": "받는 피해 −%d%%", "attack": "공격 +%d%%", "attack_speed": "공격 속도 +%d%%",
	"move_speed": "이동 속도 +%d%%", "range": "사거리 +%d%%", "ambush": "기습 배율 +%d%%", "heal_power": "마나 +%d%%",
	"tank_damage_taken": "탱커 헨치가 받는 피해 −%d%%", "party_hp": "파티 헨치 최대 체력 +%d%%", "buff_seconds": "버프 시간 +%d%%", "buff_power": "버프 효과 +%d%%",
}
const JOB_ROW_MOD := "보정"
const JOB_PASSIVE_NOTE := "패시브 칸에 장착하면 늘 켜집니다. 수치는 임시입니다."
const JOB_ACTIVE_NOTE := "수치는 임시입니다. 그림 단계에서 직업마다 다른 모션으로 바뀝니다."
## 정보창의 스킬 카드(눌러서 상세): 위 작은 이름표 · 아이콘 글자
const CHIP_ACTIVE := "액티브"
const CHIP_PASSIVE := "패시브"
const CHIP_LEGACY := "유산 패시브"
const CHIP_VARIANT := VARIANT
const CHIP_INHERIT := TERM_MIX + " 계승"
const CHIP_GLYPHS := {"active": "액", "passive": "패", "ultimate": "궁", "variant": "변", "inherit": "계"}
const CHIP_VARIANT_TITLE := "능력치 +%d%%"
## 여러 이름을 한 줄로 늘어놓을 때 사이
const LIST_SEPARATOR := ", "
const VARIANT := "변이"
const SHINING := "빛나는"
## 코어를 주웠을 때 주인공 머리 위. %s = 종 이름
const PICKUP := "+%s " + TERM_CORE
## 가방 버튼. %d = 코어 수
const BAG_BUTTON := "가방 %d"
## 가방 창 제목. %d = 코어 수
const BAG_TITLE := TERM_CORE + " 가방"
## 가방 오른쪽 칸 위: 가진 코어 수(사용자 결정 2026-10-03: 제목 옆이 아니라 오른쪽 칸에서)
const BAG_COUNT := "보유 %d개"
const BAG_CLOSE := "닫기"
const BAG_EMPTY := "아직 비어 있습니다. 몹을 쓰러뜨리면 " + TERM_CORE + "가 떨어집니다."
## 코어 칸 둘째 줄: 접미사 · 나이
const CORE_DETAIL := "%s · %s"
# ─── 디버그 화면 (개발 확인용, GameConfig.DEV_DEBUG_PANEL, 출시 전에 끈다) ─────
const DEBUG_BUTTON := "디버그"
const DEBUG_TITLE := "디버그"
const DEBUG_PARTY_TITLE := "파티 전투(코어 능력치 → 임시 환산)"
## %d = 자리, %s = 이름, %d/%d = 지금/최대 체력, %d = 공격, %.2f = 공격 간격(초)
const DEBUG_PARTY_ROW := "%d. %s — 체력 %d/%d · 공격 %d · 공격 간격 %.2f초"
const DEBUG_PARTY_HEAL := " · 회복 %d"
## 사냥 기록(디버그 화면). 처치 수 / 코어 수 / 빛나는 코어 수
const HUNT_TOTALS := "사냥 기록(이번 접속): 처치 %d · " + TERM_CORE + " %d개 (빛나는 %d개)"
## 시간당 처치: 자동 / 수동 / 수동 이득 / 하루 예상
const HUNT_RATES := "시간당 처치: 자동 %s · 수동 %s (%s) · 하루 예상(자동 24시간) %s"
## 아직 잴 수 없을 때
const HUNT_UNKNOWN := "—"
## 수동이 자동보다 얼마나 더 잡는지. %+d = 퍼센트
const HUNT_ADVANTAGE := "수동 %+d%%"
# ─── 성장 (주인공 레벨 · 헨치 골드 레벨업) ─────────────
const LEVEL_LABEL := "Lv %d"
const LEVEL_MAX := "최고"
## 레벨이 올랐을 때 주인공 머리 위
const LEVEL_UP := "레벨 업! Lv %d"
## 코어 정보창 경험치 조각 먹이기 버튼: 다음 레벨까지 넉넉함 / 모자라 가진 만큼 / 못 하는 까닭(Workshop.FeedProblem 순서: NONE, AT_CAP, NO_SHARDS)
const BTN_FEED_LEVEL := "레벨업 (조각 %d개)"
const BTN_FEED_SOME := "조각 %d개 먹이기"
const FEED_PROBLEMS := ["", "주인공 레벨(Lv %d)까지", "경험치 조각 없음"]
## 사냥 중 경험치 조각을 주웠을 때 주인공 머리 위
const EXP_SHARD_PICKUP := "경험치 조각 +%d"
## 밸런스 1차(기획서 8장): 지금 확률과, 그 확률로 하루 처치 수만큼 잡으면 얻는 양(목표 대비)
const DEBUG_BALANCE := "확률(하루 처치 %s마리 기준): " + TERM_CORE + " %.3f%% · 빛나는 %.1f%% · 변이 %.4f%%\n목표 대비: 하루 " + TERM_CORE + " %.1f개(목표 %d~%d) · 주 빛나는 %.1f개(목표 %d) · 월 변이 %.1f마리(목표 %d~%d)"
## 개발 확인용 드랍 배율 버튼(켜짐/꺼짐)
const DEBUG_DROP_BOOST := "드랍 확인 ×%d: %s"
const DEBUG_ON := "켜짐"
const DEBUG_OFF := "꺼짐"

# ─── 가방 칸 · 코어 정보 · 믹스 (프로토타입 5) ─────────────
const ROLE_NAMES := {"tank": "탱커", "melee": "근접딜러", "ranged": "원거리딜러", "healer": "힐러", "buffer": "버퍼", "boss": "보스"}
const GRADE_NAMES := {"low": "하급", "mid": "중급", "high": "상급", "king": "왕"}
## 가방 칸 배지
const BADGE_LOCK := "잠금"
const BADGE_PARTY := "파티"
## 가방의 코어 조각 칸(종마다, 사용자 결정 2026-10-03): 칸 아래 진행 · 다 모인 칸 배지 · 조각 칸들 위 작은 제목
const SHARD_PROGRESS := TERM_CORE + " 조각 %d/%d"
const SHARD_READY := "만들기"
const SHARD_SECTION := TERM_CORE + " 조각 · %d개를 모으면 그 " + TERM_CORE + "가 됩니다"
## 조각 칸을 누르면 정보창: 종류 줄 뒤 · 줄들([이름표, 값])
const SHARD_INFO_COUNT := "모은 조각"
const SHARD_INFO_SOURCE := "얻는 곳"
const SHARD_INFO_SOURCE_VALUE := "같은 종 " + TERM_CORE + " 분해"
## 만들기 확인. %s = 종 이름, %d = 쓰는 조각 수
const SHARD_MAKE_ASK := "%s " + TERM_CORE + " 조각 %d개로 " + TERM_CORE + "를 만들까요?\n(나이 · 성별 · 접미사는 무작위)"
## 코어 정보창
const INFO_EMPTY := "칸을 누르면 정보가 보입니다"
## 종족 · 역할 · 등급
const INFO_KIND := "%s · %s · %s"
const INFO_LEVEL := "LV %d"
const INFO_HP := "HP"
const INFO_MP := "MP"
const INFO_EXP := "EXP"
const INFO_EXP_VALUE := "%d/%d"
## 믹스로 태어난 코어: 보조 코어에게서 물려받은 추가 스탯. %s = 능력치 이름, %d = 더한 값
const INFO_INHERIT := TERM_MIX + " 계승: %s +%d (보조 " + TERM_CORE + "에게서)"
const BTN_PARTY := "파티 편성"
const BTN_PARTY_LEAVE := "파티에서 빼기"
const BTN_MIX := TERM_MIX
const BTN_DISMANTLE := "분해"
const BTN_LOCK := "잠금"
const BTN_UNLOCK := "잠금 해제"
const PARTY_PICK := "넣을 자리를 고르세요"
## %d = 자리 번호, %s = 지금 그 자리의 헨치
const PARTY_SLOT := "%d번 · %s"
const BTN_CANCEL := "취소"
const BTN_OK := "확인"
const BTN_YES := "예"
## 분해 확인. %s = 이름, %s = 종 이름, %d = 조각 수(그 종의 코어 조각)
const DISMANTLE_ASK := "%s\n분해하면 사라지고 %s " + TERM_CORE + " 조각 %d개를 얻습니다."
const CANT_DISMANTLE := "잠겼거나 파티에 있는 것은 분해할 수 없습니다"
## 믹스창(전체 화면 3단: 재료 · 연성 장치 · 정보창, 사용자 결정 2026-10-03)
const MIX_TITLE := TERM_MIX
const MIX_MAIN := "주 " + TERM_CORE
const MIX_SUB := "보조 " + TERM_CORE
## 성별 기호(CoreItem.Gender 순서)
const GENDER_SYMBOLS := ["♀", "♂"]
## 정보창 성별 배지: 기호 + 이름(♀ 암컷)
const GENDER_BADGE := "%s %s"
## 기획서에 없는 반대 방향 공식(임시 초안)일 때 결과 이름 옆에 붙는다.
const MIX_DRAFT := "(초안 공식)"
const MIX_HINT_NAME := "???"
const MIX_SECRET := "?"
## 힌트일 때 종류 줄: ??? · 종족
const MIX_HINT_KIND := "??? · %s"
## 주 · 보조 칸 사이 버튼(사용자 결정 2026-10-03: "바꾸면 → ○○" 글은 뺌)
const MIX_SWAP := "⇄"
## 숙련 경험치: 지금 / 다음 단계까지(마지막 단계면 "최고")
const MIX_MASTERY_EXP := "%d/%d"
const MIX_MASTERY_MAX := "최고"
## 결과 미리보기 줄 이름표와 값
const MIX_PREVIEW_CAPTIONS := ["예상 레벨", "접미사", "계승 스탯", "나이", "성별"]
const MIX_PREVIEW_LEVEL := "Lv %d"
## 주 코어 접미사 이름 · 그 확률 / 무작위 확률
const MIX_PREVIEW_SUFFIX := "%s %d%% · 무작위 %d%%"
## 보조 코어 접미사 능력치 + 최소~최대
const MIX_PREVIEW_INHERIT := "%s +%d~%d"
## 암컷 % · 수컷 %
const MIX_PREVIEW_GENDER := "♀ %d%% · ♂ %d%%"
const MIX_PREVIEW_UNKNOWN := "?"
const MIX_KEEP_OWN := "자기 패시브\n%s"
const MIX_KEEP_LEGACY := "유산 (주 " + TERM_CORE + ")\n%s"
## 유산 패시브 카드에서 고른 쪽 앞에 붙는 체크
const MIX_CHOSEN := "✓ %s"
## 성공 확률(합). 내역은 눌러서 보는 말풍선(MIX_CHANCE_TIP)
const MIX_CHANCE := "성공 확률 %s"
## 비용 / 보유 골드
const MIX_COST := "비용 %d 골드 · 보유 %d"
const MIX_WARNING := "실패하면 재료 둘이 모두 사라집니다"
## 플라스크 아래 안내(믹스할 수 있을 때, 플라스크를 누르면 믹스 — 사용자 결정 2026-10-03) · 결과 이름 뒤 정보 표시(누르면 미리보기)
const MIX_FLASK_HINT := "플라스크를 눌러 " + TERM_MIX + "하기"
const MIX_INFO_MARK := " ⓘ"
## 성공 확률을 누르면 뜨는 내역 말풍선
const MIX_CHANCE_TIP := "성공 확률 내역\n기본 %d%% + 숙련 %d%% + 마크 %d%%"
## 연성하기 아래 작은 버튼: 숙련 단계(누르면 숙련 창) · 레시피 창
const MIX_MASTERY_BUTTON := "숙련 %d단계 ⓘ"
const MIX_RECIPE_BUTTON := "레시피"
## 숙련 창: 지금 단계 · 경험치 / 표 머리 / 보너스 / 마지막 단계 / 한 번에 얻는 경험치
const MIX_MASTERY_TITLE := TERM_MIX + " 숙련"
const MIX_MASTERY_NOW := "지금 %d단계 · 경험치 %s"
const MIX_MASTERY_HEADERS := ["단계", "성공 확률 보너스", "다음 단계까지 경험치"]
const MIX_MASTERY_STEP := "%d단계"
const MIX_MASTERY_BONUS := "+%d%%"
const MIX_MASTERY_NOTE := TERM_MIX + " 한 번에 경험치: 성공 %d · 실패 %d"
## 숙련 창 맨 아래: 마지막 단계 보상(칭호는 가제, 아직 기능 없음)
const MIX_MASTERY_REWARD := "%d단계 달성 시 칭호 획득(가제)"
## 믹스창 오른쪽 정보창의 작은 제목: 재료를 눌렀을 때 / 결과 칸을 눌렀을 때
const MIX_INFO_MATERIAL := "재료 정보"
const MIX_INFO_PREVIEW := "결과 미리보기"
## 레시피 창: 한 줄 = 주 + 보조 → 결과 · 등급, 재료가 있는 공식은 눌러서 칸을 채운다
const MIX_RECIPE_TITLE := "레시피"
const MIX_RECIPE_ROW := "%s + %s → %s · %s"
const MIX_RECIPE_DRAFT := " (초안)"
const MIX_RECIPE_READY := "  ✓ 재료 있음"
const MIX_RECIPE_NOTE := "공개 · 힌트 공식만 보입니다. 재료가 있는 공식을 누르면 칸을 채웁니다"
## 결과 칸 미리보기(정보창): 비밀 · 공식 없음일 때 종류 줄
const MIX_SECRET_KIND := "비밀 공식"
const MIX_EMPTY_KIND := "재료 둘을 고르면 결과가 보입니다"
## 성공 카드의 패시브 고르기
const MIX_PASSIVE_PICK := "패시브 고르기"
const MIX_PASSIVE_FINAL := "선택은 나중에 바꿀 수 없어요"
## 재료 서랍: 머리(그 칸에 넣을 재료) · 비우기 · 다른 칸에 이미 있는 코어를 눌렀을 때 · 빈 칸 안내
const MIX_DRAWER_TITLE := "%s에 넣을 재료"
const MIX_DRAWER_CLEAR := "비우기"
const MIX_IN_OTHER_SLOT := "이미 %s 칸에 있어요(⇄로 바꿀 수 있어요)"
const MIX_SLOT_PICK := "＋\n눌러서 고르기"
const MIX_FILTER_ALL := "전체 종족"
## 재료 정렬(MixPanel.Sort 순서)
const MIX_SORTS := ["레벨 높은 순", "등급 높은 순", "빛나는 먼저"]
## 빛나는 코어 · 높은 레벨 재료를 쓸 때 한 번 더 묻기
const MIX_CONFIRM_SHINING := "빛나는 " + TERM_CORE + "가 들어 있어요"
const MIX_CONFIRM_LEVEL := "높은 레벨(Lv %d) 재료가 들어 있어요"
const MIX_CONFIRM_ASK := "%s\n실패하면 재료 둘이 모두 사라집니다. " + TERM_MIX + "할까요?"
## 결과 카드
const MIX_RESULT_NEW := "NEW · 도감 등록"
## Lv · 나이 · 성별
const MIX_RESULT_INFO := "LV %d · %s · %s"
const MIX_MASTERY_UP := TERM_MIX + " 숙련 %d단계로 올랐어요!"
## 얻은 숙련 경험치(지금 / 다음 단계까지)
const MIX_RESULT_EXP := TERM_MIX + " 숙련 경험치 +%d (%s)"
const MIX_FAIL_TITLE := TERM_MIX + " 실패…"
const MIX_FAIL_INFO := "재료 둘이 사라졌습니다"
## 실패 카드: 잃은 재료 줄
const MIX_FAIL_LOST := "잃은 재료: %s · %s"
## 실패 카드에서 잃은 재료 칸에 붙는 배지
const MIX_LOST_BADGE := "사라짐"
const BTN_TO_PARTY := "파티에 넣기"
const BTN_SHOW_INFO := "정보 보기"
const BTN_MIX_AGAIN := "계속 " + TERM_MIX
const PERCENT := "%d%%"
const UNKNOWN_PERCENT := "?%"
## 믹스할 수 없는 까닭(Mix.Problem 순서: NONE, MISSING, SAME_CORE, SAME_GENDER, LOCKED, IN_PARTY, VARIANT, NO_RECIPE, NO_GOLD)
const MIX_PROBLEMS := ["", "재료 칸이 비어 있습니다", "같은 것끼리는 안 됩니다", "암수 한 쌍이어야 합니다",
	"잠긴 것은 쓸 수 없습니다", "파티에 있는 것은 쓸 수 없습니다", VARIANT + "는 재료로 쓸 수 없습니다", "알려진 공식이 없어요", "골드가 모자랍니다"]
## 재료 목록에서 고를 수 없는 칸에 붙는 짧은 까닭(Mix.Problem 순서). 주 코어 자신은 "주 " + TERM_CORE
const MIX_MATERIAL_REASONS := ["", "", "주 " + TERM_CORE, "같은 성별", "잠금", "파티", VARIANT, "", ""]

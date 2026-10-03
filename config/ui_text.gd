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
## 치명타 숫자 · 기습이면서 치명타. %d = 피해량
const CRIT_NUMBER := "치명! %d"
const AMBUSH_CRIT_NUMBER := "기습 치명! %d"
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
## 스킬 상세 창(툴팁, 사용자 결정 2026-10-03: 롤 툴팁처럼). 맨 위 꼬리표(헨치): 고유 액티브 / 고유 패시브 / 유산 패시브 / 변이 / 믹스 계승
const TIP_TAG_HENCH_ACTIVE := "고유 액티브"
const SKILL_TAG_PASSIVE := "고유 패시브"
const SKILL_TAG_LEGACY_SHORT := "유산 패시브"
const SKILL_TAG_VARIANT := VARIANT
const SKILL_TAG_INHERIT := TERM_MIX + " 계승"
## 꼬리표: 근접 · 원거리(적을 겨누는 스킬만) · 단일 · 범위 · 자신
const TIP_TAG_MELEE := "근접"
const TIP_TAG_RANGED := "원거리"
const TIP_TAG_SINGLE := "단일"
const TIP_TAG_AREA := "범위"
const TIP_TAG_SELF := "자신"
## 오른쪽 위 스킬 레벨: 배움 / 배울 수 있음 / 레벨이 모자람
const TIP_LEVEL := "Lv %d/%d"
const TIP_LEVEL_LEARNABLE := "배울 수 있음 · Lv %d"
const TIP_LEVEL_LOCKED := "Lv %d에 배움"
## 둘째 줄: 마나 소모 · 재사용 대기 · 사거리(자신 둘레 스킬은 "자신")
const TIP_LINE := "마나 %s  ·  재사용 대기 %s  ·  사거리 %s"
const TIP_SECONDS := "%s초"
const TIP_REACH_SELF := "자신"
## 설명 문장: 계산된 숫자(계수). 계수 = 능력치 이름 + %, 스탯 색. 능력치를 모르면(미리보기) 계수만.
const TIP_AMOUNT := "%s(%s)"
const TIP_COEF := "%s %s"
const TIP_COEF_JOIN := " + "
const TIP_PHYSICAL := "물리 피해"
const TIP_MAGIC := "마법 피해"
const TIP_WHO := {"self": "나", "party": "파티 모두"}
const TIP_HIT := "대상 하나에게 %s의 %s를 줍니다."
const TIP_HIT_MULTI := "대상 하나를 %d번 때려 한 번에 %s의 %s를 줍니다."
const TIP_AREA_TARGET := "대상 둘레 반지름 %d 안의 적 모두에게 %s의 %s를 줍니다."
const TIP_AREA_SELF := "내 둘레 반지름 %d 안의 적 모두에게 %s의 %s를 줍니다."
const TIP_STUN := "맞은 적은 %s초 동안 %s합니다."
const TIP_VULNERABLE := "맞은 적은 %s초 동안 %s에 걸려 받는 피해가 %s 늘어납니다."
const TIP_TAUNT := "내 둘레 반지름 %d 안의 적을 %s해 나만 노리게 합니다."
const TIP_SHIELD := "%s에게 %s초 동안 %s의 %s을 두릅니다."
const TIP_SHIELD_AMOUNT := "최대 체력 %s"
const TIP_DASH := "최대 %d 떨어진 대상 곁으로 순간 이동해 %s %s의 %s를 줍니다."
const TIP_DASH_ONE := "대상에게"
const TIP_DASH_AREA := "반지름 %d 안의 적 모두에게"
const TIP_RETREAT := "대상에게 %s의 %s를 주고 %d만큼 물러납니다."
const TIP_PIERCE := "길이 %d · 폭 %d의 일직선 위 적 모두에게 %s의 %s를 줍니다."
const TIP_SMOKE := "내 둘레 반지름 %d 안의 적이 %s초 동안 %s하고 나를 놓칩니다."
const TIP_HEAL_LOWEST := "체력이 가장 낮은 동료 하나를 %s만큼 회복합니다."
const TIP_HEAL_AREA := "내 둘레 반지름 %d 안의 동료 모두를 %s만큼 회복합니다."
const TIP_CLEANSE := "%s도 풀어 줍니다."
const TIP_REVIVE := "쓰러진 헨치를 %d명까지 체력 %s로 일으킵니다."
const TIP_REVIVE_ALL := "쓰러진 헨치 모두를 체력 %s로 일으킵니다."
const TIP_BUFF := "%s에게 %s초 동안 %s: %s."
const TIP_STORM := "내 둘레 반지름 %d 안의 적을 %d번 휩쓸어 한 번에 %s의 %s를 줍니다."
const TIP_PASSIVE_JOB := "패시브 칸에 장착하면 늘 켜집니다: %s."
const TIP_HENCH_PASSIVE := "늘 켜져 있는 효과: %s. " + TERM_MIX + "할 때 주 " + TERM_CORE + "의 패시브(유산)로 바꿀 수 있습니다."
const TIP_LEGACY_FROM := "%s에게서 물려받은 유산 패시브입니다."
const TIP_VARIANT := "드롭으로만 얻는 돌연변이입니다. %s 능력치가 %s 더 높습니다. " + TERM_MIX + " 재료로 쓸 수 없고, 나중에 원종과 다른 공격 패턴 · 스킬을 갖습니다."
const TIP_INHERIT := TERM_MIX + "할 때 보조 " + TERM_CORE + "에게서 %s를 고정치로 물려받았습니다."
const SKILL_INHERIT_VALUE := "%s +%d"
## 다음 레벨 비교(배운 스킬, 최고 레벨 전까지): "다음 레벨: 공격 143% → 157% · 재사용 10초 → 9.5초"
const TIP_NEXT := "다음 레벨  %s"
const TIP_NEXT_PART := "%s %s → %s"
const TIP_NEXT_COOLDOWN := "재사용 %s초 → %s초"
const TIP_ARROW := "%s → %s"
const TIP_NEXT_NAMES := {"amount": "보호막", "attack": "공격", "speed": "공격 속도", "guard": "받는 피해 −", "vulnerable": "받는 피해 +", "hp": "일으킨 체력"}
## 개발 문구(디버그 화면에서 켰을 때만 보인다)
const TIP_DESIGN := "기획 효과: %s"
const TIP_DESIGN_DESC := "기획 설명: %s"
## 상태이상 낱말(굵게, 누르면 뜻 말풍선): id → [이름, 뜻]
const STATUS_TERMS := {
	"stun": ["기절", "아무것도 못 합니다(움직이기 · 공격 · 스킬)."],
	"burn": ["화상", "불에 데어 잠깐 동안 조금씩 피해를 입습니다(아직 효과 없음 — 스킬 단계에서 붙입니다)."],
	"taunt": ["도발", "도발한 대상만 노립니다."],
	"vulnerable": ["약화", "받는 피해가 늘어납니다."],
	"shield": ["보호막", "체력보다 먼저 피해를 받아 줍니다. 시간이 지나면 사라집니다."],
	"buff": ["강화", "공격 · 공격 속도가 오르거나 받는 피해가 줄어듭니다."],
}
const SKILL_NOTE_ACTIVE := "수치 · 효과 종류는 임시입니다. 그림 단계에서 종마다 다른 모션으로 바뀝니다."
const SKILL_NOTE_PASSIVE := "패시브 수치는 아직 없습니다(스킬 단계에서 정함)."
const SKILL_MOTION_CAPTION := "모션 미리보기"
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
## 능력치 표의 치명타 두 줄(UnitStats.CRIT_STATS 순서)과 값(%d = 퍼센트)
const STAT_CRIT_NAMES := {"crit_chance": "치명 확률", "crit_damage": "치명 피해"}
const STAT_PERCENT := "%d%%"
const JOB_SHEET_MP := "MP"
const JOB_COMBAT_LINE := "공격력 %d · 공격 간격 %s초 · 사거리 %d"
const JOB_MODS_LINE := "패시브 보정: %s"
const JOB_SWITCH := "직업 바꾸기(개발용 · 출시 전엔 프롤로그에서 한 번 고름)"
const JOB_SWITCH_ASK := "%s(으)로 바꿀까요?\n배운 스킬과 장착이 처음으로 돌아갑니다(개발용)."
## 직업 창 섹터 제목 · 오른쪽 작은 줄(장착 수 / 칸 수)
const JOB_SECTION_TITLES := {"active": "액티브", "passive": "패시브", "ultimate": "궁극기"}
const JOB_SECTION_INFO := "장착 %d/%d"
## 위 탭(사용자 결정 2026-10-03) · 능력치 탭 제목 · 장비 탭(아직 없음)
## 직업 창 탭(사용자 결정 2026-10-03: 능력치와 장비를 한 탭 — 왼쪽 능력치 + 오른쪽 장비)
const JOB_TABS := {"character": "캐릭터", "skills": "스킬"}
const JOB_STATS_TITLE := "능력치"
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
## 직업 스킬 종류 이름(꼬리표 · 행동 줄)
const JOB_TYPE_NAMES := {"active": "액티브", "passive": "패시브", "ultimate": "궁극기"}
const JOB_BUFF_PARTS := {"attack": "공격 +%d%%", "speed": "공격 속도 +%d%%", "guard": "받는 피해 −%d%%"}
## 패시브 보정 이름(값 = %d%%)
const JOB_MOD_NAMES := {
	"hp": "체력 +%d%%", "damage_taken": "받는 피해 −%d%%", "attack": "공격 +%d%%", "attack_speed": "공격 속도 +%d%%",
	"move_speed": "이동 속도 +%d%%", "range": "사거리 +%d%%", "ambush": "기습 배율 +%d%%", "heal_power": "마나 +%d%%",
	"tank_damage_taken": "탱커 헨치가 받는 피해 −%d%%", "party_hp": "파티 헨치 최대 체력 +%d%%", "buff_seconds": "버프 시간 +%d%%", "buff_power": "버프 효과 +%d%%",
}
const JOB_PASSIVE_NOTE := "수치는 임시입니다."
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
## 한 줄 안에서 조각 사이(대상 창 상성 줄)
const LIST_SEPARATOR_DOT := " · "
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
# ─── 종족 상성 (사용자 결정 2026-10-03, 추천 A) ─────────
const AFFINITY_TITLE := "종족 상성표"
const AFFINITY_BUTTON := "상성표"
## 상성표 아래 설명. %d = 강한 상대에게 + %, 약한 상대에게 − %
const AFFINITY_LEGEND := "화살표 방향으로 강하다. 강한 상대에게 주는 피해 +%d%%, 약한 상대에게 주는 피해 −%d%%. 주인공은 종족이 없어 상성이 없다."
## %s = 종족 이름(코어 정보창 · 대상 창)
const AFFINITY_STRONG := "▲ %s에게 강함"
const AFFINITY_WEAK := "▼ %s에게 약함"
## 상성표 오른쪽: 주제 · 강함/약함 줄(%s = 종족 이름, %s = 까닭)
const AFFINITY_THEME := "주제: %s"
const AFFINITY_STRONG_LINE := "▲ %s에게 강함\n%s"
const AFFINITY_WEAK_LINE := "▼ %s에게 약함\n%s"
## 대상 창 · 섬 지도의 섬의 왕: 약점(%s = 이 종족에게 강한 종족)
const AFFINITY_WEAKNESS := "약점 %s"
## 대상 창: 대상이 강한 종족(%s, 데려가면 불리)
const AFFINITY_TARGET_STRONG := "%s에게 강함"
const MAP_KING_WEAKNESS := " · 약점 %s"

# ─── 장비 · 캐릭터 탭 (기획서 3장, 사용자 요청 2026-10-03) ─────────
const GEAR_GRADES := ["일반", "마법", "희귀", "전설", "세트"]
const GEAR_QUALITIES := ["하급", "중급", "상급", "최상급"]
## 부위 이름(GearDb.kinds)
const GEAR_SLOT_NAMES := {"weapon": "무기", "helmet": "투구", "armor": "갑옷", "gloves": "장갑", "boots": "신발", "accessory": "장신구"}
## 능력치 9종 · 치명타 말고 장비 옵션에만 있는 것
const GEAR_EXTRA_NAMES := {"party_hp": "파티 헨치 최대 체력"}
const GEAR_TITLE := "장비"
const GEAR_ITEMS_TITLE := "아이템"
## %d = 아이템 칸의 장비 수(낀 것 빼고)
const GEAR_COUNT := "보유 %d개"
## 정렬(GearRules.Sort 차례) · 부위 거르기 첫 칸
const GEAR_SORTS := ["등급순", "레벨순", "부위순", "최근순"]
const GEAR_FILTER_ALL := "모든 부위"
## 아이템 정보: 종류 줄(%s = 등급, 품질, 부위, %d = 장비 레벨) · 무기의 직업(%s = 직업 이름)
const GEAR_KIND_LINE := "%s · %s · %s · Lv %d"
const GEAR_JOB_ONLY := "%s 전용"
## 못 끼는 까닭(GearRules.Problem 차례, OK는 "")
const GEAR_PROBLEMS := ["", "%s 전용 무기", "Lv %d부터"]
const GEAR_WORN_TAG := "착용 중"
## 비교 제목(%s = 지금 낀 장비 이름) · 빈 칸에 끼울 때
const GEAR_COMPARE := "착용 중(%s)과 비교"
const GEAR_COMPARE_EMPTY := "빈 칸에 낌 — 모두 ▲"
## 아무것도 고르지 않았을 때: 낀 장비로 오른 능력치 합계
const GEAR_TOTAL_TITLE := "장비로 오른 능력치"
const GEAR_TOTAL_NONE := "낀 장비 없음"
const BTN_EQUIP := "장착"
const BTN_UNEQUIP := "해제"
## 캐릭터 탭 이야기 버튼 · 이야기 창(인물 · 섬에 온 계기 · 지금의 갈등, 기획서 3장 표)
const STORY_BUTTON := "이야기"
const STORY_TITLE := "%s 이야기"
const STORY_PERSON := "인물 · 섬에 온 계기"
const STORY_CONFLICT := "지금의 갈등"
const STORY_PATHS := "전직 갈래 (MVP 이후)"

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
## 스킬 상세 창의 개발 문구("수치는 임시" · "기획 효과") 보이기(사용자 결정 2026-10-03: 개발 모드에서만)
const DEBUG_DEV_NOTES := "스킬 창 개발 문구: %s"
## 섬 개방(다음 단계) 전에 다른 섬을 확인하려고 모두 연다(저장하지 않음)
const DEBUG_OPEN_ISLANDS := "모든 섬 열기(개발용): %s"
const DEBUG_GIVE_GEAR := "장비 받기(개발용)"
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
const BTN_SHOW_INFO := "정보 보기"
const BTN_MIX_AGAIN := "계속 " + TERM_MIX
const PERCENT := "%d%%"
const UNKNOWN_PERCENT := "?%"
## 믹스할 수 없는 까닭(Mix.Problem 순서: NONE, MISSING, SAME_CORE, SAME_GENDER, LOCKED, IN_PARTY, VARIANT, NO_RECIPE, NO_GOLD)
const MIX_PROBLEMS := ["", "재료 칸이 비어 있습니다", "같은 것끼리는 안 됩니다", "암수 한 쌍이어야 합니다",
	"잠긴 것은 쓸 수 없습니다", "파티에 있는 것은 쓸 수 없습니다", VARIANT + "는 재료로 쓸 수 없습니다", "알려진 공식이 없어요", "골드가 모자랍니다"]
## 재료 목록에서 고를 수 없는 칸에 붙는 짧은 까닭(Mix.Problem 순서). 주 코어 자신은 "주 " + TERM_CORE
const MIX_MATERIAL_REASONS := ["", "", "주 " + TERM_CORE, "같은 성별", "잠금", "파티", VARIANT, "", ""]

# ─── 섬 · 지역 (기획서 7장, 로드맵 8) ─────────────────
## 미니맵 위 띠 · 지역에 들어설 때 뜨는 큰 글자: 섬 · 지역 (Lv a~b)
const WORLD_TITLE := "%s · %s (Lv %d~%d)"
## 패배해서 이전 지역으로 물러났을 때 큰 글자 아래 작은 줄
const WORLD_RETREAT := "쓰러져서 이전 지역으로 물러났습니다"
## 오른쪽 위 지도 버튼 · 섬 지도 창
const MAP_BUTTON := "지도"
const MAP_TITLE := "섬 지도"
const MAP_CLOSE := "닫기"
const MAP_HERE := "지금: %s · %s"
const MAP_HERE_BADGE := "지금"
const MAP_KING := "섬의 왕: %s"
const MAP_LOCKED_ISLAND := "아직 닫힌 섬입니다. 도감을 채우고 길잡이 " + TERM_HENCH + "를 " + TERM_MIX + "하면 열립니다(다음 단계)."
const MAP_REGION := "%s · Lv %d~%d"
const MAP_RARE := "%s(드묾)"
const MAP_GO := "이동"
const MAP_HERE_TAG := "지금 여기"
const MAP_NEED_LEVEL := "Lv %d부터"
const MAP_CLOSED := "닫힘"

## 파티 자리가 비었을 때(가방 창 파티 편성 고르기 · 디버그 화면)
const PARTY_SLOT_EMPTY := "빈 자리"


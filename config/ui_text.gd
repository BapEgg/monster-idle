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
const GENDER_SHORT := ["암", "수"]
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
## 정보창의 고유 액티브 줄 뒤에 붙는다. %s = 효과 종류 이름
const INFO_SKILL_KIND := "\n지금 효과(임시): %s"
## 여러 이름을 한 줄로 늘어놓을 때 사이
const LIST_SEPARATOR := ", "
const VARIANT := "변이"
const SHINING := "빛나는"
## 코어를 주웠을 때 주인공 머리 위. %s = 종 이름
const PICKUP := "+%s " + TERM_CORE
## 가방 버튼. %d = 코어 수
const BAG_BUTTON := "가방 %d"
## 가방 창 제목. %d = 코어 수
const BAG_TITLE := TERM_CORE + " 가방 · %d개"
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

# ─── 가방 칸 · 코어 정보 · 믹스 (프로토타입 5) ─────────────
const ROLE_NAMES := {"tank": "탱커", "melee": "근접딜러", "ranged": "원거리딜러", "healer": "힐러", "boss": "보스"}
const GRADE_NAMES := {"low": "하급", "mid": "중급", "high": "상급", "king": "왕"}
## 가방 칸 배지
const BADGE_LOCK := "잠금"
const BADGE_PARTY := "파티"
## 가방 창 위: 골드 · 코어 조각
const MONEY := "골드 %d · " + TERM_CORE + " 조각 %d"
## 코어 정보창
const INFO_EMPTY := "칸을 누르면 정보가 보입니다"
## 종족 · 역할 · 등급
const INFO_KIND := "%s · %s · %s"
const INFO_LEVEL := "LV %d"
const INFO_HP := "HP"
const INFO_MP := "MP"
## 믹스로 태어난 코어: %s = 주 코어 성별, %s = 오른 능력치들, %d = 몇 %
const INFO_BIRTH := TERM_MIX + " 출생(%s이 주 " + TERM_CORE + "): %s +%d%%"
## 변이 코어: %s = 오른 능력치들, %d = 몇 %. 믹스 재료로는 못 쓴다.
const INFO_VARIANT := VARIANT + ": %s +%d%% · " + TERM_MIX + " 재료로 못 씀"
const INFO_ACTIVE := "고유 액티브"
const INFO_PASSIVE := "고유 패시브"
## 유산으로 받은 패시브. %s = 패시브, %s = 원래 주인 종 이름
const INFO_LEGACY := "%s (유산 · %s)"
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
## 분해 확인. %s = 이름, %d = 조각 수
const DISMANTLE_ASK := "%s\n분해하면 사라지고 " + TERM_CORE + " 조각 %d개를 얻습니다."
const CANT_DISMANTLE := "잠겼거나 파티에 있는 것은 분해할 수 없습니다"
## 믹스창
const MIX_TITLE := TERM_MIX
const MIX_MAIN := "주 " + TERM_CORE
const MIX_SUB := "보조 " + TERM_CORE
const MIX_SLOT_EMPTY := "아래에서 고르세요"
## 성별 방향: 암컷 이름 / 수컷 이름
## 주 코어(성별) × 보조 코어(성별). 태어날 종은 어느 쪽이 주 코어냐로 정해진다.
const MIX_DIRECTION := "주 %s(%s)  ×  보조 %s(%s)"
## 주 코어 성별에 따른 능력치 경향. %s = 성별, %s = 오른 능력치들, %d = 몇 %
const MIX_GENDER_TREND := "%s이 주 " + TERM_CORE + " → 태어날 " + TERM_CORE + ":\n%s +%d%%"
## 기획서에 없는 반대 방향 공식(임시 초안)일 때 결과 이름 옆에 붙는다.
const MIX_DRAFT := "(초안 공식)"
const MIX_RESULT := "결과"
const MIX_HINT_NAME := "???"
const MIX_SECRET := "?"
const MIX_SWAP := "주 ↔ 보조"
const MIX_PASSIVE_TITLE := "패시브 1칸: 무엇을 남길까요?"
const MIX_KEEP_OWN := "자기 패시브: %s"
const MIX_KEEP_LEGACY := "유산(주 " + TERM_CORE + "): %s"
## 비용 / 보유 골드 / 성공 확률
const MIX_COST := "비용 %d 골드 (보유 %d) · 성공 확률 %s"
const MIX_WARNING := "실패하면 재료 둘이 모두 사라집니다"
const MIX_CANDIDATES := "보조 " + TERM_CORE + " 고르기"
const MIX_GO := TERM_MIX + "하기"
## 믹스 확인. %s = 성공 확률
const MIX_ASK := "성공 확률 %s\n실패하면 재료 둘이 모두 사라집니다. " + TERM_MIX + "할까요?"
## 믹스 결과. %s = 이름, %s = 성별, %s = 나이
const MIX_SUCCESS := TERM_MIX + " 성공!\n%s(%s · %s) 탄생"
const MIX_FAIL := TERM_MIX + " 실패…\n재료 둘이 사라졌습니다"
const PERCENT := "%d%%"
const UNKNOWN_PERCENT := "?%"
## 믹스할 수 없는 까닭(Mix.Problem 순서: NONE, MISSING, SAME_CORE, SAME_GENDER, LOCKED, IN_PARTY, VARIANT, NO_GOLD)
const MIX_PROBLEMS := ["", "보조 칸이 비어 있습니다", "같은 것끼리는 안 됩니다", "암수 한 쌍이어야 합니다",
	"잠긴 것은 쓸 수 없습니다", "파티에 있는 것은 쓸 수 없습니다", VARIANT + "는 재료로 쓸 수 없습니다", "골드가 모자랍니다"]

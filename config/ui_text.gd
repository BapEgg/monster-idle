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
## 사냥 기록(가방 창 위쪽). 처치 수 / 코어 수 / 빛나는 코어 수
const HUNT_TOTALS := "사냥 기록(이번 접속): 처치 %d · " + TERM_CORE + " %d개 (빛나는 %d개)"
## 시간당 처치: 자동 / 수동 / 수동 이득 / 하루 예상
const HUNT_RATES := "시간당 처치: 자동 %s · 수동 %s (%s) · 하루 예상(자동 24시간) %s"
## 아직 잴 수 없을 때
const HUNT_UNKNOWN := "—"
## 수동이 자동보다 얼마나 더 잡는지. %+d = 퍼센트
const HUNT_ADVANTAGE := "수동 %+d%%"

class_name UiText
extends RefCounted
## 화면에 보이는 문구를 모두 모아 둔 곳.
## 코어·헨치·믹스는 가제라 출시 전에 바뀐다. 문구에 직접 쓰지 말고 아래 TERM_* 상수를 이어 붙인다.
## 예) const BAG_TITLE := TERM_CORE + " 가방"

# ─── 가제 용어 ────────────────────────────────────
const TERM_CORE := "코어"
const TERM_HENCH := "헨치"
const TERM_MIX := "믹스"

# ─── 조작 안내 (화면 왼쪽 위) ─────────────────────────
const HINT := "이동: WASD · 방향키 / 화면 왼쪽 끌기\n공격: Space / 공격 버튼 · 몹을 누르면 대상 지정\n오토 버튼: 풀오토 → 세미오토 → 수동"

# ─── 공격 버튼 · 오토 버튼 (화면 오른쪽 아래) ─────────────
## 오토 버튼 글자(AutoControl.Mode 순서)
const CONTROL_MODE_NAMES := ["풀오토", "세미오토", "수동"]
const ATTACK_BUTTON := "공격"

# ─── 대상 창 (화면 위 가운데) ──────────────────────────
## %d / %d = 남은 체력 / 최대 체력
const TARGET_HP := "%d / %d"

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

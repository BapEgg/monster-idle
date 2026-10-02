class_name UiText
extends RefCounted
## 화면에 보이는 문구를 모두 모아 둔 곳.
## 코어·헨치·믹스는 가제라 출시 전에 바뀐다. 문구에 직접 쓰지 말고 아래 TERM_* 상수를 이어 붙인다.
## 예) const BAG_TITLE := TERM_CORE + " 가방"

# ─── 가제 용어 ────────────────────────────────────
const TERM_CORE := "코어"
const TERM_HENCH := "헨치"
const TERM_MIX := "믹스"

# ─── 조작 안내 ────────────────────────────────────
const HINT_MOVE := "이동: WASD · 방향키   /   화면 왼쪽을 누른 채 끌기(조이스틱)"

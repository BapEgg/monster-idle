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

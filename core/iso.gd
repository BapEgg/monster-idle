class_name Iso
extends RefCounted
## 쿼터뷰(2:1 아이소메트릭) 좌표 변환. 격자(칸) ↔ 화면(px) 변환은 반드시 여기서만 한다.
## 격자 (0, 0) 칸의 위쪽 꼭짓점이 화면 원점이다.
## 격자 x축은 화면 오른쪽 아래로, y축은 왼쪽 아래로 뻗는다.


## 격자 좌표 → 화면 좌표.
static func grid_to_screen(grid: Vector2) -> Vector2:
	var half := GameConfig.TILE_SIZE * 0.5
	return Vector2((grid.x - grid.y) * half.x, (grid.x + grid.y) * half.y)


## 화면 좌표 → 격자 좌표(소수점 포함). 정수 부분이 칸 번호다.
static func screen_to_grid(screen: Vector2) -> Vector2:
	var half := GameConfig.TILE_SIZE * 0.5
	var a := screen.x / half.x
	var b := screen.y / half.y
	return Vector2((a + b) * 0.5, (b - a) * 0.5)


## 칸 중심의 화면 좌표.
static func cell_center(cell: Vector2i) -> Vector2:
	return grid_to_screen(Vector2(cell) + Vector2(0.5, 0.5))


## 칸 마름모의 네 꼭짓점(위, 오른쪽, 아래, 왼쪽).
static func cell_polygon(cell: Vector2i) -> PackedVector2Array:
	var c := Vector2(cell)
	return PackedVector2Array([
		grid_to_screen(c),
		grid_to_screen(c + Vector2(1, 0)),
		grid_to_screen(c + Vector2(1, 1)),
		grid_to_screen(c + Vector2(0, 1)),
	])


## 필드 전체 마름모의 네 꼭짓점(위, 오른쪽, 아래, 왼쪽).
static func field_polygon(cells: Vector2i) -> PackedVector2Array:
	return PackedVector2Array([
		grid_to_screen(Vector2.ZERO),
		grid_to_screen(Vector2(cells.x, 0)),
		grid_to_screen(Vector2(cells)),
		grid_to_screen(Vector2(0, cells.y)),
	])


## 화면 위의 차이(px)를 땅 위의 차이로 편다. 화면 세로는 타일 비율만큼 눌려 있으므로 그만큼 늘린다.
## 땅 위의 거리·각도(시야)는 이걸로 잰다.
static func to_ground(screen_offset: Vector2) -> Vector2:
	return Vector2(screen_offset.x, screen_offset.y * GameConfig.TILE_SIZE.x / GameConfig.TILE_SIZE.y)


## 땅 위에서 잰 거리(px).
## 사거리·도착 판정은 이걸로 한다(그래서 사거리는 화면에서 원이 아니라 납작한 타원이 된다).
static func ground_distance(a: Vector2, b: Vector2) -> float:
	return to_ground(b - a).length()


## 화면에서 본 이동 입력(길이 0~1)을 화면 속도(px/초)로 바꾼다.
## 화면 방향은 입력 그대로 두고, 세로 성분을 vertical_ratio로 펴서 잰 "땅 위 속력"이
## 어느 방향이든 ground_speed가 되도록 맞춘다. 그래서 가로는 제 속력, 세로는 ratio배 속력이 된다.
static func move_velocity(input: Vector2, ground_speed: float, vertical_ratio: float) -> Vector2:
	var length := input.length()
	if length <= 0.0:
		return Vector2.ZERO
	var dir := input / length
	var stretch := sqrt(dir.x * dir.x + pow(dir.y / vertical_ratio, 2.0))
	return dir * (ground_speed * minf(length, 1.0) / stretch)

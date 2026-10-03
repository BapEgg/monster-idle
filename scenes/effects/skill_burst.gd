class_name SkillBurst
extends Node2D
## 스킬 범위 연출(임시 도형): 땅 위 원이 퍼지며 사라진다. 쿼터뷰라 화면에서는 세로가 납작한 타원이다
## (사거리·범위 판정과 같은 모양, Iso.to_ground). 그림 단계에서 종마다 다른 연출로 바꾼다.

const SECONDS := 0.45
const START_SCALE := 0.35
const LINE := 3.0
const POINTS := 40
const FILL_ALPHA := 0.25

## 땅 위 반지름(px). 0이면 작은 고리 하나로 보인다.
var radius := 0.0
var color := Color.WHITE

var _time := 0.0


func _ready() -> void:
	# 물리 프레임이 아니라 화면 프레임으로 퍼지므로 물리 보간을 끈다.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF


func _process(delta: float) -> void:
	_time += delta
	if _time >= SECONDS:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k := _time / SECONDS
	var r := maxf(radius, 24.0) * lerpf(START_SCALE, 1.0, ease(k, 0.4))
	var squash := GameConfig.TILE_SIZE.y / GameConfig.TILE_SIZE.x  # 땅 위 원 → 화면 타원
	var ring := PackedVector2Array()
	for i in POINTS + 1:
		var angle := TAU * i / POINTS
		ring.append(Vector2(cos(angle), sin(angle) * squash) * r)
	var fade := 1.0 - k
	draw_colored_polygon(ring, Color(color, FILL_ALPHA * fade))
	draw_polyline(ring, Color(color, fade), LINE, true)

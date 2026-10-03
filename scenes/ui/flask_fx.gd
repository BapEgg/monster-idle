@tool
class_name FlaskFx
extends Control
## 결과 플라스크 위에 겹쳐 그리는 연출(믹스창, 임시 도형): 실패하면 플라스크에 금이 가고 유리 조각이 떨어지며,
## 안의 주 코어가 운다(눈 밑으로 눈물). 결과 칸(버튼) 안에 두어 흔들림을 같이 받는다. 입력은 받지 않는다.

# 임시 도형 치수(칸 크기에 대한 비율 · px)
const FLASK_RADIUS_RATIO := 0.64
const EYE_POINTS := [Vector2(0.4, 0.47), Vector2(0.6, 0.47)]  # 임시 초상화의 눈 자리(칸 비율)
const TEAR_RADIUS := 5.0
const TEAR_FALL := 0.22  # 눈물이 흘러내리는 길이(칸 높이 비율)
const TEAR_SPEED := 1.2
const CRACK_WIDTH := 2.5
const SHARD_COUNT := 5

## 실패 연출 중인가(금 · 눈물)
var broken := false:
	set(value):
		broken = value
		_since = 0.0
		set_process(value)
		queue_redraw()

var _since := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(broken)


func _process(delta: float) -> void:
	_since += delta
	queue_redraw()


func _draw() -> void:
	if not broken:
		return
	var center := size * 0.5
	var radius := size.x * FLASK_RADIUS_RATIO
	# 금: 오른쪽 위에서 시작해 갈라지는 선 두 갈래
	var start := center + Vector2.from_angle(-PI * 0.3) * radius
	var crack := PackedVector2Array([start, start + Vector2(-14, 18), start + Vector2(-8, 34), start + Vector2(-22, 52), start + Vector2(-18, 70)])
	draw_polyline(crack, Palette.FLASK_CRACK, CRACK_WIDTH, true)
	draw_polyline(PackedVector2Array([crack[1], crack[1] + Vector2(16, 14), crack[1] + Vector2(24, 34)]), Palette.FLASK_CRACK, CRACK_WIDTH * 0.8, true)
	var left := center + Vector2.from_angle(PI * 1.1) * radius
	draw_polyline(PackedVector2Array([left, left + Vector2(16, -6), left + Vector2(28, 6), left + Vector2(40, -2)]), Palette.FLASK_CRACK, CRACK_WIDTH * 0.8, true)
	# 유리 조각: 플라스크 아래로 떨어진다
	for i in SHARD_COUNT:
		var fall := minf(_since * 160.0, 40.0 + i * 6.0)
		var at := center + Vector2((i - SHARD_COUNT * 0.5) * 14.0, radius * 0.9 + fall)
		var tri := PackedVector2Array([at, at + Vector2(7, 3 + i), at + Vector2(2, 9)])
		draw_colored_polygon(tri, Palette.FLASK_GLASS)
	# 눈물: 두 눈 밑에서 방울이 흘러내린다
	for eye: Vector2 in EYE_POINTS:
		var from := eye * size
		var phase := fposmod(_since * TEAR_SPEED, 1.0)
		var drop := from + Vector2(0, size.y * TEAR_FALL * phase + TEAR_RADIUS)
		draw_line(from, drop, Palette.TEAR, 2.0, true)
		draw_circle(drop, TEAR_RADIUS, Palette.TEAR, true, -1.0, true)

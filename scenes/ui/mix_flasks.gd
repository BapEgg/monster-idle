@tool
class_name MixFlasks
extends Control
## 믹스창 가운데 "연성 장치"의 유리 그림(임시 도형, 사용자 결정 2026-10-03: 연구소 플라스크 느낌, 믹스마스터 기계 모양은 쓰지 않는다).
## 주 · 보조 칸 = 비커 두 개(눈금 · 액체), 결과 칸 = 둥근 바닥 플라스크(목 · 액체 · 거품). 비커 밑에서 유리관이 내려와 플라스크 목으로 들어간다.
## 칸 자리는 장면(mix_panel.tscn)의 칸 노드를 따라 그린다 — 에디터에서 칸을 옮기면 유리도 따라간다(@tool).
## 칸 위에 겹쳐 그리지 않도록 이 노드는 칸들보다 먼저(뒤에) 둔다. 입력은 받지 않는다.

## 유리를 둘러 그릴 칸들
@export var main_slot_path: NodePath
@export var sub_slot_path: NodePath
@export var result_slot_path: NodePath

## 비커 안 액체 색(그 칸 코어의 종족 색). 비었으면 투명.
var main_liquid := Color.TRANSPARENT
var sub_liquid := Color.TRANSPARENT
## 재료가 다 찼나(결과 플라스크에 거품이 오른다)
var brewing := false

# 임시 도형 치수(px)
const GLASS_WIDTH := 3.0
const BEAKER_PAD := 8.0
const BEAKER_LIP := 9.0
const BEAKER_TICKS := 4
const BEAKER_LIQUID_RATIO := 0.32
const FLASK_RADIUS_RATIO := 0.64
const FLASK_LIQUID_RATIO := 0.45
const NECK_HALF_WIDTH := 15.0
const NECK_LENGTH := 22.0
const TUBE_WIDTH := 7.0
const LIQUID_ALPHA := 0.32
const BUBBLE_COUNT := 7
const BUBBLE_RADIUS := Vector2(3.0, 6.0)
const BUBBLE_SPEED := 0.45
const ARC_POINTS := 40


func _process(_delta: float) -> void:
	queue_redraw()  # 거품이 움직인다


func _draw() -> void:
	var main_rect := _local_rect(main_slot_path)
	var sub_rect := _local_rect(sub_slot_path)
	var result_rect := _local_rect(result_slot_path)
	if main_rect.size == Vector2.ZERO or sub_rect.size == Vector2.ZERO or result_rect.size == Vector2.ZERO:
		return
	var center := result_rect.get_center()
	var radius := result_rect.size.x * FLASK_RADIUS_RATIO
	var neck_bottom := center.y - radius * 0.92
	var neck_top := neck_bottom - NECK_LENGTH
	_draw_tube(main_rect, Vector2(center.x - NECK_HALF_WIDTH * 0.4, neck_top), main_liquid)
	_draw_tube(sub_rect, Vector2(center.x + NECK_HALF_WIDTH * 0.4, neck_top), sub_liquid)
	_draw_beaker(main_rect, main_liquid, false)
	_draw_beaker(sub_rect, sub_liquid, true)
	_draw_flask(center, radius, neck_top, neck_bottom)


## 칸 노드의 사각형(이 노드 기준). 없으면 빈 사각형.
func _local_rect(path: NodePath) -> Rect2:
	if path.is_empty() or not has_node(path):
		return Rect2()
	var slot := get_node(path) as Control
	if slot == null:
		return Rect2()
	return Rect2(slot.global_position - global_position, slot.size)


## 비커: 칸을 감싸는 위가 열린 유리통 + 바깥쪽 주둥이 + 눈금 + 아래쪽 액체.
func _draw_beaker(slot: Rect2, liquid: Color, spout_right: bool) -> void:
	var body := slot.grow(BEAKER_PAD)
	if liquid.a > 0.0:
		var depth := body.size.y * BEAKER_LIQUID_RATIO
		draw_rect(Rect2(body.position.x, body.end.y - depth, body.size.x, depth), Color(liquid, LIQUID_ALPHA))
	var top_left := body.position
	var top_right := Vector2(body.end.x, body.position.y)
	var lip := Vector2(BEAKER_LIP, -BEAKER_LIP * 0.6)
	var wall := PackedVector2Array()
	if spout_right:
		wall.append_array([top_left, Vector2(body.position.x, body.end.y), body.end, top_right, top_right + lip])
	else:
		wall.append_array([top_left + Vector2(-lip.x, lip.y), top_left, Vector2(body.position.x, body.end.y), body.end, top_right])
	draw_polyline(wall, Palette.FLASK_GLASS, GLASS_WIDTH, true)
	# 눈금: 주둥이 반대쪽 벽 안쪽
	var tick_x := body.position.x + 4.0 if spout_right else body.end.x - 14.0
	for i in BEAKER_TICKS:
		var y := body.end.y - body.size.y * (i + 1) / (BEAKER_TICKS + 1)
		draw_line(Vector2(tick_x, y), Vector2(tick_x + (10.0 if i % 2 == 0 else 6.0), y), Palette.FLASK_SHINE, 2.0)
	# 유리 반사광
	var shine_x := body.end.x - 6.0 if not spout_right else body.position.x + 6.0
	draw_line(Vector2(shine_x, body.position.y + 10.0), Vector2(shine_x, body.position.y + body.size.y * 0.45), Palette.FLASK_SHINE, 2.0, true)


## 유리관: 비커 밑 가운데에서 내려와 플라스크 목으로 꺾여 들어간다. 액체가 있으면 관 안에도 그 색.
func _draw_tube(slot: Rect2, into: Vector2, liquid: Color) -> void:
	var start := Vector2(slot.get_center().x, slot.end.y + BEAKER_PAD)
	var bend := Vector2(start.x, lerpf(start.y, into.y, 0.5))
	var points := PackedVector2Array([start, bend, Vector2(into.x, bend.y), into + Vector2(0, NECK_LENGTH * 0.5)])
	draw_polyline(points, Palette.FLASK_TUBE, TUBE_WIDTH, true)
	draw_polyline(points, Color(liquid, LIQUID_ALPHA * 2.0) if liquid.a > 0.0 else Palette.FLASK_SHINE, TUBE_WIDTH * 0.35, true)


## 둥근 바닥 플라스크: 원 + 목 + 아래쪽 액체(두 재료 색을 섞은 것) + 재료가 다 차면 오르는 거품.
func _draw_flask(center: Vector2, radius: float, neck_top: float, neck_bottom: float) -> void:
	var liquid := _mixed_liquid()
	if liquid.a > 0.0:
		var level := center.y + radius * (1.0 - 2.0 * FLASK_LIQUID_RATIO)
		var half := acos(clampf((level - center.y) / radius, -1.0, 1.0))
		var points := PackedVector2Array()
		for i in ARC_POINTS:
			var angle := PI * 0.5 - half + (2.0 * half) * i / (ARC_POINTS - 1)
			points.append(center + Vector2.from_angle(angle) * radius)
		if points.size() >= 3:
			draw_colored_polygon(points, Color(liquid, LIQUID_ALPHA))
		if brewing:
			_draw_bubbles(center, radius, level, liquid)
	# 유리: 원은 목 자리만 비워 두고 그린다
	var gap := asin(clampf(NECK_HALF_WIDTH / radius, 0.0, 1.0))
	draw_arc(center, radius, -PI * 0.5 + gap, PI * 1.5 - gap, ARC_POINTS * 2, Palette.FLASK_GLASS, GLASS_WIDTH, true)
	var left := center.x - NECK_HALF_WIDTH
	var right := center.x + NECK_HALF_WIDTH
	draw_line(Vector2(left, neck_bottom), Vector2(left, neck_top), Palette.FLASK_GLASS, GLASS_WIDTH, true)
	draw_line(Vector2(right, neck_bottom), Vector2(right, neck_top), Palette.FLASK_GLASS, GLASS_WIDTH, true)
	draw_line(Vector2(left - 4.0, neck_top), Vector2(right + 4.0, neck_top), Palette.FLASK_GLASS, GLASS_WIDTH, true)
	draw_arc(center, radius * 0.8, PI * 1.08, PI * 1.32, 12, Palette.FLASK_SHINE, 3.0, true)


func _draw_bubbles(center: Vector2, radius: float, level: float, liquid: Color) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	for i in BUBBLE_COUNT:
		var phase := fposmod(t * BUBBLE_SPEED + i / float(BUBBLE_COUNT), 1.0)
		var x := center.x + sin(i * 2.3) * radius * 0.45
		var y := lerpf(center.y + radius * 0.8, level, phase)
		var r := lerpf(BUBBLE_RADIUS.x, BUBBLE_RADIUS.y, fposmod(i * 0.37, 1.0))
		draw_arc(Vector2(x, y), r, 0.0, TAU, 12, Color(Palette.FLASK_BUBBLE, 1.0 - phase * 0.6), 1.5, true)
	draw_circle(center + Vector2(0, radius * 0.3), radius * 0.15, Color(liquid.lightened(0.4), 0.15), true, -1.0, true)


## 결과 플라스크 액체 색: 두 비커 색을 섞는다(한쪽만 있으면 그 색).
func _mixed_liquid() -> Color:
	if main_liquid.a > 0.0 and sub_liquid.a > 0.0:
		return main_liquid.lerp(sub_liquid, 0.5)
	if main_liquid.a > 0.0:
		return main_liquid
	return sub_liquid

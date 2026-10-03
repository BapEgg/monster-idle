@tool
class_name MixFlasks
extends Control
## 믹스창 연성 장치의 유리 그림(임시 도형, 사용자 결정 2026-10-03: 연구소 플라스크 느낌, 믹스마스터 기계 모양은 쓰지 않는다).
## 위 = 결과 칸을 감싼 둥근 바닥 플라스크(목 · 액체 · 거품), 아래 = 주 · 보조 칸을 감싼 비커 두 개(눈금 · 액체).
## 비커 위에서 유리관이 올라가 플라스크 양옆으로 들어간다. 관은 평소 비어 있는 회색이고, 믹스하면 비커 액체가 관을 따라
## 차오른다(사용자 결정 2026-10-03: 관 = 믹스 진행 막대 — 끝까지 차면 성공, 멈칫멈칫하다 멈추면 깨져 실패).
## 칸 자리는 장면(mix_panel.tscn)의 칸 노드를 따라 그린다 — 에디터에서 칸을 옮기면 유리도 따라간다(@tool).
## 연출 값(믹스창이 매 프레임 넣어 준다): angle = 플라스크 흔들림(라디안), tube_fill = 관이 찬 정도(0~1, 0 = 빈 회색 관),
## fill_override = 플라스크 액체 높이(0~1, 음수면 보통),
## mix_ready = 믹스할 수 있으면 플라스크 둘레가 은은히 빛남, pulse_main · pulse_sub = 빈 칸이면 비커 둘레가 깜빡여 누르라고 알림,
## cracked = 실패(액체가 탁해지고 빠진다). 금 · 눈물은 결과 칸 위의 FlaskFx가 그린다. 이 노드는 칸들보다 뒤에 둔다. 입력은 받지 않는다.

## 유리를 둘러 그릴 칸들
@export var main_slot_path: NodePath
@export var sub_slot_path: NodePath
@export var result_slot_path: NodePath

## 비커 안 액체 색(그 칸 코어의 종족 색). 비었으면 투명.
var main_liquid := Color.TRANSPARENT
var sub_liquid := Color.TRANSPARENT
## 재료가 다 찼나(결과 플라스크에 거품이 오른다)
var brewing := false
var mix_ready := false
var pulse_main := false
var pulse_sub := false
var cracked := false
var angle := 0.0
var tube_fill := 0.0
var fill_override := -1.0

# 임시 도형 치수(px)
const GLASS_WIDTH := 3.0
const BEAKER_PAD := 8.0
const BEAKER_LIP := 9.0
const BEAKER_TICKS := 4
const BEAKER_LIQUID_RATIO := 0.32
const FLASK_RADIUS_RATIO := 0.64
const FLASK_LIQUID_RATIO := 0.45
const FLASK_BREW_RATIO := 0.6  # 관이 끝까지 찼을 때 플라스크 액체 높이(성공하면 가득 찬다)
const CRACKED_LIQUID_RATIO := 0.18
const NECK_HALF_WIDTH := 15.0
const NECK_LENGTH := 22.0
const TUBE_WIDTH := 7.0
const TUBE_LIQUID_WIDTH := 4.5
const TUBE_LIQUID_ALPHA := 0.9
const LIQUID_ALPHA := 0.32
const BUBBLE_COUNT := 7
const BUBBLE_RADIUS := Vector2(3.0, 6.0)
const BUBBLE_SPEED := 0.45
const ARC_POINTS := 40
const GLOW_WIDTH := 6.0
const PULSE_SPEED := 4.0


func _process(_delta: float) -> void:
	queue_redraw()  # 거품 · 깜빡임 · 흔들림


func _draw() -> void:
	var main_rect := _local_rect(main_slot_path)
	var sub_rect := _local_rect(sub_slot_path)
	var result_rect := _local_rect(result_slot_path)
	if main_rect.size == Vector2.ZERO or sub_rect.size == Vector2.ZERO or result_rect.size == Vector2.ZERO:
		return
	var center := result_rect.get_center()
	var radius := result_rect.size.x * FLASK_RADIUS_RATIO
	_draw_tube(main_rect, center, radius, -1.0, main_liquid)
	_draw_tube(sub_rect, center, radius, 1.0, sub_liquid)
	_draw_beaker(main_rect, main_liquid, false, pulse_main)
	_draw_beaker(sub_rect, sub_liquid, true, pulse_sub)
	draw_set_transform(center, angle)
	_draw_flask(radius)
	draw_set_transform(Vector2.ZERO)


## 칸 노드의 사각형(이 노드 기준, 흔들림 회전은 빼고). 없으면 빈 사각형.
func _local_rect(path: NodePath) -> Rect2:
	if path.is_empty() or not has_node(path):
		return Rect2()
	var slot := get_node(path) as Control
	if slot == null:
		return Rect2()
	return Rect2(slot.global_position - global_position, slot.size)  # 회전(흔들림)은 돌리기 전 자리 기준


## 0~1로 깜빡이는 값(빈 칸 · 준비된 플라스크 빛).
static func _pulse() -> float:
	return 0.5 + 0.5 * sin(Time.get_ticks_msec() / 1000.0 * PULSE_SPEED)


## 비커: 칸을 감싸는 위가 열린 유리통 + 바깥쪽 주둥이 + 눈금 + 아래쪽 액체. 빈 칸이면 둘레가 깜빡인다.
func _draw_beaker(slot: Rect2, liquid: Color, spout_right: bool, pulse: bool) -> void:
	var body := slot.grow(BEAKER_PAD)
	if pulse:
		var glow := Palette.FLASK_PULSE
		glow.a *= _pulse()
		draw_rect(body.grow(GLOW_WIDTH * 0.5), glow, false, GLOW_WIDTH)
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
	# 눈금: 주둥이 반대쪽 벽 바깥(안쪽 글자 · 코어 그림을 가리지 않게)
	for i in BEAKER_TICKS:
		var y := body.end.y - body.size.y * (i + 1) / (BEAKER_TICKS + 1)
		var length := 10.0 if i % 2 == 0 else 6.0
		var x := body.position.x if spout_right else body.end.x
		var outward := -length if spout_right else length
		draw_line(Vector2(x, y), Vector2(x + outward, y), Palette.FLASK_SHINE, 2.0)
	var shine_x := body.end.x - 6.0 if not spout_right else body.position.x + 6.0
	draw_line(Vector2(shine_x, body.position.y + 10.0), Vector2(shine_x, body.position.y + body.size.y * 0.45), Palette.FLASK_SHINE, 2.0, true)


## 유리관: 비커 위 가운데에서 플라스크 가운데 높이까지 올라가 꺾여서 플라스크 옆구리로 들어간다(side = -1 왼쪽 · 1 오른쪽).
## 안쪽은 비어 있는 회색, tube_fill만큼 비커 쪽부터 그 비커 액체 색으로 찬다(깨지면 탁한 색).
func _draw_tube(slot: Rect2, center: Vector2, radius: float, side: float, liquid: Color) -> void:
	var points := tube_points(slot, center, radius, side)
	draw_polyline(points, Palette.FLASK_TUBE, TUBE_WIDTH, true)
	draw_polyline(points, Palette.FLASK_TUBE_EMPTY, TUBE_LIQUID_WIDTH, true)
	if tube_fill <= 0.0:
		return
	var color := liquid if liquid.a > 0.0 else _mixed_liquid()
	if cracked or color.a <= 0.0:
		color = Palette.FLASK_MURKY
	var filled := _cut_polyline(points, tube_fill)
	if filled.size() >= 2:
		draw_polyline(filled, Color(color, TUBE_LIQUID_ALPHA), TUBE_LIQUID_WIDTH, true)
		draw_circle(filled[filled.size() - 1], TUBE_LIQUID_WIDTH * 0.5, Color(color.lightened(0.35), TUBE_LIQUID_ALPHA), true, -1.0, true)


## 관이 지나는 점들: 비커 위 가운데 → 플라스크 가운데 높이 → 플라스크 옆구리.
static func tube_points(slot: Rect2, center: Vector2, radius: float, side: float) -> PackedVector2Array:
	var start := Vector2(slot.get_center().x, slot.position.y - BEAKER_PAD)
	var into := center + Vector2(side * radius * 0.96, 0.0)
	return PackedVector2Array([start, Vector2(start.x, into.y), into])


## 꺾인 선을 처음부터 길이 비율(0~1)만큼만 자른 점들.
static func _cut_polyline(points: PackedVector2Array, ratio: float) -> PackedVector2Array:
	var total := 0.0
	for i in points.size() - 1:
		total += points[i].distance_to(points[i + 1])
	var left := total * clampf(ratio, 0.0, 1.0)
	var cut := PackedVector2Array([points[0]])
	for i in points.size() - 1:
		var length := points[i].distance_to(points[i + 1])
		if left <= length:
			if left > 0.0:
				cut.append(points[i].lerp(points[i + 1], left / length))
			return cut
		cut.append(points[i + 1])
		left -= length
	return cut


## 둥근 바닥 플라스크(원점 = 플라스크 가운데, 흔들림만큼 돌려서 그린다): 액체 + 거품 + 유리 + 목, 준비되면 둘레가 빛남.
func _draw_flask(radius: float) -> void:
	if mix_ready and not cracked:
		var glow := Palette.FLASK_READY
		glow.a *= 0.35 + 0.65 * _pulse()
		draw_arc(Vector2.ZERO, radius + GLOW_WIDTH, 0.0, TAU, ARC_POINTS * 2, glow, GLOW_WIDTH, true)
	var liquid := _mixed_liquid()
	var ratio := FLASK_LIQUID_RATIO
	if fill_override >= 0.0:
		ratio = fill_override
	if cracked:
		liquid = Palette.FLASK_MURKY
		ratio = CRACKED_LIQUID_RATIO
	if liquid.a > 0.0 and ratio > 0.0:
		var level := radius * (1.0 - 2.0 * clampf(ratio, 0.0, 1.0))
		var half := acos(clampf(level / radius, -1.0, 1.0))
		var points := PackedVector2Array()
		for i in ARC_POINTS:
			var a := PI * 0.5 - half + (2.0 * half) * i / (ARC_POINTS - 1)
			points.append(Vector2.from_angle(a) * radius)
		if points.size() >= 3 and half > 0.01:
			draw_colored_polygon(points, Color(liquid, LIQUID_ALPHA if not cracked else 0.6))
		if (brewing or fill_override >= 0.0) and not cracked:
			_draw_bubbles(radius, level, liquid)
	var gap := asin(clampf(NECK_HALF_WIDTH / radius, 0.0, 1.0))
	draw_arc(Vector2.ZERO, radius, -PI * 0.5 + gap, PI * 1.5 - gap, ARC_POINTS * 2, Palette.FLASK_GLASS, GLASS_WIDTH, true)
	var neck_bottom := -radius * 0.92
	var neck_top := neck_bottom - NECK_LENGTH
	draw_line(Vector2(-NECK_HALF_WIDTH, neck_bottom), Vector2(-NECK_HALF_WIDTH, neck_top), Palette.FLASK_GLASS, GLASS_WIDTH, true)
	draw_line(Vector2(NECK_HALF_WIDTH, neck_bottom), Vector2(NECK_HALF_WIDTH, neck_top), Palette.FLASK_GLASS, GLASS_WIDTH, true)
	draw_line(Vector2(-NECK_HALF_WIDTH - 4.0, neck_top), Vector2(NECK_HALF_WIDTH + 4.0, neck_top), Palette.FLASK_GLASS, GLASS_WIDTH, true)
	draw_arc(Vector2.ZERO, radius * 0.8, PI * 1.08, PI * 1.32, 12, Palette.FLASK_SHINE, 3.0, true)


func _draw_bubbles(radius: float, level: float, liquid: Color) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var speed := BUBBLE_SPEED * (3.0 if fill_override >= 0.0 else 1.0)  # 차오를 때는 끓듯이 빨리
	for i in BUBBLE_COUNT:
		var phase := fposmod(t * speed + i / float(BUBBLE_COUNT), 1.0)
		var x := sin(i * 2.3) * radius * 0.45
		var y := lerpf(radius * 0.8, level, phase)
		var r := lerpf(BUBBLE_RADIUS.x, BUBBLE_RADIUS.y, fposmod(i * 0.37, 1.0))
		draw_arc(Vector2(x, y), r, 0.0, TAU, 12, Color(Palette.FLASK_BUBBLE, 1.0 - phase * 0.6), 1.5, true)
	draw_circle(Vector2(0, radius * 0.3), radius * 0.15, Color(liquid.lightened(0.4), 0.15), true, -1.0, true)


## 결과 플라스크 액체 색: 두 비커 색을 섞는다(한쪽만 있으면 그 색).
func _mixed_liquid() -> Color:
	if main_liquid.a > 0.0 and sub_liquid.a > 0.0:
		return main_liquid.lerp(sub_liquid, 0.5)
	if main_liquid.a > 0.0:
		return main_liquid
	return sub_liquid

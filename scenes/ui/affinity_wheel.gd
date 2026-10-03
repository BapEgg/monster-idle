@tool
class_name AffinityWheel
extends Control
## 종족 상성 원(믹스마스터 상성표처럼, 사용자 결정 2026-10-03 추천 A): 8종족을 원 위에 놓고, 강한 상대 쪽으로 화살표.
## 맨 위 = 데이터 첫 종족(용족), 시계 방향으로 "강한 상대"를 따라간다(Affinity.cycle).
## 고른 종족은 흰 고리, 그 종족이 강한 쪽 화살표는 초록 · 그 종족에게 강한 쪽 화살표는 빨강으로 굵게. 종족을 누르면 tribe_pressed.
## 종족 그림은 TribeDb.icon(없으면 색 동그라미). @tool이라 에디터에서도 보인다.

signal tribe_pressed(id: String)

# 임시 UI 치수(원 크기에 대한 비율 · px)
const ORBIT_RATIO := 0.37
const NODE_RATIO := 0.085
const NAME_FONT_SIZE := 15
const CENTER_FONT_SIZE := 22
const LINE := 2.0
const LINE_BOLD := 4.5
const HEAD := 11.0
const HEAD_BOLD := 15.0
const GAP := 6.0
const SELECTED_RING := 3.0

## 고른 종족(바꾸면 다시 그린다)
var selected := "":
	set(value):
		selected = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(queue_redraw)
	if selected == "":
		selected = order()[0] if not order().is_empty() else ""


func _gui_input(event: InputEvent) -> void:
	# 터치는 마우스 누름으로도 들어오므로(emulate_mouse_from_touch) 마우스 누름만 본다
	var press := event as InputEventMouseButton
	if press != null and press.pressed and press.button_index == MOUSE_BUTTON_LEFT:
		var id := tribe_at(press.position)
		if id != "":
			accept_event()
			tribe_pressed.emit(id)


## 원 위 차례(맨 위부터 시계 방향).
func order() -> PackedStringArray:
	var ids := TribeDb.ids()
	return Affinity.cycle(ids[0]) if not ids.is_empty() else PackedStringArray()


func _radius() -> float:
	return minf(size.x, size.y) * NODE_RATIO


## 그 종족 동그라미의 가운데(이 노드 안 좌표).
func center_of(id: String) -> Vector2:
	var list := order()
	var index := list.find(id)
	if index < 0:
		return size * 0.5
	var angle := -PI * 0.5 + TAU * index / list.size()
	return size * 0.5 + Vector2(cos(angle), sin(angle)) * minf(size.x, size.y) * ORBIT_RATIO


## 그 자리(이 노드 안 좌표)의 종족. 없으면 "".
func tribe_at(point: Vector2) -> String:
	for id in order():
		if point.distance_to(center_of(id)) <= _radius() * 1.25:
			return id
	return ""


func _draw() -> void:
	var list := order()
	if list.is_empty():
		return
	var radius := _radius()
	var middle := size * 0.5
	draw_arc(middle, minf(size.x, size.y) * ORBIT_RATIO, 0.0, TAU, 64, Palette.AFFINITY_RING, radius * 1.6, true)
	# 화살표: 각 종족 → 그 종족이 강한 종족(원 위 다음 종족)
	for id in list:
		var target := Affinity.beats(id)
		var color := Palette.AFFINITY_ARROW
		var bold := false
		if id == selected:
			color = Palette.AFFINITY_STRONG
			bold = true
		elif target == selected:
			color = Palette.AFFINITY_WEAK
			bold = true
		_arrow(center_of(id), center_of(target), radius + GAP, color, bold)
	var font := ThemeDB.fallback_font
	for id in list:
		var tribe := TribeDb.get_tribe(id)
		var at := center_of(id)
		draw_circle(at, radius, tribe.color.darkened(0.45), true, -1.0, true)
		var icon := TribeDb.icon(id)
		if icon != null:
			draw_texture_rect(icon, Rect2(at - Vector2.ONE * radius * 0.82, Vector2.ONE * radius * 1.64), false)
		else:
			draw_circle(at, radius * 0.7, tribe.color, true, -1.0, true)
		draw_arc(at, radius, 0.0, TAU, 32, tribe.color, 2.0, true)
		if id == selected:
			draw_arc(at, radius + SELECTED_RING + 1.0, 0.0, TAU, 32, Palette.CARD_SELECTED_BORDER, SELECTED_RING, true)
		# 이름: 원 바깥쪽으로(옆에 있는 종족은 글자 너비만큼 더 밀어 동그라미와 겹치지 않게)
		var outward := (at - middle).normalized()
		var width := font.get_string_size(tribe.name, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_FONT_SIZE).x
		var name_at := at + outward * (radius + GAP * 1.6) + Vector2(outward.x * width * 0.5, outward.y * NAME_FONT_SIZE * 0.7)
		var baseline := name_at + Vector2(-width * 0.5, NAME_FONT_SIZE * 0.35)
		draw_string_outline(font, baseline, tribe.name, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_FONT_SIZE, 4, Palette.TEXT_OUTLINE)
		draw_string(font, baseline, tribe.name, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_FONT_SIZE, Palette.TEXT if id == selected else Palette.TEXT_LABEL)
	# 가운데: 고른 종족 이름(종족 색)
	var chosen := TribeDb.get_tribe(selected)
	if chosen != null:
		var width := font.get_string_size(chosen.name, HORIZONTAL_ALIGNMENT_LEFT, -1, CENTER_FONT_SIZE).x
		draw_string(font, middle + Vector2(-width * 0.5, CENTER_FONT_SIZE * 0.35), chosen.name, HORIZONTAL_ALIGNMENT_LEFT, -1, CENTER_FONT_SIZE, chosen.color.lightened(0.25))


## from → to 화살표(두 동그라미 가장자리 사이, 끝에 삼각형 머리).
func _arrow(from: Vector2, to: Vector2, inset: float, color: Color, bold: bool) -> void:
	var direction := (to - from).normalized()
	var start := from + direction * inset
	var tip := to - direction * inset
	var head := HEAD_BOLD if bold else HEAD
	draw_line(start, tip - direction * head * 0.8, color, LINE_BOLD if bold else LINE, true)
	var side := Vector2(-direction.y, direction.x)
	draw_colored_polygon(PackedVector2Array([tip, tip - direction * head + side * head * 0.55, tip - direction * head - side * head * 0.55]), color)

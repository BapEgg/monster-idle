@tool
class_name WorldMapView
extends Control
## 섬 지도 창 왼쪽의 바다 그림: 섬 8개(data/islands.json의 map 자리, 종족 색 동그라미 + 이름).
## 닫힌 섬 = 회색 + 자물쇠, 지금 섬 = 노란 고리 + "지금", 고른 섬 = 흰 고리. 섬을 누르면 island_pressed.
## 그림이 들어오면 연구 노트 느낌 지도(기획서 7장 화면 콘셉트)로 바꾼다.

signal island_pressed(id: String)

# 임시 UI 치수
const ISLAND_RADIUS_RATIO := 0.075
const NAME_FONT_SIZE := 15
const RING := 3.0
const LOCK_RATIO := 0.7
const CORNER := 12

## 지금 섬 · 고른 섬 · 열렸나(섬 id → bool). 바꾸면 다시 그린다.
var current := "":
	set(value):
		current = value
		queue_redraw()
var selected := "":
	set(value):
		selected = value
		queue_redraw()
var open_ids := {}:
	set(value):
		open_ids = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _gui_input(event: InputEvent) -> void:
	# 터치는 마우스 누름으로도 들어오므로(emulate_mouse_from_touch) 마우스 누름만 본다 — 한 번 누름이 두 번 들어오지 않게
	var press := event as InputEventMouseButton
	if press != null and press.pressed and press.button_index == MOUSE_BUTTON_LEFT:
		var id := island_at(press.position)
		if id != "":
			accept_event()
			island_pressed.emit(id)


## 그 자리(이 노드 안 좌표)의 섬 id. 없으면 "".
func island_at(point: Vector2) -> String:
	for island in IslandDb.islands():
		if point.distance_to(island_center(island.id)) <= _radius() * 1.2:
			return island.id
	return ""


## 섬 동그라미 가운데(이 노드 안 좌표).
func island_center(id: String) -> Vector2:
	var island := IslandDb.get_island(id)
	return island.map_pos * size if island != null else size * 0.5


func _radius() -> float:
	return minf(size.x, size.y) * ISLAND_RADIUS_RATIO


func _draw() -> void:
	var sea := StyleBoxFlat.new()
	sea.bg_color = Palette.MAP_SEA
	sea.set_corner_radius_all(CORNER)
	draw_style_box(sea, Rect2(Vector2.ZERO, size))
	var font := ThemeDB.fallback_font
	var radius := _radius()
	for island in IslandDb.islands():
		var at := island_center(island.id)
		var unlocked: bool = open_ids.get(island.id, island.id == IslandDb.start_island())
		var tribe := TribeDb.get_tribe(island.tribe)
		var fill := tribe.color if tribe != null and unlocked else Palette.MAP_LOCKED
		draw_circle(at + Vector2(0, radius * 0.25), radius, Palette.MAP_SHORE, true, -1.0, true)
		draw_circle(at, radius, fill, true, -1.0, true)
		if island.id == selected:
			draw_arc(at, radius + RING * 2.0, 0.0, TAU, 32, Palette.CARD_SELECTED_BORDER, RING, true)
		if island.id == current:
			draw_arc(at, radius + RING * 0.5, 0.0, TAU, 32, Palette.MAP_HERE, RING, true)
			UiKit.draw_badge(self, at + Vector2(0, -radius - RING * 2.0), Vector2(0.5, 1.0), UiText.MAP_HERE_BADGE, Palette.MAP_HERE, NAME_FONT_SIZE - 3)
		if not unlocked:
			UiKit.draw_lock(self, at + Vector2(0, radius * 0.08), radius * LOCK_RATIO, Palette.JOB_LOCK)
		var width := font.get_string_size(island.name, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_FONT_SIZE).x
		var name_at := at + Vector2(-width * 0.5, radius + NAME_FONT_SIZE + 6.0)
		draw_string_outline(font, name_at, island.name, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_FONT_SIZE, 4, Palette.TEXT_OUTLINE)
		draw_string(font, name_at, island.name, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_FONT_SIZE, Palette.TEXT if unlocked else Palette.TEXT_LABEL)

@tool
class_name Minimap
extends Control
## 미니맵(기획서 7장 확정: 서식지 · 변이 기운 · 매크로 경로 · 보스 위치). 화면 왼쪽 위, 레벨 막대 아래.
## 위 띠 = 지금 섬 · 지역 이름과 레벨대. 아래 = 필드(마름모)를 줄여 그린 것:
## 서식지 = 야생이 돌아가는 자리(옅은 원), 야생 = 점(선공 빨강 · 비선공 흰색), 변이 기운 = 보라 점 + 퍼지는 고리,
## 파티 = 청록 점, 주인공 = 노란 점, 매크로 경로 = 자동 사냥 중 주인공 → 노리는 몹 점선, 섬의 왕 = 큰 빨간 점 + 고리.
## 누르면 섬 지도 창이 열린다(pressed). 자리 · 크기는 hud.tscn에서 끌어서 정한다(@tool이라 에디터에서도 보인다).

signal pressed

# 임시 UI 치수(px)
const HEADER_HEIGHT := 22.0
const HEADER_FONT_SIZE := 13
const PAD := 6.0
const DOT := 2.6
const PLAYER_DOT := 4.2
const BOSS_DOT := 6.0
const HOME_RADIUS := 7.0
const VARIANT_RING := 7.0
const PATH_DASH := 4.0
const CORNER := 8
## 변이 기운 고리가 퍼지는 빠르기
const PULSE_SPEED := 2.5

## 위 띠 글자(지금 섬 · 지역). 바꾸면 다시 그린다.
var title := "":
	set(value):
		title = value
		queue_redraw()
## 필드 바닥 색(섬 종족 색)
var field_tint := Palette.MINIMAP_FIELD
var player: Player

var _time := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	if Engine.is_editor_hint():
		title = "용섬 · 입문 (Lv 1~15)"


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	# 터치는 마우스 누름으로도 들어오므로(emulate_mouse_from_touch) 마우스 누름만 본다 — 한 번 누름이 두 번 들어오지 않게
	var press := event as InputEventMouseButton
	if press != null and press.pressed and press.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		pressed.emit()


## 필드 그림 칸(위 띠 아래).
func map_rect() -> Rect2:
	return Rect2(Vector2(PAD, HEADER_HEIGHT + PAD * 0.5), size - Vector2(PAD * 2.0, HEADER_HEIGHT + PAD * 1.5))


## 필드 화면 좌표 → 미니맵 좌표(필드 마름모가 map_rect에 꽉 차게, 2:1 그대로).
func to_map(world: Vector2) -> Vector2:
	var corners := Iso.field_polygon(GameConfig.FIELD_CELLS)
	var bounds := Rect2(corners[0], Vector2.ZERO)
	for corner in corners:
		bounds = bounds.expand(corner)
	var room := map_rect()
	var factor := minf(room.size.x / bounds.size.x, room.size.y / bounds.size.y)
	var offset := room.position + (room.size - bounds.size * factor) * 0.5
	return offset + (world - bounds.position) * factor


func _draw() -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = Palette.MINIMAP_BG
	box.border_color = Palette.PANEL_BORDER
	box.set_border_width_all(1)
	box.set_corner_radius_all(CORNER)
	draw_style_box(box, Rect2(Vector2.ZERO, size))
	var font := ThemeDB.fallback_font
	var shown := UiKit.fit_text(font, title, size.x - PAD * 2.0, HEADER_FONT_SIZE)
	draw_string(font, Vector2(PAD, HEADER_HEIGHT * 0.5 + HEADER_FONT_SIZE * 0.4), shown, HORIZONTAL_ALIGNMENT_LEFT, -1, HEADER_FONT_SIZE, Palette.TEXT)
	var corners := PackedVector2Array()
	for corner in Iso.field_polygon(GameConfig.FIELD_CELLS):
		corners.append(to_map(corner))
	draw_colored_polygon(corners, Color(field_tint, 0.55))
	Shapes.draw_outline(self, corners, Palette.MINIMAP_EDGE, 1.0)
	if Engine.is_editor_hint() or not is_inside_tree():
		draw_circle(map_rect().get_center(), PLAYER_DOT, Palette.MINIMAP_PLAYER, true, -1.0, true)
		return
	var pulse := fposmod(_time * PULSE_SPEED, 1.0)
	# 서식지(야생이 돌아가는 자리) → 야생 → 변이 기운 → 섬의 왕
	var wilds := get_tree().get_nodes_in_group(Unit.group_name(Unit.Team.WILD))
	for node in wilds:
		var wild := node as Hench
		if wild != null and not wild is Boss:
			draw_circle(to_map(wild.home), HOME_RADIUS, Palette.MINIMAP_HOME, true, -1.0, true)
	for node in wilds:
		var wild := node as Hench
		if wild == null or not wild.is_alive():
			continue
		var at := to_map(wild.position)
		if wild is Boss:
			draw_arc(at, BOSS_DOT + 3.0 + pulse * 4.0, 0.0, TAU, 20, Color(Palette.MINIMAP_BOSS, 1.0 - pulse), 1.5, true)
			draw_circle(at, BOSS_DOT, Palette.MINIMAP_BOSS, true, -1.0, true)
		elif wild.variant:
			draw_arc(at, DOT + pulse * VARIANT_RING, 0.0, TAU, 16, Color(Palette.MINIMAP_VARIANT, 1.0 - pulse), 1.5, true)
			draw_circle(at, DOT + 0.6, Palette.MINIMAP_VARIANT, true, -1.0, true)
		else:
			draw_circle(at, DOT, Palette.MINIMAP_AGGRO if wild.species.aggressive else Palette.MINIMAP_WILD, true, -1.0, true)
	if player == null or not is_instance_valid(player):
		return
	# 매크로 경로: 자동 사냥 중 노리는 몹까지 점선
	var aim: Unit = player.hunt_target if is_instance_valid(player.hunt_target) else null
	if aim != null and aim.is_alive() and not player.control.is_manual():
		draw_dashed_line(to_map(player.position), to_map(aim.position), Palette.MINIMAP_PATH, 1.5, PATH_DASH, true, true)
	for node in get_tree().get_nodes_in_group(Unit.group_name(Unit.Team.PARTY)):
		var ally := node as Unit
		if ally != null and ally != player and ally.is_alive():
			draw_circle(to_map(ally.position), DOT, Palette.MINIMAP_PARTY, true, -1.0, true)
	draw_circle(to_map(player.position), PLAYER_DOT, Palette.MINIMAP_PLAYER, true, -1.0, true)
	draw_arc(to_map(player.position), PLAYER_DOT, 0.0, TAU, 16, Palette.OUTLINE, 1.0, true)

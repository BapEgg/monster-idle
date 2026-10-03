@tool
class_name CommandButton
extends TouchScreenButton
## 지휘 버튼(보스전, 기획서 7장: 역할 그룹 지휘 — 전원 · 근접조 · 원거리조, 끌어서 대상 지정). 보스전 동안만 보인다.
## 누른 채 필드로 끌어다 놓으면 그 무리가 그 자리로 가서 버틴다(몹 위에 놓으면 그 몹을 친다).
## 끌지 않고 떼면 "모여"(버티기를 풀고 다시 주인공을 따라감). 끄는 동안 버튼에서 손가락까지 선을 그린다.
## 근접조 = 사거리가 짧은 헨치(탱커 · 근접딜러), 원거리조 = 나머지(원거리딜러 · 힐러).
## 원점 = 버튼 가운데. 크기는 shape(RectangleShape2D). @tool: 에디터에서도 그려져서 hud.tscn에서 끌어서 자리를 잡을 수 있다.

## 끌어다 놓았을 때(화면 좌표)
signal dragged_to(group: Group, screen_point: Vector2)
## 끌지 않고 뗐을 때
signal tapped(group: Group)

enum Group { ALL, MELEE, RANGED }

const FONT_SIZE := 17
const LINE_WIDTH := 3.0
const TARGET_RADIUS := 16.0

## 어느 무리를 지휘하나(UiText.COMMAND_NAMES 순서)
@export var group := Group.ALL:
	set(value):
		group = value
		queue_redraw()

var _finger := -1  # 이 버튼을 누른 손가락 번호(-1 = 없음)
var _start := Vector2.ZERO
var _finger_at := Vector2.ZERO


func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if not is_visible_in_tree():
		_finger = -1
		return
	var touch := event as InputEventScreenTouch
	if touch != null:
		if touch.pressed and _finger < 0 and Hud.covers(self, touch.position):
			_finger = touch.index
			_start = touch.position
			_finger_at = touch.position
			queue_redraw()
		elif not touch.pressed and touch.index == _finger:
			_finger = -1
			queue_redraw()
			if touch.position.distance_to(_start) >= GameConfig.COMMAND_DRAG_MIN:
				dragged_to.emit(group, touch.position)
			else:
				tapped.emit(group)
		return
	var drag := event as InputEventScreenDrag
	if drag != null and drag.index == _finger:
		_finger_at = drag.position
		queue_redraw()


## 지금 끌고 있나.
func is_dragging() -> bool:
	return _finger >= 0


func _draw() -> void:
	var box_shape := shape as RectangleShape2D
	if box_shape == null:
		return
	var size := box_shape.size
	var box := StyleBoxFlat.new()
	box.bg_color = Palette.COMMAND_BUTTON_DOWN if _finger >= 0 else Palette.COMMAND_BUTTON
	box.border_color = Palette.PANEL_BORDER
	box.set_border_width_all(1)
	box.set_corner_radius_all(roundi(size.y * 0.3))
	draw_style_box(box, Rect2(-size * 0.5, size))
	var text: String = UiText.COMMAND_NAMES[group]
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	draw_string(font, Vector2(-width * 0.5, FONT_SIZE * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Palette.TEXT)
	if _finger >= 0 and _finger_at.distance_to(_start) >= GameConfig.COMMAND_DRAG_MIN:
		var end := to_local(_finger_at)
		draw_line(Vector2.ZERO, end, Palette.COMMAND_LINE, LINE_WIDTH, true)
		draw_arc(end, TARGET_RADIUS, 0.0, TAU, 24, Palette.COMMAND_LINE, LINE_WIDTH, true)

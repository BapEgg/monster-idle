@tool
class_name AutoButton
extends TouchScreenButton
## 오토 버튼: 공격 버튼 위의 작은 버튼(메이플키우기의 Full Auto처럼). 누를 때마다 풀오토 → 세미오토 → 수동.
## 지금 사냥 방식을 글자와 바탕색으로 보여 준다. 원점 = 버튼 가운데. 크기는 shape(RectangleShape2D)의 크기를 따른다.
## 조이스틱을 쥔 채 다른 손가락으로 누를 수 있게(멀티터치) 기본 노드 TouchScreenButton을 쓴다.
## @tool: 에디터에서도 그려져서, hud.tscn을 열고 끌어서 자리를 잡을 수 있다.

const FONT_SIZE := 15

## 보여 줄 사냥 방식. 바꾸면 다시 그린다.
var mode := AutoControl.Mode.FULL_AUTO:
	set(value):
		mode = value
		queue_redraw()


func _draw() -> void:
	var box_shape := shape as RectangleShape2D
	if box_shape == null:
		return
	var size := box_shape.size
	var box := StyleBoxFlat.new()
	box.bg_color = Palette.AUTO_BUTTON_FILLS[mode]
	box.set_corner_radius_all(roundi(size.y * 0.5))
	draw_style_box(box, Rect2(-size * 0.5, size))
	var text: String = UiText.CONTROL_MODE_NAMES[mode]
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	draw_string(font, Vector2(-width * 0.5, FONT_SIZE * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Palette.AUTO_BUTTON_TEXTS[mode])

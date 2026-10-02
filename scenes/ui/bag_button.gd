@tool
class_name BagButton
extends TouchScreenButton
## 가방 버튼(화면 오른쪽 위). 누르면 코어 가방 창을 열고 닫는다. 코어 수를 함께 보여 준다.
## 원점 = 버튼 가운데. 크기는 shape(RectangleShape2D)의 크기를 따른다.
## @tool: 에디터에서도 그려져서, hud.tscn을 열고 끌어서 자리를 잡을 수 있다.

const FONT_SIZE := 15

## 보여 줄 코어 수. 바꾸면 다시 그린다.
var count := 0:
	set(value):
		count = value
		queue_redraw()


func _draw() -> void:
	var box_shape := shape as RectangleShape2D
	if box_shape == null:
		return
	var size := box_shape.size
	var box := StyleBoxFlat.new()
	box.bg_color = Palette.BAG_BUTTON
	box.border_color = Palette.PANEL_BORDER
	box.set_border_width_all(1)
	box.set_corner_radius_all(roundi(size.y * 0.3))
	draw_style_box(box, Rect2(-size * 0.5, size))
	var text := UiText.BAG_BUTTON % count
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	draw_string(font, Vector2(-width * 0.5, FONT_SIZE * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Palette.TEXT)

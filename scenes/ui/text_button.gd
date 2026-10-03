@tool
class_name TextButton
extends TouchScreenButton
## 글자 하나짜리 작은 버튼(화면 오른쪽 위의 디버그 버튼 등). 가방 버튼과 같은 모양.
## 원점 = 버튼 가운데. 크기는 shape(RectangleShape2D)의 크기를 따른다.
## @tool: 에디터에서도 그려져서, hud.tscn을 열고 끌어서 자리를 잡을 수 있다.

const FONT_SIZE := 15

## 보여 줄 글자. 바꾸면 다시 그린다(문구는 UiText에서 넣어 준다).
var text := "":
	set(value):
		text = value
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
	var shown := text
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(shown, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	draw_string(font, Vector2(-width * 0.5, FONT_SIZE * 0.35), shown, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Palette.TEXT)

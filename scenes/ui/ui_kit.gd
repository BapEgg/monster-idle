class_name UiKit
extends RefCounted
## 가방·믹스 창이 함께 쓰는 꾸미기 도우미(글자 크기·색, 창 바탕, 배지). 그림 UI가 들어오면 여기만 바꾼다.

const PANEL_CORNER := 12
const BADGE_FONT_SIZE := 11
const BADGE_PAD := Vector2(4, 1)
const BADGE_CORNER := 6


static func style_label(label: Label, font_size: int, color: Color) -> void:
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)


static func style_button(button: BaseButton, font_size: int) -> void:
	button.add_theme_font_size_override("font_size", font_size)
	button.focus_mode = Control.FOCUS_NONE


## 창 바탕(어두운 반투명 + 얇은 테두리).
static func panel_box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Palette.PANEL_BG
	box.border_color = Palette.PANEL_BORDER
	box.set_border_width_all(1)
	box.set_corner_radius_all(PANEL_CORNER)
	return box


## 작은 둥근 배지(글자 + 바탕색). at = 배지의 기준 모서리, align = 그 모서리가 배지의 어디인가(0,0 = 왼쪽 위 … 1,1 = 오른쪽 아래).
static func draw_badge(canvas: CanvasItem, at: Vector2, align: Vector2, text: String, fill: Color) -> void:
	var font := ThemeDB.fallback_font
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, BADGE_FONT_SIZE)
	var size := Vector2(text_size.x, BADGE_FONT_SIZE) + BADGE_PAD * 2.0
	var rect := Rect2(at - size * align, size)
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.set_corner_radius_all(BADGE_CORNER)
	canvas.draw_style_box(box, rect)
	canvas.draw_string(font, rect.position + Vector2(BADGE_PAD.x, BADGE_PAD.y + BADGE_FONT_SIZE * 0.85), text, HORIZONTAL_ALIGNMENT_LEFT, -1, BADGE_FONT_SIZE, Palette.BADGE_TEXT)

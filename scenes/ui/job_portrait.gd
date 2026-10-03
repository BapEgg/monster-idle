@tool
class_name JobPortrait
extends Control
## 직업 창 왼쪽 위 주인공 그림(임시 도형): 필드의 주인공과 같은 모양(몸 + 머리 + 앞머리 + 눈)을 크게, 몸은 직업 색.
## 그림 단계에서 직업 초상화로 바꾼다. @tool: 에디터에서도 보인다.

## 몸 색(직업 색)
var body_color := Color("5b8fd9"):
	set(value):
		body_color = value
		queue_redraw()


func _draw() -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = Palette.PORTRAIT_BG
	box.border_color = Palette.CARD_BORDER
	box.set_border_width_all(2)
	box.set_corner_radius_all(UiKit.PANEL_CORNER)
	draw_style_box(box, Rect2(Vector2.ZERO, size))
	var k := minf(size.x, size.y) / 100.0  # 임시 도형 치수는 100px 칸 기준
	var center := size * 0.5
	draw_colored_polygon(Shapes.ellipse(center + Vector2(0, 36) * k, Vector2(26, 9) * k), Palette.SHADOW)
	var body := center + Vector2(0, 16) * k
	draw_circle(body, 20.0 * k, body_color, true, -1.0, true)
	draw_arc(body, 20.0 * k, 0.0, TAU, 32, Palette.OUTLINE, 2.0, true)
	var head := center + Vector2(0, -16) * k
	draw_circle(head, 22.0 * k, Palette.PLAYER_SKIN, true, -1.0, true)
	draw_colored_polygon(Shapes.arc(head, 22.0 * k, PI, TAU), Palette.PLAYER_HAIR)
	draw_circle(head + Vector2(-8, 5) * k, 3.0 * k, Palette.OUTLINE, true, -1.0, true)
	draw_circle(head + Vector2(8, 5) * k, 3.0 * k, Palette.OUTLINE, true, -1.0, true)
	draw_arc(head, 22.0 * k, 0.0, TAU, 32, Palette.OUTLINE, 2.0, true)

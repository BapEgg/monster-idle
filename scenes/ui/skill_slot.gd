@tool
class_name SkillSlot
extends TouchScreenButton
## 스킬 칸 하나(사용자 결정 2026-10-02: 공격 버튼 옆 6칸). 지금은 빈 자리이고, 스킬이 생기면 채운다.
## 원점 = 칸 가운데. 크기는 shape(RectangleShape2D)의 크기를 따른다(여섯 칸이 같은 shape를 함께 써서 한 번에 바뀐다).
## @tool: 에디터에서도 그려져서, hud.tscn을 열고 칸마다 끌어서 자리를 잡을 수 있다.

const CORNER := 10
const BORDER := 2


func _draw() -> void:
	var box_shape := shape as RectangleShape2D
	if box_shape == null:
		return
	var box := StyleBoxFlat.new()
	box.bg_color = Palette.SKILL_SLOT
	box.border_color = Palette.SKILL_SLOT_BORDER
	box.set_border_width_all(BORDER)
	box.set_corner_radius_all(CORNER)
	draw_style_box(box, Rect2(-box_shape.size * 0.5, box_shape.size))

class_name SkillSlots
extends Node2D
## 공격 버튼 왼쪽의 스킬 칸(사용자 결정 2026-10-02: 공격 버튼 옆 6칸). 지금은 빈 자리이고, 스킬이 생기면 채운다.
## 원점 = 공격 버튼 가운데. 칸은 공격 버튼 왼쪽에 GameConfig.SKILL_SLOT_COLUMNS칸씩 줄지어 놓는다.

const CORNER := 10
const BORDER := 2


## 칸들의 사각형(원점 기준). 위 줄 왼쪽부터.
func slot_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	var grid := bounds()
	var step := GameConfig.SKILL_SLOT_SIZE + GameConfig.SKILL_SLOT_GAP
	for i in GameConfig.SKILL_SLOT_COUNT:
		@warning_ignore("integer_division")
		var row := i / GameConfig.SKILL_SLOT_COLUMNS
		var column := i % GameConfig.SKILL_SLOT_COLUMNS
		var at := grid.position + Vector2(column * step, row * step)
		rects.append(Rect2(at, Vector2.ONE * GameConfig.SKILL_SLOT_SIZE))
	return rects


## 칸 전체를 감싸는 사각형(원점 기준). 세로로는 공격 버튼 가운데에 맞춘다.
func bounds() -> Rect2:
	var columns := GameConfig.SKILL_SLOT_COLUMNS
	var rows := ceili(float(GameConfig.SKILL_SLOT_COUNT) / columns)
	var step := GameConfig.SKILL_SLOT_SIZE + GameConfig.SKILL_SLOT_GAP
	var size := Vector2(columns * step - GameConfig.SKILL_SLOT_GAP, rows * step - GameConfig.SKILL_SLOT_GAP)
	var right := -(GameConfig.ATTACK_BUTTON_RADIUS + GameConfig.SKILL_SLOTS_GAP_TO_ATTACK)
	return Rect2(Vector2(right - size.x, -size.y * 0.5), size)


func _draw() -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = Palette.SKILL_SLOT
	box.border_color = Palette.SKILL_SLOT_BORDER
	box.set_border_width_all(BORDER)
	box.set_corner_radius_all(CORNER)
	for rect in slot_rects():
		draw_style_box(box, rect)

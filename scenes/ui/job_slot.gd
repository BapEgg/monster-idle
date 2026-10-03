class_name JobSlot
extends Button
## 직업 창 섹터 왼쪽의 장착 칸 하나(사용자 결정 2026-10-03: 액티브 · 패시브 · 궁극기 한 섹터씩, 섹터마다 장착 칸 + 스킬 목록).
## 위 = 네모 칸(장착한 스킬 그림, 비었으면 "+", 아직 안 열렸으면 흐리게 + 빨간 "Lv n"), 아래 = 작은 글(“1번 칸” · “Lv 30에 열림”).
## 고른 스킬이 이 칸에 있으면 흰 테두리, 바꿀 칸을 고르는 중이면 청록 테두리가 깜빡인다.
## 누르면 Button의 pressed(직업 창이 고른 스킬을 이 칸에 장착하거나, 이 칸의 스킬을 고른다).

# 임시 UI 치수(px)
const SIZE := Vector2(72, 92)
const CORNER := 10
const EDGE := 2
const PAD := 5.0
const CAPTION_FONT_SIZE := 12
const PLUS_FONT_SIZE := 28
const BADGE_FONT_SIZE := 12
const DIM_ALPHA := 0.35
## 바꿀 칸 고르기 테두리가 깜빡이는 빠르기
const PULSE_SPEED := 6.0

## 장착한 스킬(빈 칸 = null)
var skill: JobDb.Skill
## 아래 작은 글(“1번 칸” 등)
var caption := ""
## 이 레벨에 열린다(0 = 열림)
var locked_level := 0
## 고른 스킬이 이 칸에 있다(흰 테두리)
var selected := false
## 바꿀 칸을 고르는 중(청록 테두리가 깜빡임)
var picking := false

var _time := 0.0


static func create(of_skill: JobDb.Skill, of_caption: String, of_locked := 0) -> JobSlot:
	var slot := JobSlot.new()
	slot.skill = of_skill
	slot.caption = of_caption
	slot.locked_level = of_locked
	return slot


func is_locked() -> bool:
	return locked_level > 0


func _ready() -> void:
	custom_minimum_size = SIZE
	flat = true
	focus_mode = Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_PASS
	for style: String in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		add_theme_stylebox_override(style, StyleBoxEmpty.new())
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)


func _process(delta: float) -> void:
	if picking:
		_time += delta
		queue_redraw()


func _draw() -> void:
	var box_rect := Rect2(Vector2.ZERO, Vector2(size.x, size.x))
	var box := StyleBoxFlat.new()
	box.bg_color = Palette.CHIP_BG_HOVER if is_hovered() and not is_locked() else Palette.JOB_SLOT_BG
	box.set_corner_radius_all(CORNER)
	if picking:
		box.border_color = Color(Palette.BADGE_PARTY, 0.55 + 0.45 * sin(_time * PULSE_SPEED))
		box.set_border_width_all(EDGE)
	elif selected:
		box.border_color = Palette.CARD_SELECTED_BORDER
		box.set_border_width_all(EDGE)
	else:
		box.border_color = Palette.JOB_SLOT_BORDER
		box.set_border_width_all(1)
	draw_style_box(box, box_rect)
	var font := ThemeDB.fallback_font
	if is_locked():
		UiKit.draw_badge(self, box_rect.get_center(), Vector2(0.5, 0.5), UiText.SKILL_SLOT_LOCKED % locked_level, Color(Palette.JOB_LEVEL_SHORT, 0.8), BADGE_FONT_SIZE)
	elif skill != null:
		var picture := JobDb.icon(skill)
		var inner := box_rect.grow(-PAD - EDGE)
		if picture != null:
			draw_texture_rect(picture, inner, false)
		else:
			var letter := skill.name.substr(0, 1)
			var letter_width := font.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, PLUS_FONT_SIZE).x
			draw_string(font, inner.get_center() + Vector2(-letter_width * 0.5, PLUS_FONT_SIZE * 0.35), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, PLUS_FONT_SIZE, Palette.TEXT)
	else:
		var plus_width := font.get_string_size("+", HORIZONTAL_ALIGNMENT_LEFT, -1, PLUS_FONT_SIZE).x
		draw_string(font, box_rect.get_center() + Vector2(-plus_width * 0.5, PLUS_FONT_SIZE * 0.35), "+", HORIZONTAL_ALIGNMENT_LEFT, -1, PLUS_FONT_SIZE, Color(Palette.TEXT_LABEL, DIM_ALPHA))
	var shown := UiKit.fit_text(font, caption, size.x, CAPTION_FONT_SIZE)
	var width := font.get_string_size(shown, HORIZONTAL_ALIGNMENT_LEFT, -1, CAPTION_FONT_SIZE).x
	draw_string(font, Vector2((size.x - width) * 0.5, box_rect.end.y + CAPTION_FONT_SIZE + 4.0), shown, HORIZONTAL_ALIGNMENT_LEFT, -1, CAPTION_FONT_SIZE, Palette.JOB_LEVEL_SHORT if is_locked() else Palette.TEXT_LABEL)

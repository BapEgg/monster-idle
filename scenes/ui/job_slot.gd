class_name JobSlot
extends Button
## 직업 창 섹터의 큰 장착 칸 하나(사용자 결정 2026-10-03: 장착 칸은 크게 · 굵은 테두리, 미래 칸은 잠긴 모양).
## 위 = 네모 칸(장착한 스킬 그림, 비었으면 "+", 아직 안 열렸으면 회색 + 자물쇠), 아래 = 작은 글("1번 칸" · "Lv 30에 열림").
## 고른 스킬이 이 칸에 있으면 흰 테두리. 장착 모드(칸이 다 차서 바꿀 칸을 고르는 중)에는 청록 테두리 · 바탕이 크게 깜빡인다.
## 누르면 Button의 pressed(직업 창이 고른 스킬을 이 칸에 장착하거나, 이 칸의 스킬을 고른다).

# 임시 UI 치수(px)
const SIZE := Vector2(96, 118)
const CORNER := 12
const EDGE := 3
const PICK_EDGE := 5
const PAD := 7.0
const CAPTION_FONT_SIZE := 13
const PLUS_FONT_SIZE := 34
const LOCK_WIDTH := 28.0
const DIM_ALPHA := 0.35
## 장착 모드 깜빡임 빠르기
const PULSE_SPEED := 7.0

## 장착한 스킬(빈 칸 = null)
var skill: JobDb.Skill
## 아래 작은 글("1번 칸" 등)
var caption := ""
## 이 레벨에 열린다(0 = 열림)
var locked_level := 0
## 고른 스킬이 이 칸에 있다(흰 테두리)
var selected := false
## 장착 모드(바꿀 칸을 고르는 중, 크게 깜빡임)
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
		var pulse := 0.5 + 0.5 * sin(_time * PULSE_SPEED)
		box.border_color = Color(Palette.JOB_PICK_GLOW, 0.5 + 0.5 * pulse)
		box.set_border_width_all(PICK_EDGE)
		box.bg_color = Color(Palette.JOB_PICK_GLOW, 0.08 + 0.14 * pulse)
		box.shadow_color = Color(Palette.JOB_PICK_GLOW, 0.45 * pulse)
		box.shadow_size = 10
	elif selected:
		box.border_color = Palette.CARD_SELECTED_BORDER
		box.set_border_width_all(EDGE)
	else:
		box.border_color = Palette.JOB_SLOT_BORDER if not is_locked() else Color(Palette.JOB_SLOT_BORDER, DIM_ALPHA)
		box.set_border_width_all(EDGE)
	draw_style_box(box, box_rect)
	var font := ThemeDB.fallback_font
	if is_locked():
		UiKit.draw_lock(self, box_rect.get_center() + Vector2(0, 3), LOCK_WIDTH, Color(Palette.JOB_LOCK, 0.6))
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
	draw_string(font, Vector2((size.x - width) * 0.5, box_rect.end.y + CAPTION_FONT_SIZE + 4.0), shown, HORIZONTAL_ALIGNMENT_LEFT, -1, CAPTION_FONT_SIZE, Palette.TEXT_LABEL)

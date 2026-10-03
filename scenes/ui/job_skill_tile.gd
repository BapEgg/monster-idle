class_name JobSkillTile
extends Button
## 직업 창의 스킬 칸 하나(사용자 결정 2026-10-03: 네모 칸에 스킬 그림, 오른쪽 위에 레벨 배지).
## 위 = 네모 그림 칸(JobDb.icon, 그림 파일이 없으면 이름 첫 글자), 아래 = 스킬 이름 + 작은 줄(스킬 레벨 / 배울 수 있음).
## 오른쪽 위 배지: 배웠으면 없음, 주인공 레벨이 모자라면 빨간 "Lv n", 레벨은 됐는데 아직 안 배웠으면 회색 "Lv n".
## 안 배운 칸은 그림을 흐리게. 장착한 칸은 흰 테두리 + 왼쪽 위에 칸 번호. 누르면 Button의 pressed(직업 창이 스킬 상세 창을 연다).

enum State { LEARNED, LEARNABLE, LOCKED }

# 임시 UI 치수(px)
const SIZE := Vector2(96, 128)
const CORNER := 10
const EDGE := 2
const PAD := 4.0
const NAME_FONT_SIZE := 14
const SMALL_FONT_SIZE := 12
const BADGE_FONT_SIZE := 13
const DIM_ALPHA := 0.4

var skill: JobDb.Skill
var state := State.LOCKED
## 스킬 레벨(배웠을 때)
var skill_level := 0
## 장착한 칸 표시(예: "1"). 비우면 장착 안 함.
var slot_badge := ""


static func create(of_skill: JobDb.Skill, of_state: State, of_level: int, of_slot: String) -> JobSkillTile:
	var tile := JobSkillTile.new()
	tile.skill = of_skill
	tile.state = of_state
	tile.skill_level = of_level
	tile.slot_badge = of_slot
	tile.name = of_skill.id
	return tile


## 오른쪽 위 배지 글자(배웠으면 "").
func badge_text() -> String:
	return "" if state == State.LEARNED else UiText.SKILL_SLOT_LOCKED % skill.unlock


func _ready() -> void:
	custom_minimum_size = SIZE
	flat = true
	focus_mode = Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_PASS
	for style: String in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		add_theme_stylebox_override(style, StyleBoxEmpty.new())
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)


func _draw() -> void:
	if skill == null:
		return
	var box_rect := Rect2(Vector2.ZERO, Vector2(size.x, size.x))
	var box := StyleBoxFlat.new()
	box.bg_color = Palette.CHIP_BG_HOVER if is_hovered() else Palette.CHIP_BG
	box.set_corner_radius_all(CORNER)
	var equipped := slot_badge != ""
	box.border_color = Palette.CARD_SELECTED_BORDER if equipped else Palette.CARD_BORDER
	box.set_border_width_all(EDGE if equipped else 1)
	draw_style_box(box, box_rect)
	var inner := box_rect.grow(-PAD - EDGE)
	var picture := JobDb.icon(skill)
	var tint := Color(1, 1, 1, 1.0 if state == State.LEARNED else DIM_ALPHA)
	var font := ThemeDB.fallback_font
	var bold := UiKit.bold_font()
	if picture != null:
		draw_texture_rect(picture, inner, false, tint)
	else:
		var letter := skill.name.substr(0, 1)
		var width := bold.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, 32).x
		draw_string(bold, inner.get_center() + Vector2(-width * 0.5, 12), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color(Palette.TEXT, tint.a))
	# 오른쪽 위 레벨 배지: 레벨이 모자라면 빨강, 됐는데 안 배웠으면 회색
	if state != State.LEARNED:
		UiKit.draw_badge(self, Vector2(box_rect.end.x - 3.0, 3.0), Vector2(1, 0), badge_text(), Palette.JOB_LEVEL_SHORT if state == State.LOCKED else Palette.JOB_LEVEL_READY, BADGE_FONT_SIZE)
	# 왼쪽 위 장착 칸 번호
	if equipped:
		UiKit.draw_badge(self, Vector2(3.0, 3.0), Vector2.ZERO, slot_badge, Palette.BADGE_PARTY, BADGE_FONT_SIZE)
	# 아래: 이름 + 작은 줄
	var name_color := Palette.TEXT if state == State.LEARNED else Palette.TEXT_LABEL
	var shown := UiKit.fit_text(font, skill.name, size.x, NAME_FONT_SIZE)
	var name_width := font.get_string_size(shown, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_FONT_SIZE).x
	draw_string(font, Vector2((size.x - name_width) * 0.5, box_rect.end.y + NAME_FONT_SIZE + 2.0), shown, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_FONT_SIZE, name_color)
	var small := ""
	match state:
		State.LEARNED:
			small = UiText.JOB_TILE_LEVEL % [skill_level, GameConfig.JOB_SKILL_MAX_LEVEL]
		State.LEARNABLE:
			small = UiText.JOB_TILE_LEARNABLE
	if small != "":
		var small_width := font.get_string_size(small, HORIZONTAL_ALIGNMENT_LEFT, -1, SMALL_FONT_SIZE).x
		draw_string(font, Vector2((size.x - small_width) * 0.5, box_rect.end.y + NAME_FONT_SIZE + SMALL_FONT_SIZE + 6.0), small, HORIZONTAL_ALIGNMENT_LEFT, -1, SMALL_FONT_SIZE, Palette.JOB_LEVEL_READY_TEXT if state == State.LEARNABLE else Palette.TEXT_LABEL)

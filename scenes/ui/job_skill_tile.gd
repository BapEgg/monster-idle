class_name JobSkillTile
extends Button
## 직업 창 섹터 오른쪽 스킬 목록의 작은 카드 하나(사용자 결정 2026-10-03: 장착 칸은 크게, 목록은 작은 카드).
## 위 = 네모 그림 칸(JobDb.icon, 그림 파일이 없으면 이름 첫 글자), 아래 = 스킬 이름 + 상태 줄. 상태:
## - 잠김(주인공 레벨이 모자람): 카드 전체 회색(grayscale.gdshader) + 자물쇠 + 필요 레벨 "Lv n"
## - 배울 수 있음(레벨은 됐는데 안 배움): 빛나는 테두리(깜빡임) + 오른쪽 위 "+" 배지
## - 배움: 컬러 + 아래 레벨 점(스킬 레벨만큼 켜짐, 최고 레벨 수만큼)
## - 장착 중: 왼쪽 위에 칸 번호 배지(궁극기는 "장착")
## 고른 카드는 흰 테두리 + 체크(사용자 결정 2026-10-03: 고른 것 표시 통일). 누르면 Button의 pressed(직업 창이 고르고, 고른 카드를 다시 누르면 미리보기).

enum State { LEARNED, LEARNABLE, LOCKED }

const GRAYSCALE := preload("res://scenes/ui/grayscale.gdshader")
# 임시 UI 치수(px)
const SIZE := Vector2(72, 100)
const CORNER := 9
const EDGE := 2
const GLOW_EDGE := 3
const PAD := 4.0
const NAME_FONT_SIZE := 13
const BADGE_FONT_SIZE := 11
const CHECK_RADIUS := 8.0
const LOCK_WIDTH := 22.0
const PLUS_RADIUS := 9.0
const DOT_RADIUS := 2.4
const DOT_GAP := 6.2
const DIM_ALPHA := 0.55
## 배울 수 있음 테두리가 깜빡이는 빠르기
const GLOW_SPEED := 4.0

var skill: JobDb.Skill
var state := State.LOCKED
## 스킬 레벨(배웠을 때)
var skill_level := 0
## 장착한 칸 표시(예: "1"). 비우면 장착 안 함.
var slot_badge := ""
## 직업 창에서 고른 카드(흰 테두리 + 체크)
var selected := false

var _time := 0.0


static func create(of_skill: JobDb.Skill, of_state: State, of_level: int, of_slot: String, is_selected := false) -> JobSkillTile:
	var tile := JobSkillTile.new()
	tile.skill = of_skill
	tile.state = of_state
	tile.skill_level = of_level
	tile.slot_badge = of_slot
	tile.selected = is_selected
	tile.name = of_skill.id
	return tile


## 잠긴 카드의 필요 레벨 글자(잠기지 않았으면 "").
func badge_text() -> String:
	return UiText.SKILL_SLOT_LOCKED % skill.unlock if state == State.LOCKED else ""


## 켜진 레벨 점 수(배운 스킬만).
func lit_dots() -> int:
	return skill_level if state == State.LEARNED else 0


func _ready() -> void:
	custom_minimum_size = SIZE
	flat = true
	focus_mode = Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_PASS
	for style: String in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		add_theme_stylebox_override(style, StyleBoxEmpty.new())
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	if state == State.LOCKED:
		var gray := ShaderMaterial.new()
		gray.shader = GRAYSCALE
		material = gray


func _process(delta: float) -> void:
	if state == State.LEARNABLE:
		_time += delta
		queue_redraw()


func _draw() -> void:
	if skill == null:
		return
	var box_rect := Rect2(Vector2.ZERO, Vector2(size.x, size.x))
	var box := StyleBoxFlat.new()
	box.bg_color = Palette.CHIP_BG_HOVER if is_hovered() else Palette.CHIP_BG
	box.set_corner_radius_all(CORNER)
	if selected:
		box.border_color = Palette.CARD_SELECTED_BORDER
		box.set_border_width_all(EDGE)
	elif state == State.LEARNABLE:
		box.border_color = Color(Palette.JOB_LEARNABLE_GLOW, 0.55 + 0.45 * sin(_time * GLOW_SPEED))
		box.set_border_width_all(GLOW_EDGE)
		box.shadow_color = Color(Palette.JOB_LEARNABLE_GLOW, 0.35)
		box.shadow_size = 6
	else:
		box.border_color = Palette.CARD_BORDER
		box.set_border_width_all(1)
	draw_style_box(box, box_rect)
	var inner := box_rect.grow(-PAD - EDGE)
	var picture := JobDb.icon(skill)
	var tint := Color(1, 1, 1, DIM_ALPHA if state == State.LOCKED else 1.0)
	var font := ThemeDB.fallback_font
	var bold := UiKit.bold_font()
	if picture != null:
		draw_texture_rect(picture, inner, false, tint)
	else:
		var letter := skill.name.substr(0, 1)
		var width := bold.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x
		draw_string(bold, inner.get_center() + Vector2(-width * 0.5, 10), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(Palette.TEXT, tint.a))
	match state:
		State.LOCKED:
			UiKit.draw_lock(self, box_rect.get_center() + Vector2(0, 2), LOCK_WIDTH, Palette.JOB_LOCK)
			UiKit.draw_badge(self, Vector2(box_rect.end.x - 3.0, 3.0), Vector2(1, 0), badge_text(), Palette.JOB_LEVEL_READY, BADGE_FONT_SIZE)
		State.LEARNABLE:
			var plus_at := Vector2(box_rect.end.x - PLUS_RADIUS - 1.0, PLUS_RADIUS + 1.0)
			var arm := PLUS_RADIUS * 0.55
			draw_circle(plus_at, PLUS_RADIUS, Palette.JOB_LEARNABLE_GLOW, true, -1.0, true)
			draw_line(plus_at - Vector2(arm, 0), plus_at + Vector2(arm, 0), Palette.CHECK_MARK, 2.5, true)
			draw_line(plus_at - Vector2(0, arm), plus_at + Vector2(0, arm), Palette.CHECK_MARK, 2.5, true)
	if slot_badge != "":
		UiKit.draw_badge(self, Vector2(3.0, 3.0), Vector2.ZERO, slot_badge, Palette.BADGE_PARTY, BADGE_FONT_SIZE)
	if selected:
		UiKit.draw_check(self, box_rect.end - Vector2.ONE * (CHECK_RADIUS + 3.0), CHECK_RADIUS)
	# 아래: 이름 + (배웠으면) 레벨 점
	var name_color := Palette.TEXT if state != State.LOCKED else Palette.TEXT_LABEL
	var shown := UiKit.fit_text(font, skill.name, size.x, NAME_FONT_SIZE)
	var name_width := font.get_string_size(shown, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_FONT_SIZE).x
	draw_string(font, Vector2((size.x - name_width) * 0.5, box_rect.end.y + NAME_FONT_SIZE + 1.0), shown, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_FONT_SIZE, name_color)
	if state == State.LEARNED:
		var count := GameConfig.JOB_SKILL_MAX_LEVEL
		var start := (size.x - DOT_GAP * (count - 1)) * 0.5
		var y := box_rect.end.y + NAME_FONT_SIZE + 9.0
		for i in count:
			draw_circle(Vector2(start + DOT_GAP * i, y), DOT_RADIUS, Palette.JOB_LEVEL_DOT_ON if i < skill_level else Palette.JOB_LEVEL_DOT_OFF, true, -1.0, true)

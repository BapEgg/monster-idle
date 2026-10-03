@tool
class_name SkillChip
extends Button
## 코어 정보창의 스킬 카드 하나(사용자 결정 2026-10-03: HP 막대 오른쪽에 액티브 · 패시브 · 변이를 잘 보이게, 누르면 스킬 상세 창).
## 왼쪽 = 색 네모 + 한 글자(액 · 패 · 변 · 계), 가운데 = 작은 이름표(회색) 위 + 스킬 이름(흰색 굵게) 아래, 오른쪽 = "›"(눌러 볼 수 있음).
## 누르면 Button의 pressed 신호. 무엇을 보여 줄지는 정보창이 sheet(SkillSheet 내용)로 넣어 준다.
## @tool: 에디터에서도 예시 글자로 그려진다.

const CAPTION_FONT_SIZE := 13
const TITLE_FONT_SIZE := 17
const GLYPH_FONT_SIZE := 15
# 임시 도형 치수(px)
const CORNER := 8
const GLYPH_SIZE := 30.0
const PAD := 8.0
const CHEVRON_WIDTH := 14.0

## 아이콘 종류(UiText.CHIP_GLYPHS의 키): active · passive · variant · inherit
@export var glyph := "active":
	set(value):
		glyph = value
		queue_redraw()
var caption := "":
	set(value):
		caption = value
		queue_redraw()
var title := "":
	set(value):
		title = value
		queue_redraw()
## 네모 색(액티브 = 효과 종류 색, 패시브 · 변이 · 계승은 정해진 색)
var accent := Palette.CHIP_PASSIVE:
	set(value):
		accent = value
		queue_redraw()
## 누르면 상세 창에 띄울 내용(SkillSheet)
var sheet := {}


func _ready() -> void:
	flat = true
	focus_mode = Control.FOCUS_NONE
	for state: String in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	button_down.connect(queue_redraw)
	button_up.connect(queue_redraw)


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var box := StyleBoxFlat.new()
	box.bg_color = Palette.CHIP_BG_DOWN if is_pressed() else (Palette.CHIP_BG_HOVER if is_hovered() else Palette.CHIP_BG)
	box.border_color = Color(accent, 0.55)
	box.set_border_width_all(1)
	box.border_width_left = 3
	box.set_corner_radius_all(CORNER)
	draw_style_box(box, rect)
	var font := ThemeDB.fallback_font
	var bold := UiKit.bold_font()
	# 색 네모 + 한 글자
	var square := Rect2(Vector2(PAD + 2.0, (size.y - GLYPH_SIZE) * 0.5), Vector2.ONE * GLYPH_SIZE)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(accent, 0.85)
	fill.set_corner_radius_all(6)
	draw_style_box(fill, square)
	var letter: String = UiText.CHIP_GLYPHS.get(glyph, "")
	var letter_width := bold.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, GLYPH_FONT_SIZE).x
	draw_string(bold, square.get_center() + Vector2(-letter_width * 0.5, GLYPH_FONT_SIZE * 0.36), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, GLYPH_FONT_SIZE, Palette.CHIP_GLYPH)
	# 이름표 + 스킬 이름(넘치면 줄임표)
	var left := square.end.x + PAD
	var room := size.x - left - CHEVRON_WIDTH - PAD
	var shown_caption := caption if not Engine.is_editor_hint() else UiText.CHIP_ACTIVE
	var shown_title := title if not Engine.is_editor_hint() else "매운 박치기"
	var middle := size.y * 0.5
	draw_string(font, Vector2(left, middle - 3.0), shown_caption, HORIZONTAL_ALIGNMENT_LEFT, room, CAPTION_FONT_SIZE, Palette.TEXT_LABEL)
	draw_string(bold, Vector2(left, middle + TITLE_FONT_SIZE - 1.0), UiKit.fit_text(bold, shown_title, room, TITLE_FONT_SIZE), HORIZONTAL_ALIGNMENT_LEFT, -1, TITLE_FONT_SIZE, Palette.TEXT)
	# "›"
	var chevron := Vector2(size.x - PAD - CHEVRON_WIDTH * 0.5, middle)
	draw_polyline(PackedVector2Array([chevron + Vector2(-3, -6), chevron + Vector2(3, 0), chevron + Vector2(-3, 6)]), Palette.TEXT_LABEL, 2.0, true)

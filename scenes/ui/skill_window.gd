class_name SkillWindow
extends Control
## 스킬 상세 창(툴팁, 사용자 결정 2026-10-03: 롤 툴팁처럼). 보기 전용이다(장착 · 레벨 올리기는 직업 창 아래 행동 줄에서).
## 코어 정보창의 스킬 카드(액티브 · 패시브 · 변이 · 믹스 계승)나 직업 창의 "미리보기"를 누르면 뜬다. 뒤를 어둡게 덮고, 덮개나 닫기를 누르면 닫힌다.
## 위 = 이름 + 꼬리표(액티브/패시브/궁극기 · 근접/원거리 · 단일/범위/자신) + 오른쪽 스킬 레벨.
## 왼쪽 = 모션 미리보기(SkillPreview, 임시 도형), 오른쪽 = 마나 · 재사용 대기 · 사거리 한 줄 / 설명 문장(계산된 숫자 + 스탯 색 계수) /
## 다음 레벨 비교 / 개발 문구(디버그 화면에서 켰을 때만). 상태이상 낱말(굵게 · 밑줄)을 누르면 뜻 말풍선이 뜬다.
## 내용은 SkillSheet가 만든다. 자리 · 크기는 skill_window.tscn을 에디터로 열어 바꾼다.

const TITLE_FONT_SIZE := 26
const TAG_FONT_SIZE := 14
const LEVEL_FONT_SIZE := 18
const LINE_FONT_SIZE := 16
const TEXT_FONT_SIZE := 18
const NEXT_FONT_SIZE := 15
const NOTE_FONT_SIZE := 14
const TAG_PAD := Vector2(8, 2)
const TAG_CORNER := 6
const BUBBLE_PAD := 10.0
const BUBBLE_GAP := 14.0

@onready var _shade: ColorRect = %Shade
@onready var _panel: PanelContainer = %Panel
@onready var _title: Label = %Title
@onready var _tags: HBoxContainer = %Tags
@onready var _level: Label = %Level
@onready var _close: Button = %Close
@onready var _preview: SkillPreview = %Preview
@onready var _preview_caption: Label = %PreviewCaption
@onready var _line: RichTextLabel = %Line
@onready var _line_rule: HSeparator = %LineRule
@onready var _description: RichTextLabel = %Description
@onready var _next: RichTextLabel = %Next
@onready var _dev: RichTextLabel = %Dev
@onready var _bubble: PanelContainer = %TermBubble
@onready var _bubble_text: RichTextLabel = %TermText


func _ready() -> void:
	_panel.add_theme_stylebox_override("panel", UiKit.panel_box())
	_shade.color = Palette.MODAL_SHADE
	UiKit.style_label(_title, TITLE_FONT_SIZE, Palette.TEXT)
	_title.add_theme_font_override("font", UiKit.bold_font())
	UiKit.style_label(_level, LEVEL_FONT_SIZE, Palette.TEXT)
	_level.add_theme_font_override("font", UiKit.bold_font())
	UiKit.style_caption(_preview_caption, NOTE_FONT_SIZE)
	UiKit.style_button(_close, TEXT_FONT_SIZE)
	_close.text = UiText.SKILL_CLOSE
	_preview_caption.text = UiText.SKILL_MOTION_CAPTION
	_style_rich(_line, LINE_FONT_SIZE, Palette.TEXT_LABEL)
	_style_rich(_description, TEXT_FONT_SIZE, Palette.TEXT)
	_style_rich(_next, NEXT_FONT_SIZE, Palette.SKILL_NEXT)
	_style_rich(_dev, NOTE_FONT_SIZE, Palette.TEXT_LABEL)
	_style_rich(_bubble_text, NOTE_FONT_SIZE + 1, Palette.TEXT)
	for rich: RichTextLabel in [_description, _next, _dev]:
		rich.meta_clicked.connect(func(meta: Variant) -> void: show_term(str(meta)))
	var bubble := StyleBoxFlat.new()
	bubble.bg_color = Palette.TERM_BUBBLE_BG
	bubble.border_color = Palette.STATUS_TERM
	bubble.set_border_width_all(1)
	bubble.set_corner_radius_all(TAG_CORNER)
	bubble.set_content_margin_all(BUBBLE_PAD)
	_bubble.add_theme_stylebox_override("panel", bubble)
	_close.pressed.connect(hide)
	_shade.gui_input.connect(func(event: InputEvent) -> void:
		if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.is_pressed():
			hide())
	visibility_changed.connect(func() -> void:
		if not visible:
			_bubble.hide())


## RichTextLabel 글자 크기 · 굵은 글꼴 · 기본 색.
static func _style_rich(rich: RichTextLabel, font_size: int, color: Color) -> void:
	rich.add_theme_font_size_override("normal_font_size", font_size)
	rich.add_theme_font_size_override("bold_font_size", font_size)
	rich.add_theme_font_override("bold_font", UiKit.bold_font())
	rich.add_theme_color_override("default_color", color)
	rich.selection_enabled = false


## 뜻 말풍선이 떠 있으면 다음 누름에 닫는다(상태이상 낱말을 누르면 그 뒤에 새로 뜬다).
func _input(event: InputEvent) -> void:
	if _bubble.visible and (event is InputEventMouseButton or event is InputEventScreenTouch) and event.is_pressed():
		_bubble.hide()


## 띄운다. sheet = SkillSheet 내용, caster = 시전자 색(종족 · 직업 색).
func open(sheet: Dictionary, caster: Color) -> void:
	if sheet.is_empty():
		return
	_bubble.hide()
	_title.text = sheet.get("title", "")
	for child in _tags.get_children():
		_tags.remove_child(child)
		child.queue_free()
	for tag: String in sheet.get("tags", PackedStringArray()):
		_tags.add_child(_tag_chip(tag))
	_level.text = sheet.get("level", "")
	_level.visible = _level.text != ""
	_level.add_theme_color_override("font_color", _level_color(str(sheet.get("level_state", ""))))
	_line.text = sheet.get("line", "")
	_line.visible = _line.text != ""
	_line_rule.visible = _line.visible
	_description.text = sheet.get("body", "")
	_next.text = sheet.get("next", "")
	_next.visible = _next.text != ""
	_dev.text = sheet.get("dev", "")
	_dev.visible = SkillSheet.dev_notes and _dev.text != ""
	var motion := str(sheet.get("motion", ""))
	_preview.show_sheet(sheet, caster, effect_color(motion))
	show()


static func _tag_chip(text: String) -> Label:
	var chip := Label.new()
	UiKit.style_label(chip, TAG_FONT_SIZE, Palette.TEXT)
	chip.text = text
	var box := StyleBoxFlat.new()
	box.bg_color = Palette.SKILL_TAG_BG
	box.set_corner_radius_all(TAG_CORNER)
	box.content_margin_left = TAG_PAD.x
	box.content_margin_right = TAG_PAD.x
	box.content_margin_top = TAG_PAD.y
	box.content_margin_bottom = TAG_PAD.y
	chip.add_theme_stylebox_override("normal", box)
	return chip


static func _level_color(state: String) -> Color:
	match state:
		"learnable":
			return Palette.SKILL_LEVEL_LEARNABLE
		"locked":
			return Palette.SKILL_LEVEL_LOCKED
	return Palette.SKILL_LEVEL_LEARNED


## 상태이상 낱말의 뜻 말풍선을 누른 자리 곁에 띄운다(id = UiText.STATUS_TERMS의 키).
func show_term(id: String) -> void:
	if not UiText.STATUS_TERMS.has(id):
		return
	var term: Array = UiText.STATUS_TERMS[id]
	_bubble_text.text = "[b][color=#%s]%s[/color][/b]  %s" % [Palette.STATUS_TERM.to_html(false), term[0], term[1]]
	_bubble.reset_size()
	var at := get_global_mouse_position() + Vector2(0, BUBBLE_GAP)
	var room := get_viewport_rect().size
	_bubble.global_position = Vector2(clampf(at.x - _bubble.size.x * 0.5, 0.0, room.x - _bubble.size.x), minf(at.y, room.y - _bubble.size.y))
	_bubble.show()


## 미리보기 효과 색: 액티브는 효과 종류 색, 패시브 · 변이 · 계승은 스킬 카드 색과 같다.
static func effect_color(motion: String) -> Color:
	match motion:
		SkillSheet.MOTION_PASSIVE:
			return Palette.CHIP_PASSIVE
		SkillSheet.MOTION_VARIANT:
			return Palette.CHIP_VARIANT
		SkillSheet.MOTION_INHERIT:
			return Palette.CHIP_INHERIT
	return Palette.SKILL_COLORS.get(motion, Palette.CHIP_PASSIVE)


# ─── 실행 검사용 ──────────────────────────────────

## 보이는 글: [꼬리표들(" · "로 이음), 이름, 설명 글자].
func texts() -> PackedStringArray:
	return PackedStringArray([" · ".join(tag_texts()), _title.text, body_text()])


func tag_texts() -> PackedStringArray:
	var list := PackedStringArray()
	for chip: Label in _tags.get_children():
		if not chip.is_queued_for_deletion():
			list.append(chip.text)
	return list


func level_text() -> String:
	return _level.text if _level.visible else ""


func line_text() -> String:
	return _line.get_parsed_text() if _line.visible else ""


func body_text() -> String:
	return _description.get_parsed_text()


func body_bbcode() -> String:
	return _description.text


func next_text() -> String:
	return _next.get_parsed_text() if _next.visible else ""


func dev_visible() -> bool:
	return _dev.visible


func term_text() -> String:
	return _bubble_text.get_parsed_text() if _bubble.visible else ""


## 미리보기 종류.
func preview_motion() -> String:
	return _preview.motion

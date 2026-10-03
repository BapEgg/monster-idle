class_name SkillWindow
extends Control
## 스킬 상세 창(사용자 결정 2026-10-03: 롤처럼 스킬을 누르면 모션 미리보기 · 설명 · 계수).
## 코어 정보창의 스킬 카드(액티브 · 패시브 · 변이 · 믹스 계승)를 누르면 뜬다. 뒤를 어둡게 덮고, 덮개나 닫기를 누르면 닫힌다.
## 왼쪽 = 모션 미리보기(SkillPreview, 임시 도형), 오른쪽 = 설명 한 줄 + 계수 표(이름표 회색 · 값 흰색 굵게) + 작은 안내.
## 내용은 SkillSheet가 만든다. 나중에 주인공 직업 스킬을 고르는(장착) 창도 이 창을 다시 쓴다.
## 자리 · 크기는 skill_window.tscn을 에디터에서 열어 바꾼다.

const TAG_FONT_SIZE := 15
const TITLE_FONT_SIZE := 26
const TEXT_FONT_SIZE := 18
const ROW_FONT_SIZE := 17
const NOTE_FONT_SIZE := 14

@onready var _shade: ColorRect = %Shade
@onready var _panel: PanelContainer = %Panel
@onready var _tag: Label = %Tag
@onready var _title: Label = %Title
@onready var _close: Button = %Close
@onready var _preview: SkillPreview = %Preview
@onready var _preview_caption: Label = %PreviewCaption
@onready var _description: Label = %Description
@onready var _rows: GridContainer = %Rows
@onready var _note: Label = %Note


func _ready() -> void:
	_panel.add_theme_stylebox_override("panel", UiKit.panel_box())
	_shade.color = Palette.MODAL_SHADE
	UiKit.style_label(_tag, TAG_FONT_SIZE, Palette.TEXT_LABEL)
	UiKit.style_label(_title, TITLE_FONT_SIZE, Palette.TEXT)
	_title.add_theme_font_override("font", UiKit.bold_font())
	UiKit.style_label(_description, TEXT_FONT_SIZE, Palette.TEXT)
	UiKit.style_caption(_preview_caption, NOTE_FONT_SIZE)
	UiKit.style_caption(_note, NOTE_FONT_SIZE)
	UiKit.style_button(_close, TEXT_FONT_SIZE)
	_close.text = UiText.SKILL_CLOSE
	_preview_caption.text = UiText.SKILL_MOTION_CAPTION
	_close.pressed.connect(hide)
	_shade.gui_input.connect(func(event: InputEvent) -> void:
		if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.is_pressed():
			hide())


## 띄운다. sheet = SkillSheet 내용, caster = 시전자 색(종족 색).
func open(sheet: Dictionary, caster: Color) -> void:
	if sheet.is_empty():
		return
	_tag.text = sheet.get("tag", "")
	_title.text = sheet.get("title", "")
	_description.text = sheet.get("description", "")
	_note.text = sheet.get("note", "")
	_note.visible = _note.text != ""
	for child in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	for row: Array in sheet.get("rows", []):
		var caption := Label.new()
		UiKit.style_caption(caption, ROW_FONT_SIZE)
		caption.text = row[0]
		var value := Label.new()
		UiKit.style_number(value, ROW_FONT_SIZE)
		value.text = row[1]
		value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_rows.add_child(caption)
		_rows.add_child(value)
	var motion := str(sheet.get("motion", ""))
	_preview.show_sheet(sheet, caster, effect_color(motion))
	show()


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


## 보이는 글(실행 검사용): [꼬리표, 이름, 설명].
func texts() -> PackedStringArray:
	return PackedStringArray([_tag.text, _title.text, _description.text])


## 계수 표의 [이름표, 값] 줄들(실행 검사용).
func row_texts() -> Array:
	var rows := []
	for i in range(0, _rows.get_child_count(), 2):
		rows.append([(_rows.get_child(i) as Label).text, (_rows.get_child(i + 1) as Label).text])
	return rows


## 미리보기 종류(실행 검사용).
func preview_motion() -> String:
	return _preview.motion

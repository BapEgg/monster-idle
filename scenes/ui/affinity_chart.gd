class_name AffinityChart
extends Control
## 종족 상성표 창(사용자 결정 2026-10-03, 추천 A): 가방 창의 "상성표" 버튼이나 코어 정보창의 상성 줄을 누르면 열린다.
## 왼쪽 = 상성 원(AffinityWheel), 오른쪽 = 고른 종족: 이름(종족 색) · 주제 · ▲ 강한 상대와 까닭 · ▼ 약한 상대와 까닭, 아래 = 피해 배율 설명.
## 원에서 종족을 누르면 그 종족을 고른다. 어두운 덮개나 닫기를 누르면 닫힌다. 위치 · 크기는 affinity_chart.tscn에서.

const TITLE_FONT_SIZE := 24
const NAME_FONT_SIZE := 30
const TEXT_FONT_SIZE := 19
const SMALL_FONT_SIZE := 15

@onready var _shade: ColorRect = %Shade
@onready var _panel: PanelContainer = %Panel
@onready var _title: Label = %Title
@onready var _close: Button = %Close
@onready var _wheel: AffinityWheel = %Wheel
@onready var _name: Label = %TribeName
@onready var _theme: Label = %Theme
@onready var _strong: Label = %Strong
@onready var _weak: Label = %Weak
@onready var _legend: Label = %Legend


func _ready() -> void:
	_panel.add_theme_stylebox_override("panel", UiKit.panel_box())
	_shade.color = Palette.MODAL_SHADE
	UiKit.style_label(_title, TITLE_FONT_SIZE, Palette.TEXT)
	_title.add_theme_font_override("font", UiKit.bold_font())
	_title.text = UiText.AFFINITY_TITLE
	UiKit.style_button(_close, TEXT_FONT_SIZE)
	_close.text = UiText.BAG_CLOSE
	_close.pressed.connect(hide)
	UiKit.style_label(_name, NAME_FONT_SIZE, Palette.TEXT)
	_name.add_theme_font_override("font", UiKit.bold_font())
	UiKit.style_caption(_theme, TEXT_FONT_SIZE - 2)
	UiKit.style_label(_strong, TEXT_FONT_SIZE, Palette.AFFINITY_STRONG)
	UiKit.style_label(_weak, TEXT_FONT_SIZE, Palette.AFFINITY_WEAK)
	UiKit.style_caption(_legend, SMALL_FONT_SIZE)
	_legend.text = UiText.AFFINITY_LEGEND % [roundi(GameConfig.AFFINITY_ADVANTAGE * 100.0), roundi(GameConfig.AFFINITY_DISADVANTAGE * 100.0)]
	_wheel.tribe_pressed.connect(select)
	_shade.gui_input.connect(func(event: InputEvent) -> void:
		var press := event as InputEventMouseButton
		if press != null and press.pressed:
			hide())


## 연다. tribe_id를 주면 그 종족을 고른 채로(없으면 지난번 그대로).
func open(tribe_id := "") -> void:
	visible = true
	select(tribe_id if TribeDb.get_tribe(tribe_id) != null else _wheel.selected)


## 종족을 고른다: 원의 화살표와 오른쪽 설명이 바뀐다.
func select(tribe_id: String) -> void:
	var tribe := TribeDb.get_tribe(tribe_id)
	if tribe == null:
		return
	_wheel.selected = tribe_id
	_name.text = tribe.name
	_name.add_theme_color_override("font_color", tribe.color.lightened(0.2))
	_theme.text = UiText.AFFINITY_THEME % tribe.theme
	var strong := TribeDb.get_tribe(tribe.beats)
	_strong.text = UiText.AFFINITY_STRONG_LINE % [strong.name, tribe.beats_why] if strong != null else ""
	var weak := TribeDb.get_tribe(Affinity.beaten_by(tribe_id))
	_weak.text = UiText.AFFINITY_WEAK_LINE % [weak.name, weak.beats_why] if weak != null else ""


# ─── 실행 검사용 ──────────────────────────────────

func selected() -> String:
	return _wheel.selected


func wheel() -> AffinityWheel:
	return _wheel


## [이름, 주제, 강함 줄, 약함 줄].
func detail_texts() -> PackedStringArray:
	return PackedStringArray([_name.text, _theme.text, _strong.text, _weak.text])

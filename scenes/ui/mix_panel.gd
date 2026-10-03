class_name MixPanel
extends Control
## 믹스창(화면 전체 + 뒤를 어둡게, 사용자 정리 2026-10-03 · 기획서 4장 믹스 세부 규칙).
## 위: 공식 한 줄(♀ 고추룡 + ♂ 깡통거북 → 돌구아나) + 숙련도 막대 + 닫기.
## 왼쪽 위: 주 · 보조 코어 칸(크게, 아래에 Lv · 접미사 · 성별) + 주↔보조 버튼(아래에 "바꾸면 → 결과"). 칸을 누르면 비운다.
## 왼쪽 아래: 재료 목록(종족 필터 · 정렬, 남은 높이에 2~3줄이 들어가게 칸을 키운다).
##   고를 수 없는 코어(주 코어 자신 · 같은 성별 · 잠금 · 파티 · 변이)는 흐리게(이름은 그대로) + 까닭 배지. 고른 칸은 흰 테두리 + 체크.
##   빈 칸부터 채운다(주 코어가 비었으면 주 코어, 아니면 보조 코어).
## 오른쪽: 결과 미리보기(초상화 · 종족·역할·등급 · 예상 레벨 · 접미사 계승 확률 · 계승 스탯 · 나이 · 성별 확률),
##   유산 패시브 카드 두 장, 성공 확률 내역(기본 + 숙련 + 마크), 비용, 실패 경고, 큰 믹스하기 버튼.
## 빛나는 코어나 높은 레벨 재료를 쓰면 한 번 더 묻는다. 성공하면 번쩍임 + NEW 결과 카드(이름 · 종족·역할·등급 · 고른 패시브 ·
## 얻은 숙련 경험치, 파티에 넣기(강조) / 정보 보기 / 계속 믹스), 실패하면 붉은 번쩍임 + 같은 모양의 흔들리는 실패 카드
## (잃은 재료 · 얻은 숙련 경험치). 실제 처리는 Workshop.mix(숙련도 · 도감도 함께).
## 결과 초상화는 종족 그림(TribeDb.portrait)이고, 힌트는 같은 그림을 검게 칠한 실루엣 + 종족 이름이다.
## 자리·크기는 mix_panel.tscn을 에디터에서 열어 바꾼다. 연출 시간 등 수치는 GameConfig.MIX_*.

## 결과 카드의 "정보 보기": 가방 창에서 그 코어를 보여 준다.
signal core_shown(item: CoreItem)
## 결과 카드의 "파티에 넣기"
signal party_requested(item: CoreItem, slot: int)

## 재료 정렬(UiText.MIX_SORTS 순서)
enum Sort { LEVEL, GRADE, SHINING }

const TITLE_FONT_SIZE := 26
const FORMULA_FONT_SIZE := 24
const TEXT_FONT_SIZE := 18
const SMALL_FONT_SIZE := 16
const RESULT_NAME_FONT_SIZE := 26
const CHANCE_FONT_SIZE := 24
const BUTTON_FONT_SIZE := 19
const GO_FONT_SIZE := 26
const SECRET_FONT_SIZE := 64
const SLOT_CARD_SIZE := Vector2(144, 144)
## 재료 목록 칸 크기(최소 ~ 최대 px): 재료가 모두 들어가는 가장 큰 크기로 키운다. 다 안 들어가면 MATERIAL_ROWS줄이 보이는 크기로
## 두고 굴려 본다. 세로 스크롤 막대 자리(px)
const MATERIAL_ROWS := 3
const MATERIAL_CARD_MIN := 96.0
const MATERIAL_CARD_MAX := 150.0
const SCROLL_BAR_ROOM := 14.0
## 실패 카드의 잃은 재료 칸 크기
const LOST_CARD_SIZE := Vector2(110, 110)
const PORTRAIT_BORDER := 2
const CHOICE_CORNER := 8

var main_core: CoreItem
var sub_core: CoreItem
## 유산을 남기나(주 코어의 패시브를 받나)
var keep_legacy := false
## 마지막 믹스에서 태어난 코어(실패면 null)
var last_born: CoreItem
## 파티 자리마다 지금 헨치 이름(결과 카드의 "파티에 넣기")
var party_names := Callable()

var _workshop: Workshop
var _confirm: ConfirmBox
var _preview_values: Array[Label] = []
var _busy := false  # 연출 중에는 누름을 받지 않는다
var _material_side := CoreCard.SIZE.x  # 재료 칸 한 변(px, _layout_materials가 정한다)
var _own_passive := ""
var _legacy_passive := ""
var _mixed_main: CoreItem  # 마지막 믹스에 쓴 재료(실패 카드의 잃은 재료)
var _mixed_sub: CoreItem

@onready var _dim: ColorRect = %Dim
@onready var _frame: PanelContainer = %Frame
@onready var _title: Label = %Title
@onready var _formula: Label = %Formula
@onready var _mastery_label: Label = %MasteryLabel
@onready var _mastery_bar: ValueBar = %MasteryBar
@onready var _close: Button = %Close
@onready var _main_label: Label = %MainLabel
@onready var _sub_label: Label = %SubLabel
@onready var _main_slot: CenterContainer = %MainSlot
@onready var _sub_slot: CenterContainer = %SubSlot
@onready var _main_detail: Label = %MainDetail
@onready var _sub_detail: Label = %SubDetail
@onready var _swap: Button = %Swap
@onready var _swap_result: Label = %SwapResult
@onready var _material_title: Label = %MaterialTitle
@onready var _tribe_filter: OptionButton = %TribeFilter
@onready var _sort: OptionButton = %Sort
@onready var _materials: GridContainer = %Materials
@onready var _material_scroll: ScrollContainer = %Materials.get_parent()
@onready var _result_frame: PanelContainer = %ResultFrame
@onready var _result_portrait: TextureRect = %ResultPortrait
@onready var _result_secret: Label = %ResultSecret
@onready var _result_name: Label = %ResultName
@onready var _result_kind: Label = %ResultKind
@onready var _preview: GridContainer = %Preview
@onready var _keep_own: Button = %KeepOwn
@onready var _keep_legacy: Button = %KeepLegacy
@onready var _chance: Label = %Chance
@onready var _chance_parts: Label = %ChanceParts
@onready var _cost: Label = %Cost
@onready var _problem: Label = %Problem
@onready var _warning: Label = %Warning
@onready var _go: Button = %Go
@onready var _flash: ColorRect = %Flash
@onready var _result_layer: Control = %ResultLayer
@onready var _result_dim: ColorRect = %ResultDim
@onready var _result_card: PanelContainer = %ResultCard
@onready var _new_badge: Label = %NewBadge
@onready var _card_lost: HBoxContainer = %CardLost
@onready var _card_portrait: TextureRect = %CardPortrait
@onready var _card_title: Label = %CardTitle
@onready var _card_kind: Label = %CardKind
@onready var _card_info: Label = %CardInfo
@onready var _card_passive: Label = %CardPassive
@onready var _card_mastery: Label = %CardMastery
@onready var _card_party: HBoxContainer = %CardParty
@onready var _to_party: Button = %ToParty
@onready var _show_info: Button = %ShowInfo
@onready var _again: Button = %Again


func _ready() -> void:
	_dim.color = Palette.MIX_DIM
	_result_dim.color = Palette.MIX_DIM
	_frame.add_theme_stylebox_override("panel", UiKit.panel_box())
	_result_card.add_theme_stylebox_override("panel", UiKit.panel_box())
	UiKit.style_label(_title, TITLE_FONT_SIZE, Palette.TEXT)
	_title.add_theme_font_override("font", UiKit.bold_font())
	_title.text = UiText.MIX_TITLE
	UiKit.style_label(_formula, FORMULA_FONT_SIZE, Palette.TEXT)
	UiKit.style_caption(_mastery_label, SMALL_FONT_SIZE)
	for label: Label in [_main_label, _sub_label, _material_title, _main_detail, _sub_detail]:
		UiKit.style_caption(label, SMALL_FONT_SIZE)
	UiKit.style_label(_swap_result, SMALL_FONT_SIZE, Palette.TEXT)
	_main_label.text = UiText.MIX_MAIN
	_sub_label.text = UiText.MIX_SUB
	_material_title.text = UiText.MIX_MATERIALS
	UiKit.style_label(_result_name, RESULT_NAME_FONT_SIZE, Palette.TEXT)
	_result_name.add_theme_font_override("font", UiKit.bold_font())
	UiKit.style_caption(_result_kind, TEXT_FONT_SIZE)
	UiKit.style_label(_result_secret, SECRET_FONT_SIZE, Palette.TEXT_DIM)
	_result_secret.text = UiText.MIX_SECRET
	UiKit.style_number(_chance, CHANCE_FONT_SIZE)
	UiKit.style_caption(_chance_parts, SMALL_FONT_SIZE)
	UiKit.style_label(_cost, TEXT_FONT_SIZE, Palette.CORE_SHINE)
	UiKit.style_label(_problem, TEXT_FONT_SIZE, Palette.TEXT_WARNING)
	UiKit.style_label(_warning, SMALL_FONT_SIZE, Palette.TEXT_WARNING)
	_warning.text = UiText.MIX_WARNING
	for button: BaseButton in [_close, _swap, _keep_own, _keep_legacy, _to_party, _show_info, _again, _tribe_filter, _sort]:
		UiKit.style_button(button, BUTTON_FONT_SIZE)
	UiKit.style_button(_go, GO_FONT_SIZE)
	# 큰 믹스하기 버튼: 누를 수 있으면 금빛 테두리로 눈에 띄게(누를 수 없으면 기본 흐린 모양)
	var go_box := _choice_box(Palette.MIX_GO_BG, Palette.CORE_SHINE)
	for state: String in ["normal", "hover", "pressed", "focus"]:
		_go.add_theme_stylebox_override(state, go_box)
	_go.add_theme_color_override("font_color", Palette.CORE_SHINE)
	_go.add_theme_color_override("font_hover_color", Palette.CORE_SHINE)
	_go.add_theme_font_override("font", UiKit.bold_font())
	_close.text = UiText.BAG_CLOSE
	_swap.text = UiText.MIX_SWAP
	_go.text = UiText.MIX_GO
	_to_party.text = UiText.BTN_TO_PARTY
	_show_info.text = UiText.BTN_SHOW_INFO
	_again.text = UiText.BTN_MIX_AGAIN
	_build_preview()
	_build_choices()
	_build_filters()
	UiKit.style_label(_new_badge, TEXT_FONT_SIZE, Palette.MIX_NEW)
	_new_badge.add_theme_font_override("font", UiKit.bold_font())
	_new_badge.text = UiText.MIX_RESULT_NEW
	UiKit.style_label(_card_title, RESULT_NAME_FONT_SIZE, Palette.TEXT)
	_card_title.add_theme_font_override("font", UiKit.bold_font())
	UiKit.style_caption(_card_kind, TEXT_FONT_SIZE)
	UiKit.style_label(_card_info, TEXT_FONT_SIZE, Palette.TEXT)
	UiKit.style_label(_card_passive, TEXT_FONT_SIZE, Palette.TEXT)
	UiKit.style_label(_card_mastery, SMALL_FONT_SIZE, Palette.MIX_MASTERY_BAR)
	# 결과 카드에서는 "파티에 넣기"만 강조색
	var accent := _choice_box(Palette.MIX_ACCENT_BG, Palette.MIX_ACCENT_BORDER)
	for state: String in ["normal", "hover", "pressed", "focus"]:
		_to_party.add_theme_stylebox_override(state, accent)
	_to_party.add_theme_color_override("font_color", Palette.TEXT)
	_to_party.add_theme_color_override("font_hover_color", Palette.TEXT)
	_to_party.add_theme_font_override("font", UiKit.bold_font())
	_close.pressed.connect(_on_close)
	_swap.pressed.connect(_on_swap)
	_go.pressed.connect(_on_go)
	_material_scroll.resized.connect(func() -> void: _layout_materials(_materials.get_child_count()))
	_tribe_filter.item_selected.connect(func(_index: int) -> void: _rebuild_materials())
	_sort.item_selected.connect(func(_index: int) -> void: _rebuild_materials())
	_to_party.pressed.connect(_on_to_party)
	_show_info.pressed.connect(_on_show_info)
	_again.pressed.connect(_close_result)


func bind(workshop: Workshop, confirm: ConfirmBox, names: Callable) -> void:
	_workshop = workshop
	_confirm = confirm
	party_names = names
	_workshop.bag.changed.connect(_refresh_if_open)
	_workshop.wallet.changed.connect(_refresh_if_open)


func _refresh_if_open() -> void:
	if visible and not _busy:
		refresh()


## 결과 미리보기 표: 이름표(연한 회색) + 값(흰색 굵게) 다섯 줄.
func _build_preview() -> void:
	for caption_text: String in UiText.MIX_PREVIEW_CAPTIONS:
		var caption := Label.new()
		UiKit.style_caption(caption, SMALL_FONT_SIZE)
		caption.text = caption_text
		var value := Label.new()
		UiKit.style_number(value, SMALL_FONT_SIZE + 1)
		value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_preview.add_child(caption)
		_preview.add_child(value)
		_preview_values.append(value)


## 유산 패시브 카드 두 장: 둘 중 하나만 눌리는 버튼. 고른 쪽은 흰 테두리 + 체크(노랑은 빛나는 코어 전용, 사용자 결정 2026-10-03).
func _build_choices() -> void:
	for choice: Button in [_keep_own, _keep_legacy]:
		var off := _choice_box(Palette.CARD_BG, Palette.CARD_BORDER)
		var on := _choice_box(Palette.CARD_SELECTED_BG, Palette.CARD_SELECTED_BORDER)
		for state: String in ["normal", "hover", "focus", "disabled"]:
			choice.add_theme_stylebox_override(state, off)
		for state: String in ["pressed", "hover_pressed"]:
			choice.add_theme_stylebox_override(state, on)
		choice.add_theme_color_override("font_color", Palette.TEXT_LABEL)
		choice.add_theme_color_override("font_hover_color", Palette.TEXT_LABEL)
		choice.add_theme_color_override("font_pressed_color", Palette.TEXT)
		choice.add_theme_color_override("font_hover_pressed_color", Palette.TEXT)
	var group := ButtonGroup.new()
	_keep_own.button_group = group
	_keep_legacy.button_group = group
	_keep_own.toggled.connect(func(on: bool) -> void:
		if on:
			keep_legacy = false
			_label_passives())
	_keep_legacy.toggled.connect(func(on: bool) -> void:
		if on:
			keep_legacy = true
			_label_passives())


## 재료 목록 위: 종족 필터(전체 + 종족 8개) · 정렬(레벨 · 등급 · 빛나는).
func _build_filters() -> void:
	_tribe_filter.add_item(UiText.MIX_FILTER_ALL)
	for tribe_id: String in HenchSpecies.TRIBES:
		_tribe_filter.add_item(TribeDb.get_tribe(tribe_id).name)
	for sort_name: String in UiText.MIX_SORTS:
		_sort.add_item(sort_name)
	for option: OptionButton in [_tribe_filter, _sort]:
		option.get_popup().add_theme_font_size_override("font_size", BUTTON_FONT_SIZE)


static func _choice_box(fill: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(2)
	box.set_corner_radius_all(CHOICE_CORNER)
	box.content_margin_left = 10
	box.content_margin_right = 10
	box.content_margin_top = 6
	box.content_margin_bottom = 6
	return box


## 그 코어를 주 코어로 열고, 보조 칸은 비운다.
func open(main: CoreItem) -> void:
	main_core = main
	sub_core = null
	keep_legacy = false
	_keep_own.set_pressed_no_signal(true)
	_keep_legacy.set_pressed_no_signal(false)
	_result_layer.visible = false
	visible = true
	refresh()


## 재료 목록에서 그 코어를 누른 것처럼(빈 칸부터 채운다). 실행 검사에서도 쓴다.
func choose(item: CoreItem) -> void:
	if _busy or item == main_core:
		return
	if item == sub_core:
		sub_core = null
		refresh()
		return
	var problem := Mix.material_problem(item, _partner())
	if problem != Mix.Problem.NONE:
		_problem.text = UiText.MIX_PROBLEMS[problem]
		return
	if main_core == null:
		main_core = item
	else:
		sub_core = item
	refresh()


## 재료 목록에서 그 코어의 칸(실행 검사용). 없으면 null.
func material_card(item: CoreItem) -> CoreCard:
	for card: CoreCard in _materials.get_children():
		if card.item == item:
			return card
	return null


## 공식 한 줄(실행 검사용).
func formula_text() -> String:
	return _formula.text


## 재료가 짝지어질 상대: 주 코어, 없으면 보조 코어.
func _partner() -> CoreItem:
	return main_core if main_core != null else sub_core


func refresh() -> void:
	if main_core != null and not _workshop.bag.has(main_core):
		main_core = null
	if sub_core != null and not _workshop.bag.has(sub_core):
		sub_core = null
	_show_slot(_main_slot, main_core, true)
	_show_slot(_sub_slot, sub_core, false)
	_main_detail.text = _slot_detail(main_core)
	_sub_detail.text = _slot_detail(sub_core)
	var has_pair := main_core != null and sub_core != null
	var result := Mix.result_id(main_core, sub_core) if has_pair else ""
	var reveal := Mix.reveal_of(result)
	_swap_result.text = UiText.MIX_SWAP_RESULT % _swapped_outcome() if has_pair else ""
	_formula.text = UiText.MIX_FORMULA % [_side(main_core, UiText.MIX_MAIN), _side(sub_core, UiText.MIX_SUB), _outcome(result, reveal, has_pair)]
	_show_mastery()
	_show_result(result, reveal, has_pair)
	_show_preview(result, reveal)
	_show_passives(result, reveal)
	_show_chance(result, reveal, has_pair)
	var problem := _workshop.mix_problem(main_core, sub_core)
	_problem.text = UiText.MIX_PROBLEMS[problem]
	_go.disabled = problem != Mix.Problem.NONE or _busy
	_rebuild_materials()


## 공식 한쪽: "♀ 고추룡", 비었으면 "(주 코어)".
static func _side(item: CoreItem, empty_name: String) -> String:
	if item == null:
		return UiText.MIX_FORMULA_EMPTY % empty_name
	return UiText.MIX_FORMULA_SIDE % [UiText.GENDER_SYMBOLS[item.gender], item.species().name]


## 주·보조 칸 아래 한 줄: Lv · 접미사 · 성별 기호(빈 칸이면 "").
static func _slot_detail(item: CoreItem) -> String:
	if item == null:
		return ""
	return UiText.MIX_SLOT_DETAIL % [item.level, SuffixDb.display_name(item.suffix_id), UiText.GENDER_SYMBOLS[item.gender]]


## 주·보조를 바꾸면 나올 결과: 공개 공식이면 이름, 아니면(힌트 · 비밀 · 공식 없음) ?
func _swapped_outcome() -> String:
	var swapped := Mix.result_id(sub_core, main_core)
	if swapped == "" or Mix.reveal_of(swapped) != Mix.Reveal.OPEN:
		return UiText.MIX_SECRET
	return HenchDb.get_species(swapped).name


## 주·보조를 바꾸면 나올 결과 글자(실행 검사용).
func swap_result_text() -> String:
	return _swap_result.text


## 공식의 결과 쪽: 공개 = 이름, 힌트 = ???, 비밀 · 공식 없음 · 재료가 덜 참 = ?
static func _outcome(result: String, reveal: Mix.Reveal, has_pair: bool) -> String:
	if not has_pair or result == "" or reveal == Mix.Reveal.SECRET:
		return UiText.MIX_SECRET
	if reveal == Mix.Reveal.HINT:
		return UiText.MIX_HINT_NAME
	return HenchDb.get_species(result).name


func _show_mastery() -> void:
	var mastery := _workshop.mastery
	_mastery_label.text = UiText.MIX_MASTERY % mastery.level
	var exp_text := UiText.MIX_MASTERY_MAX if mastery.is_max() else UiText.MIX_MASTERY_EXP % [mastery.exp_points, mastery.exp_to_next()]
	_mastery_bar.show_value("", exp_text, Palette.MIX_MASTERY_BAR, mastery.progress())


## 결과 미리보기 머리: 공개 = 초상화 + 이름 + 종족·역할·등급, 힌트 = 실루엣 + ??? + 종족, 비밀 = ?
func _show_result(result: String, reveal: Mix.Reveal, has_pair: bool) -> void:
	var secret := not has_pair or result == "" or reveal == Mix.Reveal.SECRET
	_result_secret.visible = secret
	_result_portrait.visible = not secret
	var frame := StyleBoxFlat.new()
	frame.bg_color = Palette.PORTRAIT_BG
	frame.border_color = Palette.CARD_BORDER
	frame.set_border_width_all(PORTRAIT_BORDER)
	frame.set_corner_radius_all(UiKit.PANEL_CORNER)
	_result_frame.add_theme_stylebox_override("panel", frame)
	_result_name.text = ""
	_result_kind.text = ""
	if secret:
		return
	var species := HenchDb.get_species(result)
	var tribe := TribeDb.get_tribe(species.tribe)
	_result_portrait.texture = TribeDb.portrait(species.tribe)
	var draft := (" " + UiText.MIX_DRAFT) if Mix.is_draft(main_core, sub_core) else ""
	if reveal == Mix.Reveal.OPEN:
		_result_portrait.modulate = Color.WHITE
		_result_name.text = species.name + draft
		_result_kind.text = UiText.INFO_KIND % [tribe.name, UiText.ROLE_NAMES.get(species.role, species.role), UiText.GRADE_NAMES.get(species.grade, species.grade)]
	else:
		_result_portrait.modulate = Palette.SILHOUETTE
		_result_name.text = UiText.MIX_HINT_NAME + draft
		_result_kind.text = UiText.MIX_HINT_KIND % tribe.name


## 예상 레벨 · 접미사 계승 확률 · 계승 스탯 · 나이 · 성별 확률. 공식을 모르면 "?".
func _show_preview(result: String, reveal: Mix.Reveal) -> void:
	var values := PackedStringArray()
	values.resize(_preview_values.size())
	values.fill(UiText.MIX_PREVIEW_UNKNOWN)
	if result != "":
		if reveal != Mix.Reveal.SECRET:
			values[0] = UiText.MIX_PREVIEW_LEVEL % Mix.born_level(main_core, sub_core, result)
		var keep := roundi(GameConfig.MIX_SUFFIX_KEEP_CHANCE * 100.0)
		values[1] = UiText.MIX_PREVIEW_SUFFIX % [SuffixDb.display_name(main_core.suffix_id), keep, 100 - keep]
		var span := Mix.inherit_range(sub_core)
		values[2] = UiText.MIX_PREVIEW_INHERIT % [SuffixDb.stat_name(sub_core.suffix_id), span.x, span.y]
		values[3] = UiText.AGE_NAMES[GameConfig.MIX_BORN_AGE]
		var female := roundi(GameConfig.FEMALE_CHANCE * 100.0)
		values[4] = UiText.MIX_PREVIEW_GENDER % [female, 100 - female]
	for i in _preview_values.size():
		_preview_values[i].text = values[i]


## 유산 패시브 카드: 자기 패시브(공개일 때만 이름) / 주 코어의 지금 패시브.
func _show_passives(result: String, reveal: Mix.Reveal) -> void:
	_own_passive = HenchDb.get_species(result).passive if result != "" and reveal == Mix.Reveal.OPEN else UiText.MIX_HINT_NAME
	_legacy_passive = HenchDb.get_species(main_core.passive_owner_id()).passive if main_core != null else UiText.MIX_HINT_NAME
	_keep_legacy.disabled = main_core == null
	_label_passives()


## 유산 패시브 카드 글자: 고른 쪽 앞에 체크.
func _label_passives() -> void:
	var own := UiText.MIX_KEEP_OWN % _own_passive
	var legacy := UiText.MIX_KEEP_LEGACY % _legacy_passive
	_keep_own.text = own if keep_legacy else UiText.MIX_CHOSEN % own
	_keep_legacy.text = UiText.MIX_CHOSEN % legacy if keep_legacy else legacy


## 성공 확률(합)과 내역(기본 + 숙련 + 마크), 비용. 비밀 공식은 확률을 ?로 둔다.
func _show_chance(result: String, reveal: Mix.Reveal, has_pair: bool) -> void:
	var known := has_pair and result != "" and reveal != Mix.Reveal.SECRET
	var parts := _workshop.mix_chance(main_core, sub_core) if has_pair else Mix.success_parts("")
	_chance.text = UiText.MIX_CHANCE % (UiText.PERCENT % roundi(parts["total"] * 100.0) if known else UiText.UNKNOWN_PERCENT)
	_chance_parts.text = UiText.MIX_CHANCE_PARTS % [roundi(parts["base"] * 100.0), roundi(parts["mastery"] * 100.0), roundi(parts["mark"] * 100.0)] if known else ""
	_cost.text = UiText.MIX_COST % [Mix.gold_cost(result), _workshop.wallet.gold]


## 주 · 보조 칸: 코어가 있으면 크게 보이고, 누르면 그 칸을 비운다. 비었으면 안내 글자.
func _show_slot(holder: CenterContainer, item: CoreItem, is_main: bool) -> void:
	for child in holder.get_children():
		holder.remove_child(child)
		child.queue_free()
	if item == null:
		var empty := Label.new()
		empty.text = UiText.MIX_SLOT_EMPTY
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UiKit.style_caption(empty, SMALL_FONT_SIZE)
		holder.add_child(empty)
		return
	var card := CoreCard.create(item, SLOT_CARD_SIZE)
	card.pressed.connect(func() -> void:
		if _busy:
			return
		if is_main:
			main_core = null
		else:
			sub_core = null
		refresh())
	holder.add_child(card)


## 재료 목록: 종족 필터 · 정렬을 따르고, 고를 수 없는 코어는 흐리게 + 까닭. 고른 코어는 흰 테두리.
func _rebuild_materials() -> void:
	for child in _materials.get_children():
		_materials.remove_child(child)
		child.queue_free()
	var tribe_index := _tribe_filter.selected
	var list: Array[CoreItem] = []
	for item in _workshop.bag.cores:
		if tribe_index <= 0 or item.species().tribe == HenchSpecies.TRIBES[tribe_index - 1]:
			list.append(item)
	list.sort_custom(_sorter(maxi(_sort.selected, 0) as Sort))
	_layout_materials(list.size())
	for item in list:
		var card := CoreCard.create(item, Vector2.ONE * _material_side)
		card.block_reason = _material_reason(item)
		card.selected = item == main_core or item == sub_core
		card.pressed.connect(choose.bind(item))
		_materials.add_child(card)


## 재료 목록 칸 크기와 열 수를 남은 자리에 맞춘다: count개가 스크롤 없이 모두 들어가는 가장 큰 칸(2~3줄로 왼쪽 아래를 채운다).
## 너무 많아 다 안 들어가면 MATERIAL_ROWS줄이 보이는 크기로 두고 굴린다. 휴대폰이 길면 한 줄에 더 많이.
func _layout_materials(count: int) -> void:
	var gap := float(_materials.get_theme_constant("h_separation"))
	var width := _material_scroll.size.x - SCROLL_BAR_ROOM
	var height := _material_scroll.size.y
	if width <= 0.0 or height <= 0.0:
		return
	var side := clampf((height - gap * (MATERIAL_ROWS - 1)) / MATERIAL_ROWS, MATERIAL_CARD_MIN, MATERIAL_CARD_MAX)
	var biggest := MATERIAL_CARD_MAX
	while biggest > side:
		var fit_columns := maxi(1, floori((width + gap) / (biggest + gap)))
		var rows := ceili(float(maxi(count, 1)) / fit_columns)
		if rows * (biggest + gap) - gap <= height:
			side = biggest
			break
		biggest -= 2.0
	side = floorf(minf(side, width))
	_material_side = side
	_materials.columns = maxi(1, floori((width + gap) / (side + gap)))
	for card: CoreCard in _materials.get_children():
		card.resize_to(Vector2.ONE * side)


## 재료 칸 한 변(px, 실행 검사용).
func material_side() -> float:
	return _material_side


## 재료 칸에 붙일 까닭(고를 수 있으면 "").
func _material_reason(item: CoreItem) -> String:
	if item == main_core:
		return UiText.MIX_MATERIAL_REASONS[Mix.Problem.SAME_CORE]
	if item == sub_core:
		return ""
	return UiText.MIX_MATERIAL_REASONS[Mix.material_problem(item, _partner())]


## 정렬 비교 함수: 레벨 높은 순 / 등급 높은 순(같으면 레벨) / 빛나는 먼저(같으면 레벨).
static func _sorter(sort: Sort) -> Callable:
	return func(a: CoreItem, b: CoreItem) -> bool:
		if sort == Sort.GRADE:
			var ga := HenchSpecies.GRADES.find(a.species().grade)
			var gb := HenchSpecies.GRADES.find(b.species().grade)
			if ga != gb:
				return ga > gb
		elif sort == Sort.SHINING and a.shining != b.shining:
			return a.shining
		return a.level > b.level


func _on_swap() -> void:
	if _busy or (main_core == null and sub_core == null):
		return
	var old_main := main_core
	main_core = sub_core
	sub_core = old_main
	refresh()


func _on_close() -> void:
	if _busy:
		return
	_result_layer.visible = false
	hide()


## 믹스하기: 빛나는 코어나 높은 레벨 재료가 있으면 한 번 더 묻고, 아니면 바로.
func _on_go() -> void:
	if _busy or _workshop.mix_problem(main_core, sub_core) != Mix.Problem.NONE:
		return
	var reasons := PackedStringArray()
	if main_core.shining or sub_core.shining:
		reasons.append(UiText.MIX_CONFIRM_SHINING)
	var highest := maxi(main_core.level, sub_core.level)
	if highest >= GameConfig.MIX_CONFIRM_LEVEL:
		reasons.append(UiText.MIX_CONFIRM_LEVEL % highest)
	if reasons.is_empty():
		_start_mix()
	else:
		_confirm.ask(UiText.MIX_CONFIRM_ASK % "\n".join(reasons), _start_mix)


## 연출 1: 두 재료 칸이 흐려지며 모인다 → 실제 믹스 → 번쩍임과 결과 카드.
func _start_mix() -> void:
	if _busy:
		return
	_busy = true
	_go.disabled = true
	var tween := create_tween().set_parallel()
	for slot: CenterContainer in [_main_slot, _sub_slot]:
		tween.tween_property(slot, "modulate:a", 0.15, GameConfig.MIX_FX_GATHER_SECONDS)
	tween.chain().tween_callback(_finish_mix)


func _finish_mix() -> void:
	_mixed_main = main_core
	_mixed_sub = sub_core
	last_born = _workshop.mix(main_core, sub_core, keep_legacy)
	main_core = null
	sub_core = null
	for slot: CenterContainer in [_main_slot, _sub_slot]:
		slot.modulate.a = 1.0
	_busy = false
	refresh()
	_flash_screen(Palette.MIX_FLASH_SUCCESS if last_born != null else Palette.MIX_FLASH_FAIL)
	_show_result_card()


func _flash_screen(color: Color) -> void:
	_flash.color = Color(color, 0.85)
	create_tween().tween_property(_flash, "color:a", 0.0, GameConfig.MIX_FX_FLASH_SECONDS)


## 결과 카드(성공 · 실패 같은 모양): 이름 + 종족·역할·등급 + 내용 + 패시브 + 얻은 숙련 경험치 + 버튼.
## 성공 = (NEW) 초상화 · LV·나이·성별 · 계승 스탯 · 고른 패시브, 버튼 셋(파티에 넣기만 강조).
## 실패 = 잃은 재료 두 칸 · "재료 둘이 사라졌습니다", 흔들림, 계속 믹스만.
func _show_result_card() -> void:
	_result_layer.visible = true
	_card_party.visible = false
	var born := last_born
	var success := born != null
	_new_badge.visible = success and _workshop.last_mix_new
	_card_portrait.visible = success
	_card_lost.visible = not success
	_card_passive.visible = success
	_to_party.visible = success
	_show_info.visible = success
	var mastery := _workshop.mastery
	var exp_text := UiText.MIX_MASTERY_MAX if mastery.is_max() else UiText.MIX_MASTERY_EXP % [mastery.exp_points, mastery.exp_to_next()]
	_card_mastery.text = UiText.MIX_RESULT_EXP % [_workshop.last_mix_exp, exp_text]
	if _workshop.last_mix_level_up:
		_card_mastery.text += "\n" + UiText.MIX_MASTERY_UP % mastery.level
	_result_card.pivot_offset = _result_card.size * 0.5
	if success:
		var species := born.species()
		var tribe := TribeDb.get_tribe(species.tribe)
		_card_portrait.texture = TribeDb.portrait(species.tribe)
		_card_title.text = born.title()
		_card_title.add_theme_color_override("font_color", Palette.TEXT)
		_card_kind.text = UiText.INFO_KIND % [tribe.name, UiText.ROLE_NAMES.get(species.role, species.role), UiText.GRADE_NAMES.get(species.grade, species.grade)]
		_card_info.text = UiText.MIX_RESULT_INFO % [born.level, UiText.AGE_NAMES[born.age], UiText.GENDER_BADGE % [UiText.GENDER_SYMBOLS[born.gender], UiText.GENDER_NAMES[born.gender]]]
		_card_info.text += "\n" + UiText.INFO_INHERIT % [SuffixDb.stat_name(born.inherit_stat), born.inherit_value]
		var passive_from := born.passive_owner_id()
		var from := UiText.MIX_RESULT_PASSIVE_OWN if passive_from == born.species_id else UiText.MIX_RESULT_PASSIVE_LEGACY % HenchDb.get_species(passive_from).name
		_card_passive.text = UiText.MIX_RESULT_PASSIVE % [HenchDb.get_species(passive_from).passive, from]
		_result_card.scale = Vector2.ONE * 0.6
		create_tween().tween_property(_result_card, "scale", Vector2.ONE, GameConfig.MIX_FX_POP_SECONDS).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		_card_title.text = UiText.MIX_FAIL_TITLE
		_card_title.add_theme_color_override("font_color", Palette.TEXT_WARNING)
		_card_kind.text = UiText.MIX_FAIL_INFO
		_card_info.text = UiText.MIX_FAIL_LOST % [_mixed_main.title(), _mixed_sub.title()]
		_show_lost_cards()
		_result_card.scale = Vector2.ONE
		var home := _result_card.position
		var shake := create_tween()
		var step := GameConfig.MIX_FX_SHAKE_SECONDS / 6.0
		for i in 5:
			var offset := GameConfig.MIX_FX_SHAKE_PIXELS * (1.0 - i / 5.0) * (1.0 if i % 2 == 0 else -1.0)
			shake.tween_property(_result_card, "position:x", home.x + offset, step)
		shake.tween_property(_result_card, "position:x", home.x, step)


## 실패 카드의 잃은 재료 두 칸(흐리게 + "사라짐" 배지, 누를 수 없음).
func _show_lost_cards() -> void:
	for child in _card_lost.get_children():
		_card_lost.remove_child(child)
		child.queue_free()
	for item: CoreItem in [_mixed_main, _mixed_sub]:
		var card := CoreCard.create(item, LOST_CARD_SIZE)
		card.block_reason = UiText.MIX_LOST_BADGE
		_card_lost.add_child(card)
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE  # 칸이 _ready에서 정한 값을 덮어쓴다


## 결과 카드 글자들(실행 검사용): 제목 · 종류 줄 · 내용 · 패시브 · 숙련 경험치.
func result_card_texts() -> PackedStringArray:
	return PackedStringArray([_card_title.text, _card_kind.text, _card_info.text, _card_passive.text, _card_mastery.text])


## 결과 카드가 떠 있나(실행 검사용).
func is_showing_result() -> bool:
	return _result_layer.visible


## 파티에 넣기: 넣을 자리 버튼(지금 헨치 이름) + 취소.
func _on_to_party() -> void:
	for child in _card_party.get_children():
		child.queue_free()
	var names: PackedStringArray = party_names.call() if party_names.is_valid() else PackedStringArray()
	for slot in names.size():
		var button := Button.new()
		button.text = UiText.PARTY_SLOT % [slot + 1, names[slot]]
		button.custom_minimum_size.y = BUTTON_FONT_SIZE * 2.4
		UiKit.style_button(button, BUTTON_FONT_SIZE)
		button.pressed.connect(func() -> void:
			party_requested.emit(last_born, slot)
			_close_result())
		_card_party.add_child(button)
	var cancel := Button.new()
	cancel.text = UiText.BTN_CANCEL
	cancel.custom_minimum_size.y = BUTTON_FONT_SIZE * 2.4
	UiKit.style_button(cancel, BUTTON_FONT_SIZE)
	cancel.pressed.connect(func() -> void: _card_party.visible = false)
	_card_party.add_child(cancel)
	_card_party.visible = true


## 정보 보기: 믹스창을 닫고 가방 창에서 그 코어를 보여 준다.
func _on_show_info() -> void:
	_result_layer.visible = false
	hide()
	core_shown.emit(last_born)


## 계속 믹스: 결과 카드만 닫고 빈 칸으로 다시 고른다.
func _close_result() -> void:
	_result_layer.visible = false
	refresh()

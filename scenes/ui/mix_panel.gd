class_name MixPanel
extends Control
## 믹스창(화면 전체 + 뒤를 어둡게, 사용자 결정 2026-10-03: 정보를 버리지 않고 단계로 나눈 3단 배치).
## 왼쪽 = 재료 그리드(종족 필터 · 정렬). 고를 수 없는 코어(주 코어 자신 · 같은 성별 · 잠금 · 파티 · 변이)는 흐리게 + 까닭 배지,
##   고른 칸은 흰 테두리 + 체크. 누르면 오른쪽에 그 코어 상세를 보여 주고, 고를 수 있으면 빈 칸부터 채운다(주 → 보조).
## 가운데 = 연성 장치(플라스크 도형, MixFlasks): 주 · 보조 칸(누르면 비움), 그 사이 ⇄ + "바꾸면 → ○○",
##   결과 칸(공개 = 그림 + 이름, 힌트 = 실루엣, 비밀 = ?), 성공 확률 숫자(누르면 내역 말풍선), 비용, 큰 "연성하기",
##   실패 경고(처음 GameConfig.MIX_WARNING_BIG_TIMES번은 크게, 그 뒤로는 버튼 아래 작게), "숙련 n단계 ⓘ"(숙련 창) · "레시피"(레시피 창).
## 오른쪽 = 정보창(가방 창의 CoreInfo를 버튼 없이 재사용). 결과 칸을 누르면 미리보기(예상 레벨 · 접미사 확률 · 계승 스탯 · 나이 · 성별 확률).
## 연성하기: 빛나는 코어나 높은 레벨 재료면 한 번 더 묻는다. 성공하면 두 재료가 결과 플라스크로 모이는 연출 → 번쩍임 →
## 성공 카드(이름 · 종족·역할·등급 · LV·나이·성별 · 계승 스탯 · 패시브 고르기(자기 / 유산) · 얻은 숙련 경험치,
## 파티에 넣기(강조) / 정보 보기 / 계속 믹스). 실패하면 붉은 번쩍임 + 같은 모양의 실패 카드(잃은 재료 · 얻은 숙련 경험치).
## 실제 처리는 Workshop(믹스 · 숙련도 · 도감 · 패시브 고르기). 자리·크기는 mix_panel.tscn을 에디터에서 연다. 수치는 GameConfig.MIX_*.

## 결과 카드의 "정보 보기": 가방 창에서 그 코어를 보여 준다.
signal core_shown(item: CoreItem)
## 결과 카드의 "파티에 넣기"
signal party_requested(item: CoreItem, slot: int)

## 재료 정렬(UiText.MIX_SORTS 순서)
enum Sort { LEVEL, GRADE, SHINING }

const TITLE_FONT_SIZE := 26
const TEXT_FONT_SIZE := 18
const SMALL_FONT_SIZE := 16
const SLOT_CAPTION_FONT_SIZE := 15
const RESULT_NAME_FONT_SIZE := 22
const CARD_TITLE_FONT_SIZE := 26
const CHANCE_FONT_SIZE := 24
const BUTTON_FONT_SIZE := 19
const GO_FONT_SIZE := 26
const SWAP_FONT_SIZE := 26
const SECRET_FONT_SIZE := 56
const SLOT_CARD_SIZE := Vector2(100, 100)
const CHOICE_CORNER := 8
## 재료 목록 칸 크기(최소 ~ 최대 px): 재료가 모두 들어가는 가장 큰 크기로 키운다. 다 안 들어가면 MATERIAL_ROWS줄이 보이는 크기로
## 두고 굴려 본다. 세로 스크롤 막대 자리(px)
const MATERIAL_ROWS := 4
const MATERIAL_CARD_MIN := 92.0
const MATERIAL_CARD_MAX := 150.0
const SCROLL_BAR_ROOM := 14.0
## 실패 카드의 잃은 재료 칸 크기
const LOST_CARD_SIZE := Vector2(104, 104)
## 숙련 표 한 칸의 여백(px)
const TABLE_PAD := Vector2(14, 6)

var main_core: CoreItem
var sub_core: CoreItem
## 마지막 믹스에서 태어난 코어(실패면 null)
var last_born: CoreItem
## 파티 자리마다 지금 헨치 이름(결과 카드의 "파티에 넣기")
var party_names := Callable()

var _workshop: Workshop
var _confirm: ConfirmBox
var _busy := false  # 연출 중에는 누름을 받지 않는다
var _material_side := CoreCard.SIZE.x  # 재료 칸 한 변(px, _layout_materials가 정한다)
var _mixed_main: CoreItem  # 마지막 믹스에 쓴 재료(모이는 연출 · 실패 카드의 잃은 재료)
var _mixed_sub: CoreItem
var _legacy_owner := ""  # 마지막 믹스의 주 코어 패시브 주인(성공 카드에서 유산으로 고를 때)
var _tip_left := 0.0

@onready var _dim: ColorRect = %Dim
@onready var _frame: PanelContainer = %Frame
@onready var _title: Label = %Title
@onready var _close: Button = %Close
@onready var _material_title: Label = %MaterialTitle
@onready var _tribe_filter: OptionButton = %TribeFilter
@onready var _sort: OptionButton = %Sort
@onready var _materials: GridContainer = %Materials
@onready var _material_scroll: ScrollContainer = %Materials.get_parent()
@onready var _flasks: MixFlasks = %Flasks
@onready var _main_label: Label = %MainLabel
@onready var _sub_label: Label = %SubLabel
@onready var _main_slot: CenterContainer = %MainSlot
@onready var _sub_slot: CenterContainer = %SubSlot
@onready var _swap: Button = %Swap
@onready var _swap_result: Label = %SwapResult
@onready var _result_slot: Button = %ResultSlot
@onready var _result_portrait: TextureRect = %ResultPortrait
@onready var _result_secret: Label = %ResultSecret
@onready var _result_name: Label = %ResultName
@onready var _chance: Button = %Chance
@onready var _cost: Label = %Cost
@onready var _problem: Label = %Problem
@onready var _warning_big: PanelContainer = %WarningBig
@onready var _warning_big_text: Label = %WarningBigText
@onready var _go: Button = %Go
@onready var _warning_small: Label = %WarningSmall
@onready var _mastery_button: Button = %MasteryButton
@onready var _recipe_button: Button = %RecipeButton
@onready var _info: CoreInfo = %CoreInfo
@onready var _flash: ColorRect = %Flash
@onready var _fx_layer: Control = %FxLayer
@onready var _chance_tip: PanelContainer = %ChanceTip
@onready var _chance_tip_text: Label = %ChanceTipText
@onready var _popup_layer: Control = %PopupLayer
@onready var _popup_dim: ColorRect = %PopupDim
@onready var _mastery_window: PanelContainer = %MasteryWindow
@onready var _mastery_title: Label = %MasteryTitle
@onready var _mastery_close: Button = %MasteryClose
@onready var _mastery_now: Label = %MasteryNow
@onready var _mastery_table: GridContainer = %MasteryTable
@onready var _mastery_note: Label = %MasteryNote
@onready var _recipe_window: PanelContainer = %RecipeWindow
@onready var _recipe_title: Label = %RecipeTitle
@onready var _recipe_close: Button = %RecipeClose
@onready var _recipe_note: Label = %RecipeNote
@onready var _recipe_list: VBoxContainer = %RecipeList
@onready var _result_layer: Control = %ResultLayer
@onready var _result_dim: ColorRect = %ResultDim
@onready var _result_card: PanelContainer = %ResultCard
@onready var _new_badge: Label = %NewBadge
@onready var _card_lost: HBoxContainer = %CardLost
@onready var _card_portrait: TextureRect = %CardPortrait
@onready var _card_title: Label = %CardTitle
@onready var _card_kind: Label = %CardKind
@onready var _card_info: Label = %CardInfo
@onready var _card_passive_title: Label = %CardPassiveTitle
@onready var _card_passives: HBoxContainer = %CardPassives
@onready var _keep_own: Button = %KeepOwn
@onready var _keep_legacy: Button = %KeepLegacy
@onready var _card_mastery: Label = %CardMastery
@onready var _card_party: HBoxContainer = %CardParty
@onready var _to_party: Button = %ToParty
@onready var _show_info: Button = %ShowInfo
@onready var _again: Button = %Again


func _ready() -> void:
	for dim: ColorRect in [_dim, _result_dim, _popup_dim]:
		dim.color = Palette.MIX_DIM
	for panel: PanelContainer in [_frame, _result_card, _mastery_window, _recipe_window]:
		panel.add_theme_stylebox_override("panel", UiKit.panel_box())
	UiKit.style_label(_title, TITLE_FONT_SIZE, Palette.TEXT)
	_title.add_theme_font_override("font", UiKit.bold_font())
	_title.text = UiText.MIX_TITLE
	UiKit.style_caption(_material_title, SMALL_FONT_SIZE)
	_material_title.text = UiText.MIX_MATERIALS
	for label: Label in [_main_label, _sub_label]:
		UiKit.style_caption(label, SLOT_CAPTION_FONT_SIZE)
	_main_label.text = UiText.MIX_MAIN
	_sub_label.text = UiText.MIX_SUB
	UiKit.style_label(_swap_result, SMALL_FONT_SIZE - 1, Palette.TEXT_LABEL)
	UiKit.style_label(_result_name, RESULT_NAME_FONT_SIZE, Palette.TEXT)
	_result_name.add_theme_font_override("font", UiKit.bold_font())
	UiKit.style_label(_result_secret, SECRET_FONT_SIZE, Palette.TEXT_DIM)
	_result_secret.text = UiText.MIX_SECRET
	_result_secret.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiKit.style_button(_chance, CHANCE_FONT_SIZE)
	_chance.add_theme_font_override("font", UiKit.bold_font())
	_chance.add_theme_color_override("font_color", Palette.TEXT)
	UiKit.style_label(_cost, SMALL_FONT_SIZE, Palette.CORE_SHINE)
	UiKit.style_label(_problem, SMALL_FONT_SIZE, Palette.TEXT_WARNING)
	UiKit.style_label(_warning_big_text, TEXT_FONT_SIZE, Palette.TEXT_WARNING)
	_warning_big_text.add_theme_font_override("font", UiKit.bold_font())
	_warning_big_text.text = UiText.MIX_WARNING
	_warning_big.add_theme_stylebox_override("panel", _choice_box(Palette.MIX_WARNING_BG, Palette.MIX_WARNING_BORDER))
	UiKit.style_label(_warning_small, SMALL_FONT_SIZE - 2, Palette.TEXT_WARNING)
	_warning_small.text = UiText.MIX_WARNING
	for button: BaseButton in [_close, _recipe_button, _mastery_close, _recipe_close, _to_party, _show_info, _again, _tribe_filter, _sort, _keep_own, _keep_legacy]:
		UiKit.style_button(button, BUTTON_FONT_SIZE)
	UiKit.style_button(_swap, SWAP_FONT_SIZE)
	UiKit.style_button(_mastery_button, SMALL_FONT_SIZE)
	_mastery_button.add_theme_color_override("font_color", Palette.MIX_MASTERY_BAR)
	UiKit.style_button(_go, GO_FONT_SIZE)
	_accent(_go, Palette.MIX_GO_BG, Palette.CORE_SHINE, Palette.CORE_SHINE)
	_accent(_to_party, Palette.MIX_ACCENT_BG, Palette.MIX_ACCENT_BORDER, Palette.TEXT)  # 결과 카드에서는 "파티에 넣기"만 강조색
	_close.text = UiText.BAG_CLOSE
	_mastery_close.text = UiText.BAG_CLOSE
	_recipe_close.text = UiText.BAG_CLOSE
	_swap.text = UiText.MIX_SWAP
	_go.text = UiText.MIX_GO
	_recipe_button.text = UiText.MIX_RECIPE_BUTTON
	_to_party.text = UiText.BTN_TO_PARTY
	_show_info.text = UiText.BTN_SHOW_INFO
	_again.text = UiText.BTN_MIX_AGAIN
	_chance_tip.add_theme_stylebox_override("panel", _choice_box(Palette.MIX_TIP_BG, Palette.PANEL_BORDER))
	UiKit.style_label(_chance_tip_text, SMALL_FONT_SIZE, Palette.TEXT)
	UiKit.style_label(_mastery_title, TITLE_FONT_SIZE - 2, Palette.TEXT)
	_mastery_title.text = UiText.MIX_MASTERY_TITLE
	UiKit.style_number(_mastery_now, TEXT_FONT_SIZE)
	UiKit.style_caption(_mastery_note, SMALL_FONT_SIZE)
	UiKit.style_label(_recipe_title, TITLE_FONT_SIZE - 2, Palette.TEXT)
	_recipe_title.text = UiText.MIX_RECIPE_TITLE
	UiKit.style_caption(_recipe_note, SMALL_FONT_SIZE)
	_recipe_note.text = UiText.MIX_RECIPE_NOTE
	_info.show_actions = false
	_build_choices()
	_build_filters()
	UiKit.style_label(_new_badge, TEXT_FONT_SIZE, Palette.MIX_NEW)
	_new_badge.add_theme_font_override("font", UiKit.bold_font())
	_new_badge.text = UiText.MIX_RESULT_NEW
	UiKit.style_label(_card_title, CARD_TITLE_FONT_SIZE, Palette.TEXT)
	_card_title.add_theme_font_override("font", UiKit.bold_font())
	UiKit.style_caption(_card_kind, TEXT_FONT_SIZE)
	UiKit.style_label(_card_info, TEXT_FONT_SIZE, Palette.TEXT)
	UiKit.style_caption(_card_passive_title, SMALL_FONT_SIZE)
	_card_passive_title.text = UiText.MIX_PASSIVE_PICK
	UiKit.style_label(_card_mastery, SMALL_FONT_SIZE, Palette.MIX_MASTERY_BAR)
	_close.pressed.connect(_on_close)
	_swap.pressed.connect(_on_swap)
	_go.pressed.connect(_on_go)
	_result_slot.pressed.connect(show_result_preview)
	_chance.pressed.connect(_toggle_chance_tip)
	_mastery_button.pressed.connect(open_mastery)
	_recipe_button.pressed.connect(open_recipes)
	_mastery_close.pressed.connect(_close_popups)
	_recipe_close.pressed.connect(_close_popups)
	_popup_dim.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			_close_popups())
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


## 큰 버튼 꾸미기: 바탕 · 테두리 · 글자 색(누를 수 없으면 기본 흐린 모양).
func _accent(button: Button, fill: Color, border: Color, text: Color) -> void:
	var box := _choice_box(fill, border)
	for state: String in ["normal", "hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(state, box)
	button.add_theme_color_override("font_color", text)
	button.add_theme_color_override("font_hover_color", text)
	button.add_theme_font_override("font", UiKit.bold_font())


## 성공 카드의 패시브 카드 두 장(자기 / 유산): 둘 중 하나만 눌리고, 고른 쪽은 흰 테두리 + 체크(노랑은 빛나는 코어 전용).
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
			_choose_passive(false))
	_keep_legacy.toggled.connect(func(on: bool) -> void:
		if on:
			_choose_passive(true))


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


## 그 코어를 주 코어로 열고, 보조 칸은 비운다. 오른쪽 정보창은 그 코어.
func open(main: CoreItem) -> void:
	main_core = main
	sub_core = null
	_result_layer.visible = false
	_close_popups()
	_chance_tip.visible = false
	visible = true
	_info.show_core(main)
	refresh()


## 재료 목록에서 그 코어를 누른 것처럼: 오른쪽에 상세를 보이고, 고를 수 있으면 빈 칸부터 채운다. 실행 검사에서도 쓴다.
func choose(item: CoreItem) -> void:
	if _busy:
		return
	_info.show_core(item)
	if item == main_core or item == sub_core:
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


## 오른쪽 정보창(실행 검사용).
func info() -> CoreInfo:
	return _info


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
	var has_pair := main_core != null and sub_core != null
	var result := Mix.result_id(main_core, sub_core) if has_pair else ""
	var reveal := Mix.reveal_of(result)
	_flasks.main_liquid = _liquid(main_core)
	_flasks.sub_liquid = _liquid(sub_core)
	_flasks.brewing = has_pair and result != ""
	_swap_result.text = UiText.MIX_SWAP_RESULT % _swapped_outcome() if has_pair else ""
	_show_result_slot(result, reveal, has_pair)
	_show_chance(result, reveal, has_pair)
	var problem := _workshop.mix_problem(main_core, sub_core)
	_problem.text = UiText.MIX_PROBLEMS[problem] if problem != Mix.Problem.MISSING else ""
	_go.disabled = problem != Mix.Problem.NONE or _busy
	var big := _workshop.mastery.mixes < GameConfig.MIX_WARNING_BIG_TIMES
	_warning_big.visible = big
	_warning_small.visible = not big
	_mastery_button.text = UiText.MIX_MASTERY_BUTTON % _workshop.mastery.level
	if _info.previewing:
		show_result_preview()
	_rebuild_materials()


## 비커 액체 색: 그 칸 코어의 종족 색(비었으면 투명).
static func _liquid(item: CoreItem) -> Color:
	return TribeDb.get_tribe(item.species().tribe).color if item != null else Color.TRANSPARENT


## 주·보조를 바꾸면 나올 결과: 공개 공식이면 이름, 아니면(힌트 · 비밀 · 공식 없음) ?
func _swapped_outcome() -> String:
	var swapped := Mix.result_id(sub_core, main_core)
	if swapped == "" or Mix.reveal_of(swapped) != Mix.Reveal.OPEN:
		return UiText.MIX_SECRET
	return HenchDb.get_species(swapped).name


## 주·보조를 바꾸면 나올 결과 글자(실행 검사용).
func swap_result_text() -> String:
	return _swap_result.text


## 결과 칸: 공개 = 그림 + 이름, 힌트 = 실루엣 + ???, 비밀 · 공식 없음 · 재료가 덜 참 = ?
func _show_result_slot(result: String, reveal: Mix.Reveal, has_pair: bool) -> void:
	var secret := not has_pair or result == "" or reveal == Mix.Reveal.SECRET
	_result_secret.visible = secret
	_result_portrait.visible = not secret
	_result_name.text = _outcome_name(result, reveal, has_pair)
	if secret:
		return
	var species := HenchDb.get_species(result)
	_result_portrait.texture = TribeDb.portrait(species.tribe)
	_result_portrait.modulate = Color.WHITE if reveal == Mix.Reveal.OPEN else Palette.SILHOUETTE


## 결과 이름: 공개 = 이름(초안 공식이면 표시), 힌트 = ???, 그 밖 = ?
func _outcome_name(result: String, reveal: Mix.Reveal, has_pair: bool) -> String:
	if not has_pair or result == "" or reveal == Mix.Reveal.SECRET:
		return UiText.MIX_SECRET
	var draft := (" " + UiText.MIX_DRAFT) if Mix.is_draft(main_core, sub_core) else ""
	if reveal == Mix.Reveal.HINT:
		return UiText.MIX_HINT_NAME + draft
	return HenchDb.get_species(result).name + draft


## 결과 이름 글자(실행 검사용).
func result_name_text() -> String:
	return _result_name.text


## 성공 확률 숫자 하나(누르면 내역)와 비용. 비밀 공식은 확률을 ?로 둔다.
func _show_chance(result: String, reveal: Mix.Reveal, has_pair: bool) -> void:
	var known := has_pair and result != "" and reveal != Mix.Reveal.SECRET
	var parts := _workshop.mix_chance(main_core, sub_core) if has_pair else Mix.success_parts("")
	_chance.text = UiText.MIX_CHANCE % (UiText.PERCENT % roundi(parts["total"] * 100.0) if known else UiText.UNKNOWN_PERCENT)
	_chance.disabled = not known
	_chance_tip_text.text = UiText.MIX_CHANCE_TIP % [roundi(parts["base"] * 100.0), roundi(parts["mastery"] * 100.0), roundi(parts["mark"] * 100.0)]
	if not known:
		_chance_tip.visible = false
	_cost.text = UiText.MIX_COST % [Mix.gold_cost(result), _workshop.wallet.gold]


## 성공 확률 글자(실행 검사용).
func chance_text() -> String:
	return _chance.text


## 성공 확률을 누름: 내역 말풍선을 그 숫자 바로 아래에 잠깐 띄운다(다시 누르면 닫힘).
func _toggle_chance_tip() -> void:
	if _chance_tip.visible:
		_chance_tip.visible = false
		return
	_chance_tip.reset_size()
	var rect := _chance.get_global_rect()
	_chance_tip.global_position = Vector2(rect.get_center().x - _chance_tip.size.x * 0.5, rect.end.y + 4.0)
	_chance_tip.visible = true
	_tip_left = GameConfig.MIX_TIP_SECONDS


## 내역 말풍선이 떠 있나 · 그 글자(실행 검사용).
func is_showing_chance_tip() -> bool:
	return _chance_tip.visible


func chance_tip_text() -> String:
	return _chance_tip_text.text


func _process(delta: float) -> void:
	if _chance_tip.visible:
		_tip_left -= delta
		if _tip_left <= 0.0:
			_chance_tip.visible = false


## 결과 칸을 누름: 오른쪽 정보창에 미리보기(예상 레벨 · 접미사 확률 · 계승 스탯 · 나이 · 성별 확률).
func show_result_preview() -> void:
	var has_pair := main_core != null and sub_core != null
	var result := Mix.result_id(main_core, sub_core) if has_pair else ""
	var reveal := Mix.reveal_of(result)
	var values := PackedStringArray()
	values.resize(UiText.MIX_PREVIEW_CAPTIONS.size())
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
	var rows := []
	for i in values.size():
		rows.append([UiText.MIX_PREVIEW_CAPTIONS[i], values[i]])
	var name_text := _outcome_name(result, reveal, has_pair)
	if not has_pair:
		_info.show_preview(name_text, UiText.MIX_EMPTY_KIND, null, false, rows, null)
	elif result == "" or reveal == Mix.Reveal.SECRET:
		_info.show_preview(name_text, UiText.MIX_SECRET_KIND if result != "" else UiText.MIX_PROBLEMS[Mix.Problem.NO_RECIPE], null, false, rows, null)
	else:
		var species := HenchDb.get_species(result)
		var tribe := TribeDb.get_tribe(species.tribe)
		if reveal == Mix.Reveal.OPEN:
			var kind := UiText.INFO_KIND % [tribe.name, UiText.ROLE_NAMES.get(species.role, species.role), UiText.GRADE_NAMES.get(species.grade, species.grade)]
			_info.show_preview(name_text, kind, TribeDb.portrait(species.tribe), false, rows, species)
		else:
			_info.show_preview(name_text, UiText.MIX_HINT_KIND % tribe.name, TribeDb.portrait(species.tribe), true, rows, null)


## 주 · 보조 칸: 코어가 있으면 크게 보이고, 누르면 그 칸을 비운다. 비었으면 비커만.
func _show_slot(holder: CenterContainer, item: CoreItem, is_main: bool) -> void:
	for child in holder.get_children():
		holder.remove_child(child)
		child.queue_free()
	if item == null:
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


## 재료 목록: 종족 필터 · 정렬을 따르고, 고를 수 없는 코어는 흐리게 + 까닭. 고른 코어는 흰 테두리 + 체크.
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


## 재료 목록 칸 크기와 열 수를 남은 자리에 맞춘다: count개가 스크롤 없이 모두 들어가는 가장 큰 칸.
## 너무 많아 다 안 들어가면 MATERIAL_ROWS줄이 보이는 크기로 두고 굴린다. 휴대폰이 길면 한 줄에 더 많이.
func _layout_materials(count: int) -> void:
	var gap := float(_materials.get_theme_constant("h_separation"))
	var width := _material_scroll.size.x - SCROLL_BAR_ROOM
	var height := _material_scroll.size.y
	if width <= 0.0 or height <= 0.0:
		return
	var side := clampf((height - gap * (MATERIAL_ROWS - 1)) / MATERIAL_ROWS, MATERIAL_CARD_MIN, MATERIAL_CARD_MAX)
	var biggest := MATERIAL_CARD_MAX
	while biggest >= MATERIAL_CARD_MIN:
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
	_close_popups()
	_chance_tip.visible = false
	hide()


# ─── 숙련 창 · 레시피 창 ─────────────────────────────

## 숙련 창: 단계별 성공 확률 보너스 표(지금 단계 줄 강조) + 지금 경험치 + 한 번에 얻는 경험치.
func open_mastery() -> void:
	var mastery := _workshop.mastery
	var exp_text := UiText.MIX_MASTERY_MAX if mastery.is_max() else UiText.MIX_MASTERY_EXP % [mastery.exp_points, mastery.exp_to_next()]
	_mastery_now.text = UiText.MIX_MASTERY_NOW % [mastery.level, exp_text]
	_mastery_note.text = UiText.MIX_MASTERY_NOTE % [GameConfig.MIX_MASTERY_EXP_PER_MIX, roundi(GameConfig.MIX_MASTERY_EXP_PER_MIX * GameConfig.MIX_MASTERY_FAIL_EXP_RATE)]
	for child in _mastery_table.get_children():
		_mastery_table.remove_child(child)
		child.queue_free()
	for header: String in UiText.MIX_MASTERY_HEADERS:
		_mastery_table.add_child(_table_cell(header, false, false))
	for level in range(1, GameConfig.MIX_MASTERY_MAX_LEVEL + 1):
		var now := level == mastery.level
		var bonus := roundi((level - 1) * GameConfig.MIX_MASTERY_BONUS_PER_LEVEL * 100.0)
		var to_next: String = str(GameConfig.MIX_MASTERY_EXP_TO_NEXT[level - 1]) if level < GameConfig.MIX_MASTERY_MAX_LEVEL else UiText.MIX_MASTERY_MAX
		for text: String in [UiText.MIX_MASTERY_STEP % level, UiText.MIX_MASTERY_BONUS % bonus, to_next]:
			_mastery_table.add_child(_table_cell(text, true, now))
	_open_popup(_mastery_window)


## 숙련 표 한 칸: 머리(연한 회색) / 값(흰색 굵게, 지금 단계가 아니면 흐리게), 지금 단계 줄은 바탕을 칠한다.
func _table_cell(text: String, value: bool, now: bool) -> PanelContainer:
	var cell := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Palette.MIX_TABLE_NOW if now else Color.TRANSPARENT
	box.content_margin_left = TABLE_PAD.x
	box.content_margin_right = TABLE_PAD.x
	box.content_margin_top = TABLE_PAD.y
	box.content_margin_bottom = TABLE_PAD.y
	cell.add_theme_stylebox_override("panel", box)
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var label := Label.new()
	if value:
		UiKit.style_number(label, SMALL_FONT_SIZE + 1)
		if not now:
			label.add_theme_color_override("font_color", Palette.TEXT_DIM)
	else:
		UiKit.style_caption(label, SMALL_FONT_SIZE)
	label.text = text
	cell.add_child(label)
	return cell


## 숙련 표의 그 단계 줄 글자(실행 검사용, 1부터).
func mastery_row_texts(level: int) -> PackedStringArray:
	var texts := PackedStringArray()
	var columns := _mastery_table.columns
	for i in columns:
		var cell := _mastery_table.get_child(level * columns + i)
		texts.append((cell.get_child(0) as Label).text)
	return texts


## 레시피 창: 공개 · 힌트 공식만(비밀은 숨김), 재료가 있는 공식을 위에 두고 누르면 칸을 채운다.
func open_recipes() -> void:
	for child in _recipe_list.get_children():
		_recipe_list.remove_child(child)
		child.queue_free()
	var rows: Array[Dictionary] = []
	for row in HenchDb.recipes():
		var reveal := Mix.reveal_of(row["result"])
		if reveal == Mix.Reveal.SECRET:
			continue
		var entry := row.duplicate()
		entry["reveal"] = reveal
		entry["pair"] = Mix.find_pair(_workshop.bag.cores, row["main"], row["sub"])
		rows.append(entry)
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ready_a := not (a["pair"] as Array).is_empty()
		var ready_b := not (b["pair"] as Array).is_empty()
		if ready_a != ready_b:
			return ready_a
		return str(a["main"]) + str(a["sub"]) < str(b["main"]) + str(b["sub"]))
	for entry in rows:
		_recipe_list.add_child(_recipe_row(entry))
	_open_popup(_recipe_window)


func _recipe_row(entry: Dictionary) -> Button:
	var result := HenchDb.get_species(entry["result"])
	var result_name := result.name if entry["reveal"] == Mix.Reveal.OPEN else UiText.MIX_HINT_NAME
	var text := UiText.MIX_RECIPE_ROW % [HenchDb.get_species(entry["main"]).name, HenchDb.get_species(entry["sub"]).name, result_name, UiText.GRADE_NAMES.get(result.grade, result.grade)]
	if entry["draft"]:
		text += UiText.MIX_RECIPE_DRAFT
	var has_pair := not (entry["pair"] as Array).is_empty()
	if has_pair:
		text += UiText.MIX_RECIPE_READY
	var button := Button.new()
	button.text = text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size.y = BUTTON_FONT_SIZE * 2.3
	UiKit.style_button(button, SMALL_FONT_SIZE + 1)
	button.add_theme_color_override("font_color", Palette.MIX_RECIPE_READY if has_pair else Palette.TEXT_DIM)
	button.add_theme_color_override("font_disabled_color", Palette.TEXT_DIM)
	button.disabled = not has_pair
	var main_id: String = entry["main"]
	var sub_id: String = entry["sub"]
	button.pressed.connect(func() -> void: use_recipe(main_id, sub_id))
	return button


## 레시피 창에서 공식을 누름: 가방에서 쓸 수 있는 한 쌍을 찾아 주 · 보조 칸을 채운다.
func use_recipe(main_id: String, sub_id: String) -> bool:
	var pair := Mix.find_pair(_workshop.bag.cores, main_id, sub_id)
	if pair.is_empty():
		return false
	main_core = pair[0]
	sub_core = pair[1]
	_close_popups()
	_info.show_core(main_core)
	refresh()
	return true


## 레시피 창 줄 수(실행 검사용).
func recipe_rows() -> int:
	return _recipe_list.get_child_count()


func _open_popup(window: PanelContainer) -> void:
	_mastery_window.visible = window == _mastery_window
	_recipe_window.visible = window == _recipe_window
	_popup_layer.visible = true


func _close_popups() -> void:
	_popup_layer.visible = false
	_mastery_window.visible = false
	_recipe_window.visible = false


## 숙련 창 · 레시피 창이 떠 있나(실행 검사용).
func is_showing_mastery() -> bool:
	return _popup_layer.visible and _mastery_window.visible


func is_showing_recipes() -> bool:
	return _popup_layer.visible and _recipe_window.visible


# ─── 연성하기 · 연출 · 결과 카드 ─────────────────────────

## 연성하기: 빛나는 코어나 높은 레벨 재료가 있으면 한 번 더 묻고, 아니면 바로.
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


## 믹스를 먼저 굴리고(패시브는 성공 카드에서 고른다), 결과에 맞는 연출을 한다:
## 성공 = 두 재료가 결과 플라스크로 모인다, 실패 = 두 재료가 흐려진다. 그다음 번쩍임과 결과 카드.
func _start_mix() -> void:
	if _busy:
		return
	_busy = true
	_go.disabled = true
	_chance_tip.visible = false
	_mixed_main = main_core
	_mixed_sub = sub_core
	_legacy_owner = main_core.passive_owner_id()
	last_born = _workshop.mix(main_core, sub_core, false)
	var tween := create_tween().set_parallel()
	if last_born != null:
		var target := _result_slot.get_global_rect().get_center()
		for slot: CenterContainer in [_main_slot, _sub_slot]:
			if slot.get_child_count() == 0:
				continue
			var original := slot.get_child(0) as CoreCard
			var flying := CoreCard.create(original.item, SLOT_CARD_SIZE)
			_fx_layer.add_child(flying)
			flying.mouse_filter = Control.MOUSE_FILTER_IGNORE
			flying.global_position = original.global_position
			flying.pivot_offset = SLOT_CARD_SIZE * 0.5
			original.modulate.a = 0.0
			tween.tween_property(flying, "global_position", target - SLOT_CARD_SIZE * 0.5, GameConfig.MIX_FX_GATHER_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tween.tween_property(flying, "scale", Vector2.ONE * 0.3, GameConfig.MIX_FX_GATHER_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tween.tween_property(flying, "modulate:a", 0.2, GameConfig.MIX_FX_GATHER_SECONDS)
	else:
		for slot: CenterContainer in [_main_slot, _sub_slot]:
			tween.tween_property(slot, "modulate:a", 0.15, GameConfig.MIX_FX_GATHER_SECONDS)
	tween.chain().tween_callback(_finish_mix)


func _finish_mix() -> void:
	for child in _fx_layer.get_children():
		child.queue_free()
	main_core = null
	sub_core = null
	for slot: CenterContainer in [_main_slot, _sub_slot]:
		slot.modulate.a = 1.0
	_busy = false
	if last_born != null:
		_info.show_core(last_born)
	refresh()
	_flash_screen(Palette.MIX_FLASH_SUCCESS if last_born != null else Palette.MIX_FLASH_FAIL)
	_show_result_card()


func _flash_screen(color: Color) -> void:
	_flash.color = Color(color, 0.85)
	create_tween().tween_property(_flash, "color:a", 0.0, GameConfig.MIX_FX_FLASH_SECONDS)


## 결과 카드(성공 · 실패 같은 모양): 이름 + 종족·역할·등급 + 내용 + (성공이면 패시브 고르기) + 얻은 숙련 경험치 + 버튼.
## 성공 = (NEW) 초상화 · LV·나이·성별 · 계승 스탯 · 패시브 카드 두 장(자기 / 유산), 버튼 셋(파티에 넣기만 강조).
## 실패 = 잃은 재료 두 칸 · "재료 둘이 사라졌습니다", 흔들림, 계속 믹스만.
func _show_result_card() -> void:
	_result_layer.visible = true
	_card_party.visible = false
	var born := last_born
	var success := born != null
	_new_badge.visible = success and _workshop.last_mix_new
	_card_portrait.visible = success
	_card_lost.visible = not success
	_card_passive_title.visible = success
	_card_passives.visible = success
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
		_keep_own.set_pressed_no_signal(born.passive_owner_id() == born.species_id)
		_keep_legacy.set_pressed_no_signal(born.passive_owner_id() != born.species_id)
		_label_passives()
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


## 성공 카드의 패시브 카드 글자: 자기 패시브 / 유산(주 코어의 지금 패시브), 고른 쪽 앞에 체크.
func _label_passives() -> void:
	if last_born == null:
		return
	var own := UiText.MIX_KEEP_OWN % last_born.species().passive
	var legacy := UiText.MIX_KEEP_LEGACY % HenchDb.get_species(_legacy_owner).passive
	var keep_legacy := last_born.passive_owner_id() != last_born.species_id
	_keep_own.text = own if keep_legacy else UiText.MIX_CHOSEN % own
	_keep_legacy.text = UiText.MIX_CHOSEN % legacy if keep_legacy else legacy


## 성공 카드에서 패시브를 고름(Workshop이 태어난 코어에 반영하고 저장을 앞당긴다).
func _choose_passive(legacy: bool) -> void:
	if last_born == null:
		return
	_workshop.choose_passive(last_born, _legacy_owner if legacy else "")
	_label_passives()
	if _info.item == last_born:
		_info.refresh()


## 성공 카드의 패시브 카드(실행 검사용): 0 = 자기, 1 = 유산.
func passive_choice(index: int) -> Button:
	return _keep_own if index == 0 else _keep_legacy


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


## 결과 카드가 떠 있나(실행 검사용).
func is_showing_result() -> bool:
	return _result_layer.visible


## 결과 카드 글자들(실행 검사용): 제목 · 종류 줄 · 내용 · 패시브(고른 쪽) · 숙련 경험치.
func result_card_texts() -> PackedStringArray:
	var passive := ""
	if _card_passives.visible:
		passive = _keep_legacy.text if _keep_legacy.button_pressed else _keep_own.text
	return PackedStringArray([_card_title.text, _card_kind.text, _card_info.text, passive, _card_mastery.text])


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

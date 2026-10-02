class_name MixPanel
extends PanelContainer
## 믹스창(가방 창 위에 뜬다): 주·보조 2칸, 성별 방향, 결과 미리보기(공개 = 이름 · 힌트 = 실루엣 · 비밀 = ?),
## 유산 패시브 선택(1칸), 골드 비용과 성공 확률. 아래 목록에서 보조 코어를 고른다.
## 사용자 결정(2026-10-02): 성공 확률이 있고, 실패하면 재료 둘이 모두 사라진다. 실제 처리는 Workshop.mix.
## 결과 초상화는 종족 그림(TribeDb.portrait)이고, 힌트는 같은 그림을 검게 칠해 실루엣으로 보인다.

## 믹스를 마쳤을 때(성공이면 새 코어, 실패면 null)
signal mixed(born: CoreItem)

const TITLE_FONT_SIZE := 20
const TEXT_FONT_SIZE := 14
const SMALL_FONT_SIZE := 13
const SECRET_FONT_SIZE := 64

## 주 코어(유산 패시브를 주는 쪽)와 보조 코어
var main_core: CoreItem
var sub_core: CoreItem
## 유산을 남기나(주 코어의 패시브를 받나)
var keep_legacy := false

var _workshop: Workshop
var _confirm: ConfirmBox

@onready var _title: Label = %Title
@onready var _close: Button = %Close
@onready var _main_label: Label = %MainLabel
@onready var _sub_label: Label = %SubLabel
@onready var _main_slot: CenterContainer = %MainSlot
@onready var _sub_slot: CenterContainer = %SubSlot
@onready var _direction: Label = %Direction
@onready var _result_label: Label = %ResultLabel
@onready var _result_portrait: TextureRect = %ResultPortrait
@onready var _result_secret: Label = %ResultSecret
@onready var _result_name: Label = %ResultName
@onready var _swap: Button = %Swap
@onready var _passive_title: Label = %PassiveTitle
@onready var _keep_own: Button = %KeepOwn
@onready var _keep_legacy: Button = %KeepLegacy
@onready var _cost: Label = %Cost
@onready var _warning: Label = %Warning
@onready var _problem: Label = %Problem
@onready var _candidates_label: Label = %CandidatesLabel
@onready var _candidates: HBoxContainer = %Candidates
@onready var _go: Button = %Go


func _ready() -> void:
	add_theme_stylebox_override("panel", UiKit.panel_box())
	UiKit.style_label(_title, TITLE_FONT_SIZE, Palette.TEXT)
	_title.text = UiText.MIX_TITLE
	for label: Label in [_main_label, _sub_label, _result_label, _passive_title, _candidates_label]:
		UiKit.style_label(label, SMALL_FONT_SIZE, Palette.TEXT_DIM)
	_main_label.text = UiText.MIX_MAIN
	_sub_label.text = UiText.MIX_SUB
	_result_label.text = UiText.MIX_RESULT
	_passive_title.text = UiText.MIX_PASSIVE_TITLE
	_candidates_label.text = UiText.MIX_CANDIDATES
	UiKit.style_label(_direction, TEXT_FONT_SIZE, Palette.TEXT)
	UiKit.style_label(_result_name, TEXT_FONT_SIZE + 2, Palette.TEXT)
	UiKit.style_label(_result_secret, SECRET_FONT_SIZE, Palette.TEXT_DIM)
	_result_secret.text = UiText.MIX_SECRET
	UiKit.style_label(_cost, TEXT_FONT_SIZE, Palette.CORE_SHINE)
	UiKit.style_label(_warning, SMALL_FONT_SIZE, Palette.TEXT_WARNING)
	_warning.text = UiText.MIX_WARNING
	UiKit.style_label(_problem, TEXT_FONT_SIZE, Palette.TEXT_WARNING)
	for button: BaseButton in [_close, _swap, _keep_own, _keep_legacy, _go]:
		UiKit.style_button(button, TEXT_FONT_SIZE)
	_close.text = UiText.BAG_CLOSE
	_swap.text = UiText.MIX_SWAP
	_go.text = UiText.MIX_GO
	# 패시브 고르기: 둘 중 하나만 눌리는 버튼(고른 쪽은 금빛 테두리)
	for choice: Button in [_keep_own, _keep_legacy]:
		var off := _choice_box(Palette.CARD_BG, Palette.CARD_BORDER)
		var on := _choice_box(Palette.CARD_SELECTED_BG, Palette.CORE_SHINE)
		for state: String in ["normal", "hover", "focus", "disabled"]:
			choice.add_theme_stylebox_override(state, off)
		for state: String in ["pressed", "hover_pressed"]:
			choice.add_theme_stylebox_override(state, on)
		choice.add_theme_color_override("font_pressed_color", Palette.CORE_SHINE)
		choice.add_theme_color_override("font_hover_pressed_color", Palette.CORE_SHINE)
	var group := ButtonGroup.new()
	_keep_own.button_group = group
	_keep_legacy.button_group = group
	_keep_own.toggled.connect(func(on: bool) -> void:
		if on:
			keep_legacy = false)
	_keep_legacy.toggled.connect(func(on: bool) -> void:
		if on:
			keep_legacy = true)
	_close.pressed.connect(hide)
	_swap.pressed.connect(_on_swap)
	_go.pressed.connect(_on_go)


func bind(workshop: Workshop, confirm: ConfirmBox) -> void:
	_workshop = workshop
	_confirm = confirm
	_workshop.bag.changed.connect(func() -> void:
		if visible:
			refresh())
	_workshop.wallet.changed.connect(func() -> void:
		if visible:
			refresh())


static func _choice_box(fill: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(2)
	box.set_corner_radius_all(8)
	box.content_margin_left = 10
	box.content_margin_right = 10
	return box


## 그 코어를 주 코어로 열고, 보조 칸은 비운다.
func open(main: CoreItem) -> void:
	main_core = main
	sub_core = null
	keep_legacy = false
	_keep_own.set_pressed_no_signal(true)
	_keep_legacy.set_pressed_no_signal(false)
	visible = true
	refresh()


## 보조 코어를 고른다.
func choose_sub(item: CoreItem) -> void:
	sub_core = item if item != main_core else null
	refresh()


## 고를 수 있는 보조 코어 칸(실행 검사용).
func candidate_for(item: CoreItem) -> CoreCard:
	for card: CoreCard in _candidates.get_children():
		if card.item == item:
			return card
	return null


func refresh() -> void:
	if main_core == null or not _workshop.bag.has(main_core):
		hide()
		return
	if sub_core != null and not _workshop.bag.has(sub_core):
		sub_core = null
	_show_slot(_main_slot, main_core)
	_show_slot(_sub_slot, sub_core)

	var result := Mix.result_id(main_core, sub_core) if sub_core != null else ""
	var reveal := Mix.reveal_of(result)
	var female := Mix.female_of(main_core, sub_core) if sub_core != null else null
	if female != null:
		var male := sub_core if female == main_core else main_core
		_direction.text = UiText.MIX_DIRECTION % [female.species().name, male.species().name]
	else:
		_direction.text = ""
	_show_result(result, reveal, sub_core != null)

	var own_passive := HenchDb.get_species(result).passive if reveal == Mix.Reveal.OPEN else UiText.MIX_HINT_NAME
	_keep_own.text = UiText.MIX_KEEP_OWN % own_passive
	_keep_legacy.text = UiText.MIX_KEEP_LEGACY % HenchDb.get_species(main_core.passive_owner_id()).passive

	var chance := Mix.success_chance(result)
	var chance_text := UiText.UNKNOWN_PERCENT if reveal == Mix.Reveal.SECRET else UiText.PERCENT % roundi(chance * 100.0)
	_cost.text = UiText.MIX_COST % [Mix.gold_cost(result), _workshop.wallet.gold, chance_text]
	var problem := _workshop.mix_problem(main_core, sub_core)
	_problem.text = UiText.MIX_PROBLEMS[problem]
	_go.disabled = problem != Mix.Problem.NONE
	_rebuild_candidates()


func _show_slot(holder: CenterContainer, item: CoreItem) -> void:
	for child in holder.get_children():
		holder.remove_child(child)
		child.queue_free()
	if item == null:
		var empty := Label.new()
		empty.text = UiText.MIX_SLOT_EMPTY
		UiKit.style_label(empty, SMALL_FONT_SIZE, Palette.TEXT_DIM)
		holder.add_child(empty)
		return
	var card := CoreCard.create(item)
	card.disabled = true  # 칸은 보여 주기만 한다(바꾸려면 아래 목록에서 고른다)
	holder.add_child(card)


## 결과 미리보기: 공개 = 초상화 + 이름, 힌트 = 검은 실루엣 + ???, 비밀 = ?
func _show_result(result: String, reveal: Mix.Reveal, has_pair: bool) -> void:
	_result_secret.visible = has_pair and reveal == Mix.Reveal.SECRET
	_result_portrait.visible = has_pair and reveal != Mix.Reveal.SECRET
	_result_name.text = ""
	if not has_pair:
		return
	if reveal == Mix.Reveal.SECRET:
		return
	var species := HenchDb.get_species(result)
	_result_portrait.texture = TribeDb.portrait(species.tribe)
	if reveal == Mix.Reveal.OPEN:
		_result_portrait.modulate = Color.WHITE
		_result_name.text = species.name
	else:
		_result_portrait.modulate = Palette.SILHOUETTE
		_result_name.text = UiText.MIX_HINT_NAME


## 아래 목록: 주 코어를 뺀 가방의 코어. 짝이 될 수 있는 것(반대 성별 · 잠금·파티 아님)이 앞, 그 안에서는 새로 얻은 것이 앞.
## 누르면 보조 칸에 들어간다.
func _rebuild_candidates() -> void:
	for child in _candidates.get_children():
		_candidates.remove_child(child)
		child.queue_free()
	var usable: Array[CoreItem] = []
	var others: Array[CoreItem] = []
	var cores := _workshop.bag.cores
	for i in range(cores.size() - 1, -1, -1):
		var item := cores[i]
		if item == main_core:
			continue
		var fits := item.gender != main_core.gender and not item.locked and not item.in_party()
		(usable if fits else others).append(item)
	for item in usable + others:
		var card := CoreCard.create(item)
		card.selected = item == sub_core
		card.pressed.connect(choose_sub.bind(item))
		_candidates.add_child(card)


func _on_swap() -> void:
	if sub_core == null:
		return
	var old_main := main_core
	main_core = sub_core
	sub_core = old_main
	refresh()


func _on_go() -> void:
	if _workshop.mix_problem(main_core, sub_core) != Mix.Problem.NONE:
		return
	var result := Mix.result_id(main_core, sub_core)
	var chance_text := UiText.UNKNOWN_PERCENT if Mix.reveal_of(result) == Mix.Reveal.SECRET else UiText.PERCENT % roundi(Mix.success_chance(result) * 100.0)
	_confirm.ask(UiText.MIX_ASK % chance_text, _do_mix)


func _do_mix() -> void:
	var born := _workshop.mix(main_core, sub_core, keep_legacy)
	hide()
	if born != null:
		_confirm.tell(UiText.MIX_SUCCESS % [born.species().name, UiText.GENDER_NAMES[born.gender], UiText.AGE_NAMES[born.age]])
	else:
		_confirm.tell(UiText.MIX_FAIL)
	mixed.emit(born)

class_name BagPanel
extends PanelContainer
## 코어 가방 창(믹스마스터식, 사용자 결정 2026-10-03): 왼쪽은 고른 코어의 정보창, 오른쪽은 5열 칸(새로 얻은 것이 앞).
## 화면 세로를 꽉 채운다. 위쪽에 골드·코어 조각. 사냥 기록(하루 처치 수 측정)은 디버그 화면으로 옮겼다.
## 가방 버튼으로 열고 닫는다.
## 정보창의 버튼: 파티 편성·믹스는 신호로 HUD(→ main · 믹스창)에, 분해·잠금은 여기서 Workshop으로 처리한다.
## 위치·크기·열 수는 이 장면(bag_panel.tscn)이나 hud.tscn에서 에디터로 정한다.

signal mix_requested(item: CoreItem)
signal party_requested(item: CoreItem, slot: int)
signal party_leave_requested(item: CoreItem)

const TITLE_FONT_SIZE := 24
const TEXT_FONT_SIZE := 18

var _bag: Bag
var _wallet: Wallet
var _workshop: Workshop
var _confirm: ConfirmBox
var _selected: CoreItem

@onready var _title: Label = %Title
@onready var _money: Label = %Money
@onready var _close: Button = %Close
@onready var _grid: GridContainer = %Grid
@onready var _empty: Label = %Empty
@onready var _info: CoreInfo = %CoreInfo


func _ready() -> void:
	add_theme_stylebox_override("panel", UiKit.panel_box())
	UiKit.style_label(_title, TITLE_FONT_SIZE, Palette.TEXT)
	_title.add_theme_font_override("font", UiKit.bold_font())
	UiKit.style_label(_money, TEXT_FONT_SIZE, Palette.CORE_SHINE)
	UiKit.style_caption(_empty, TEXT_FONT_SIZE)
	UiKit.style_button(_close, TEXT_FONT_SIZE)
	_close.text = UiText.BAG_CLOSE
	_close.pressed.connect(close)
	_empty.text = UiText.BAG_EMPTY
	_info.mix_requested.connect(func(item: CoreItem) -> void: mix_requested.emit(item))
	_info.party_requested.connect(func(item: CoreItem, slot: int) -> void: party_requested.emit(item, slot))
	_info.party_leave_requested.connect(func(item: CoreItem) -> void: party_leave_requested.emit(item))
	_info.dismantle_requested.connect(_on_dismantle)
	_info.lock_requested.connect(func(item: CoreItem) -> void: _workshop.toggle_lock(item))
	_info.level_up_requested.connect(func(item: CoreItem) -> void: _workshop.level_up(item))


func bind(bag: Bag) -> void:
	_bag = bag
	_bag.changed.connect(_on_bag_changed)


func bind_collection(wallet: Wallet, workshop: Workshop, confirm: ConfirmBox, party_names: Callable) -> void:
	_wallet = wallet
	_workshop = workshop
	_confirm = confirm
	_info.party_names = party_names
	_info.workshop = workshop
	_wallet.changed.connect(_update_money)
	_wallet.changed.connect(func() -> void:
		if visible:
			_info.refresh())  # 골드가 바뀌면 레벨업 버튼(살 수 있나)도 다시
	_workshop.progress.changed.connect(func() -> void:
		if visible:
			_info.refresh())  # 주인공 레벨이 오르면 레벨업 상한도 다시


func open() -> void:
	visible = true
	_rebuild()
	_update_money()


func close() -> void:
	visible = false


## 그 코어를 골라 정보창에 띄운다(null = 고른 것 없음).
func select(item: CoreItem) -> void:
	_selected = item
	for card: CoreCard in _grid.get_children():
		card.selected = card.item == item
	_info.show_core(item)


## 지금 보이는 코어 칸 수(실행 검사용).
func card_count() -> int:
	return _grid.get_child_count()


## 그 코어의 칸(실행 검사용). 없으면 null.
func card_for(item: CoreItem) -> CoreCard:
	for card: CoreCard in _grid.get_children():
		if card.item == item:
			return card
	return null


## 정보창(실행 검사용).
func info() -> CoreInfo:
	return _info


func _on_bag_changed() -> void:
	if visible:
		_rebuild()


func _rebuild() -> void:
	for child in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	for i in range(_bag.count() - 1, -1, -1):
		var card := CoreCard.create(_bag.cores[i], CoreCard.BAG_SIZE)
		card.pressed.connect(select.bind(card.item))
		_grid.add_child(card)
	_title.text = UiText.BAG_TITLE % _bag.count()
	_empty.visible = _bag.count() == 0
	select(_selected if _selected != null and _bag.has(_selected) else null)


func _update_money() -> void:
	if _wallet != null:
		_money.text = UiText.MONEY % [_wallet.gold, _wallet.shards]


func _on_dismantle(item: CoreItem) -> void:
	if not _workshop.can_dismantle(item):
		return
	_confirm.ask(UiText.DISMANTLE_ASK % [item.title(), Mix.dismantle_shards(item)], func() -> void:
		_workshop.dismantle(item)
		select(null))

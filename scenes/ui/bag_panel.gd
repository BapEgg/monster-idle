class_name BagPanel
extends PanelContainer
## 코어 가방 창(믹스마스터식): 왼쪽은 5열 칸(새로 얻은 것이 앞), 오른쪽은 고른 코어의 정보창.
## 위쪽에 골드·코어 조각과 사냥 기록(하루 처치 수 측정). 가방 버튼으로 열고 닫는다.
## 정보창의 버튼: 파티 편성·믹스는 신호로 HUD(→ main · 믹스창)에, 분해·잠금은 여기서 Workshop으로 처리한다.
## 위치·크기·열 수는 이 장면(bag_panel.tscn)이나 hud.tscn에서 에디터로 정한다.

signal mix_requested(item: CoreItem)
signal party_requested(item: CoreItem, slot: int)
signal party_leave_requested(item: CoreItem)

const TITLE_FONT_SIZE := 20
const TEXT_FONT_SIZE := 14
## 사냥 기록 글자를 다시 쓰는 간격(초)
const STATS_REFRESH_SECONDS := 0.5

var _bag: Bag
var _log: HuntLog
var _wallet: Wallet
var _workshop: Workshop
var _confirm: ConfirmBox
var _selected: CoreItem
var _refresh_left := 0.0

@onready var _title: Label = %Title
@onready var _money: Label = %Money
@onready var _close: Button = %Close
@onready var _totals: Label = %Totals
@onready var _rates: Label = %Rates
@onready var _grid: GridContainer = %Grid
@onready var _empty: Label = %Empty
@onready var _info: CoreInfo = %CoreInfo


func _ready() -> void:
	add_theme_stylebox_override("panel", UiKit.panel_box())
	UiKit.style_label(_title, TITLE_FONT_SIZE, Palette.TEXT)
	UiKit.style_label(_money, TEXT_FONT_SIZE, Palette.CORE_SHINE)
	UiKit.style_label(_totals, TEXT_FONT_SIZE, Palette.TEXT)
	UiKit.style_label(_rates, TEXT_FONT_SIZE, Palette.TEXT_DIM)
	UiKit.style_label(_empty, TEXT_FONT_SIZE, Palette.TEXT_DIM)
	UiKit.style_button(_close, TEXT_FONT_SIZE)
	_close.text = UiText.BAG_CLOSE
	_close.pressed.connect(close)
	_empty.text = UiText.BAG_EMPTY
	_info.mix_requested.connect(func(item: CoreItem) -> void: mix_requested.emit(item))
	_info.party_requested.connect(func(item: CoreItem, slot: int) -> void: party_requested.emit(item, slot))
	_info.party_leave_requested.connect(func(item: CoreItem) -> void: party_leave_requested.emit(item))
	_info.dismantle_requested.connect(_on_dismantle)
	_info.lock_requested.connect(func(item: CoreItem) -> void: _workshop.toggle_lock(item))


func bind(bag: Bag, hunt_log: HuntLog) -> void:
	_bag = bag
	_log = hunt_log
	_bag.changed.connect(_on_bag_changed)


func bind_collection(wallet: Wallet, workshop: Workshop, confirm: ConfirmBox, party_names: Callable) -> void:
	_wallet = wallet
	_workshop = workshop
	_confirm = confirm
	_info.party_names = party_names
	_wallet.changed.connect(_update_money)


func open() -> void:
	visible = true
	_rebuild()
	_refresh_stats()
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


func _process(delta: float) -> void:
	if not visible or _log == null:
		return
	_refresh_left -= delta
	if _refresh_left <= 0.0:
		_refresh_stats()


func _on_bag_changed() -> void:
	if visible:
		_rebuild()


func _rebuild() -> void:
	for child in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	for i in range(_bag.count() - 1, -1, -1):
		var card := CoreCard.create(_bag.cores[i])
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


func _refresh_stats() -> void:
	_refresh_left = STATS_REFRESH_SECONDS
	_totals.text = UiText.HUNT_TOTALS % [_log.kills(), _log.cores, _log.shining_cores]
	var advantage := _log.manual_advantage()
	_rates.text = UiText.HUNT_RATES % [
		_count_text(_log.kills_per_hour(false)),
		_count_text(_log.kills_per_hour(true)),
		UiText.HUNT_UNKNOWN if is_nan(advantage) else UiText.HUNT_ADVANTAGE % roundi(advantage * 100.0),
		_count_text(_log.daily_kills_estimate()),
	]


static func _count_text(value: float) -> String:
	return UiText.HUNT_UNKNOWN if value < 0.0 else str(roundi(value))

class_name BagPanel
extends PanelContainer
## 코어 가방 창(믹스마스터식, 사용자 결정 2026-10-03): 왼쪽은 고른 코어의 정보창, 오른쪽은 5열 칸(새로 얻은 것이 앞).
## 코어 칸 아래에 코어 조각 칸(종마다 "코어 조각 n/12", 덜 모이면 흑백으로 흐리게 — 다 모이면 눌러서 그 종 코어를 만든다, 임시).
## 화면 세로를 꽉 채운다. 재화(골드 · 경험치 조각)는 메인 화면 오른쪽 위로 옮겼다(사용자 결정 2026-10-03).
## 사냥 기록(하루 처치 수 측정)은 디버그 화면으로 옮겼다.
## 가방 버튼으로 열고 닫는다.
## 정보창의 버튼: 파티 편성·믹스는 신호로 HUD(→ main · 믹스창)에, 분해·잠금은 여기서 Workshop으로 처리한다.
## 위치·크기·열 수는 이 장면(bag_panel.tscn)이나 hud.tscn에서 에디터로 정한다.

signal mix_requested(item: CoreItem)
signal party_requested(item: CoreItem, slot: int)
signal party_leave_requested(item: CoreItem)

const TITLE_FONT_SIZE := 24
const TEXT_FONT_SIZE := 18
const SHARD_TITLE_FONT_SIZE := 15

var _bag: Bag
var _wallet: Wallet
var _workshop: Workshop
var _confirm: ConfirmBox
var _selected: CoreItem
var _shown_shards := ""  # 정보창에 띄운 코어 조각 칸의 종
var _shard_snapshot := {}  # 조각 칸을 마지막으로 만든 때의 지갑 코어 조각(골드만 바뀌면 다시 만들지 않는다)

@onready var _title: Label = %Title
@onready var _close: Button = %Close
@onready var _grid: GridContainer = %Grid
@onready var _shard_title: Label = %ShardTitle
@onready var _shard_grid: GridContainer = %ShardGrid
@onready var _empty: Label = %Empty
@onready var _info: CoreInfo = %CoreInfo


func _ready() -> void:
	add_theme_stylebox_override("panel", UiKit.panel_box())
	UiKit.style_label(_title, TITLE_FONT_SIZE, Palette.TEXT)
	_title.add_theme_font_override("font", UiKit.bold_font())
	UiKit.style_caption(_shard_title, SHARD_TITLE_FONT_SIZE)
	_shard_title.text = UiText.SHARD_SECTION % GameConfig.CORE_SHARDS_PER_CORE
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
	_info.feed_requested.connect(func(item: CoreItem) -> void: _workshop.feed_shards(item))


func bind(bag: Bag) -> void:
	_bag = bag
	_bag.changed.connect(_on_bag_changed)


func bind_collection(wallet: Wallet, workshop: Workshop, confirm: ConfirmBox, party_names: Callable) -> void:
	_wallet = wallet
	_workshop = workshop
	_confirm = confirm
	_info.party_names = party_names
	_info.workshop = workshop
	_wallet.changed.connect(func() -> void:
		if visible:
			_rebuild_shards()
			_info.refresh())  # 경험치 조각이 바뀌면 먹이기 버튼도 다시
	_workshop.progress.changed.connect(func() -> void:
		if visible:
			_info.refresh())  # 주인공 레벨이 오르면 헨치 레벨 상한도 다시


func open() -> void:
	visible = true
	_rebuild()


func close() -> void:
	visible = false


## 그 코어를 골라 정보창에 띄운다(null = 고른 것 없음).
func select(item: CoreItem) -> void:
	_selected = item
	_shown_shards = ""
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


## 그 종의 코어 조각 칸(실행 검사용). 없으면 null.
func shard_card_for(species_id: String) -> ShardCard:
	for card: ShardCard in _shard_grid.get_children():
		if card.species_id == species_id:
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
	_rebuild_shards(true)
	_empty.visible = _bag.count() == 0 and _shard_grid.get_child_count() == 0
	if _shown_shards == "":
		select(_selected if _selected != null and _bag.has(_selected) else null)


## 코어 조각 칸: 모은 조각이 있는 종마다 하나(많이 모은 것이 앞). 없으면 제목째 숨는다.
## force가 아니면 코어 조각이 바뀌었을 때만 다시 만든다(사냥 중 골드가 오를 때마다 칸을 새로 만들지 않게).
func _rebuild_shards(force := false) -> void:
	if _wallet == null:
		return
	if not force and _wallet.core_shards == _shard_snapshot:
		return
	_shard_snapshot = _wallet.core_shards.duplicate()
	for child in _shard_grid.get_children():
		_shard_grid.remove_child(child)
		child.queue_free()
	var ids: Array = _wallet.core_shards.keys()
	ids.sort_custom(func(a: String, b: String) -> bool:
		var left := _wallet.core_shards_of(a)
		var right := _wallet.core_shards_of(b)
		return left > right if left != right else a < b)
	for id: String in ids:
		var card := ShardCard.create(id, _wallet.core_shards_of(id))
		card.pressed.connect(_on_shard_pressed.bind(id))
		_shard_grid.add_child(card)
	_shard_title.visible = not ids.is_empty()
	_shard_grid.visible = not ids.is_empty()
	if _shown_shards != "":
		if _wallet.core_shards_of(_shown_shards) <= 0:
			select(null)
		else:
			show_shards(_shown_shards)  # 모은 수가 바뀌었으면 정보창도


## 코어 조각 칸을 누름: 정보창에 그 종(모은 조각 · 얻는 곳 · 고유 스킬). 다 모인 칸이면 만들기 확인 창도 띄운다.
func _on_shard_pressed(species_id: String) -> void:
	show_shards(species_id)
	if not _workshop.can_make_from_shards(species_id):
		return
	var species := HenchDb.get_species(species_id)
	_confirm.ask(UiText.SHARD_MAKE_ASK % [species.name, GameConfig.CORE_SHARDS_PER_CORE], func() -> void:
		var made := _workshop.make_from_shards(species_id)
		if made != null:
			select(made))


## 정보창에 그 종의 코어 조각 정보를 띄운다.
func show_shards(species_id: String) -> void:
	var species := HenchDb.get_species(species_id)
	if species == null:
		return
	_selected = null
	for card: CoreCard in _grid.get_children():
		card.selected = false
	var tribe := TribeDb.get_tribe(species.tribe)
	var kind := UiText.INFO_KIND % [tribe.name, UiText.ROLE_NAMES.get(species.role, species.role), UiText.GRADE_NAMES.get(species.grade, species.grade)]
	var rows := [
		[UiText.SHARD_INFO_COUNT, "%d / %d" % [_wallet.core_shards_of(species_id), GameConfig.CORE_SHARDS_PER_CORE]],
		[UiText.SHARD_INFO_SOURCE, UiText.SHARD_INFO_SOURCE_VALUE],
	]
	_info.show_preview(species.name, kind, TribeDb.portrait(species.tribe), false, rows, species)
	_shown_shards = species_id


func _on_dismantle(item: CoreItem) -> void:
	if not _workshop.can_dismantle(item):
		return
	_confirm.ask(UiText.DISMANTLE_ASK % [item.title(), item.species().name, Mix.dismantle_shards(item)], func() -> void:
		_workshop.dismantle(item)
		select(null))

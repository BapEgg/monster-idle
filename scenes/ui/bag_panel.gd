class_name BagPanel
extends PanelContainer
## 코어 가방 창: 모은 코어를 칸으로 보여 주고(새로 얻은 것이 앞), 위쪽에 사냥 기록(하루 처치 수 측정)을 보여 준다.
## 가방 버튼으로 열고 닫는다. 위치·크기는 hud.tscn에서 이 창을 골라 에디터로 정한다.

const TITLE_FONT_SIZE := 20
const TEXT_FONT_SIZE := 14
const CORNER := 12
## 사냥 기록 글자를 다시 쓰는 간격(초)
const STATS_REFRESH_SECONDS := 0.5

var _bag: Bag
var _log: HuntLog
var _refresh_left := 0.0

@onready var _title: Label = %Title
@onready var _close: Button = %Close
@onready var _totals: Label = %Totals
@onready var _rates: Label = %Rates
@onready var _grid: GridContainer = %Grid
@onready var _empty: Label = %Empty


func _ready() -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = Palette.PANEL_BG
	box.border_color = Palette.PANEL_BORDER
	box.set_border_width_all(1)
	box.set_corner_radius_all(CORNER)
	add_theme_stylebox_override("panel", box)
	_style(_title, TITLE_FONT_SIZE, Palette.TEXT)
	_style(_totals, TEXT_FONT_SIZE, Palette.TEXT)
	_style(_rates, TEXT_FONT_SIZE, Palette.TEXT_DIM)
	_style(_empty, TEXT_FONT_SIZE, Palette.TEXT_DIM)
	_close.text = UiText.BAG_CLOSE
	_close.pressed.connect(close)
	_empty.text = UiText.BAG_EMPTY


func bind(bag: Bag, hunt_log: HuntLog) -> void:
	_bag = bag
	_log = hunt_log
	_bag.changed.connect(_on_bag_changed)


func open() -> void:
	visible = true
	_rebuild()
	_refresh_stats()


func close() -> void:
	visible = false


## 지금 보이는 코어 칸 수(실행 검사용).
func card_count() -> int:
	return _grid.get_child_count()


func _process(delta: float) -> void:
	if not visible or _log == null:
		return
	_refresh_left -= delta
	if _refresh_left <= 0.0:
		_refresh_stats()


func _on_bag_changed() -> void:
	if not visible:
		return
	# 창이 열려 있으면 새로 얻은 코어를 맨 앞에 붙인다(전부 다시 만들지 않게).
	var card := CoreCard.create(_bag.cores.back())
	_grid.add_child(card)
	_grid.move_child(card, 0)
	_update_title()


func _rebuild() -> void:
	for child in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	for i in range(_bag.count() - 1, -1, -1):
		_grid.add_child(CoreCard.create(_bag.cores[i]))
	_update_title()


func _update_title() -> void:
	_title.text = UiText.BAG_TITLE % _bag.count()
	_empty.visible = _bag.count() == 0


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


static func _style(label: Label, font_size: int, color: Color) -> void:
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)

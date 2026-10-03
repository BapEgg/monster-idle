class_name DebugPanel
extends PanelContainer
## 디버그 화면(개발 확인용, GameConfig.DEV_DEBUG_PANEL): 사냥 기록(이번 접속)과 시간당 처치(하루 처치 수 측정),
## 파티 헨치 3마리의 전투 값(코어 능력치 → 임시 환산). 원래 가방 창 위에 있던 것을 옮겼다(사용자 결정 2026-10-03).
## 화면 오른쪽 위 디버그 버튼으로 열고 닫는다. 위치·크기는 debug_panel.tscn을 에디터에서 연다.

const TITLE_FONT_SIZE := 22
const TEXT_FONT_SIZE := 17
## 글자를 다시 쓰는 간격(초)
const REFRESH_SECONDS := 0.5

var _log: HuntLog
var _party: Array[Hench] = []
var _refresh_left := 0.0

@onready var _title: Label = %Title
@onready var _close: Button = %Close
@onready var _totals: Label = %Totals
@onready var _rates: Label = %Rates
@onready var _party_title: Label = %PartyTitle
@onready var _party_rows: Label = %PartyRows


func _ready() -> void:
	add_theme_stylebox_override("panel", UiKit.panel_box())
	UiKit.style_label(_title, TITLE_FONT_SIZE, Palette.TEXT)
	_title.text = UiText.DEBUG_TITLE
	UiKit.style_label(_totals, TEXT_FONT_SIZE, Palette.TEXT)
	UiKit.style_caption(_rates, TEXT_FONT_SIZE)
	UiKit.style_caption(_party_title, TEXT_FONT_SIZE)
	_party_title.text = UiText.DEBUG_PARTY_TITLE
	UiKit.style_label(_party_rows, TEXT_FONT_SIZE, Palette.TEXT)
	UiKit.style_button(_close, TEXT_FONT_SIZE)
	_close.text = UiText.BAG_CLOSE
	_close.pressed.connect(hide)


func bind(hunt_log: HuntLog, party: Array[Hench]) -> void:
	_log = hunt_log
	_party = party


func open() -> void:
	visible = true
	refresh()


func _process(delta: float) -> void:
	if not visible or _log == null:
		return
	_refresh_left -= delta
	if _refresh_left <= 0.0:
		refresh()


func refresh() -> void:
	_refresh_left = REFRESH_SECONDS
	_totals.text = UiText.HUNT_TOTALS % [_log.kills(), _log.cores, _log.shining_cores]
	var advantage := _log.manual_advantage()
	_rates.text = UiText.HUNT_RATES % [
		_count_text(_log.kills_per_hour(false)),
		_count_text(_log.kills_per_hour(true)),
		UiText.HUNT_UNKNOWN if is_nan(advantage) else UiText.HUNT_ADVANTAGE % roundi(advantage * 100.0),
		_count_text(_log.daily_kills_estimate()),
	]
	var rows := PackedStringArray()
	for i in _party.size():
		var hench := _party[i]
		if not is_instance_valid(hench):
			continue
		var s := hench.stats
		var row := UiText.DEBUG_PARTY_ROW % [i + 1, hench.display_name, ceili(hench.hp), roundi(s.max_hp), roundi(s.attack), s.attack_interval]
		if s.heal > 0.0:
			row += UiText.DEBUG_PARTY_HEAL % roundi(s.heal)
		rows.append(row)
	_party_rows.text = "\n".join(rows)


## 파티 전투 값 글자(실행 검사용).
func party_text() -> String:
	return _party_rows.text


static func _count_text(value: float) -> String:
	return UiText.HUNT_UNKNOWN if value < 0.0 else str(roundi(value))

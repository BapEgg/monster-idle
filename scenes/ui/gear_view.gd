class_name GearView
extends VBoxContainer
## 직업 창 캐릭터 탭의 오른쪽(사용자 요청 2026-10-03: 왼쪽 능력치 + 오른쪽 장비, 디아블로 · 믹스마스터 장비창처럼).
## 위 = 장비 인형 7칸(GearDoll) + 아이템 정보(고른 장비: 이름(등급 색) · 등급 · 품질 · 부위 · 레벨, 주 능력치, 옵션, 못 끼는 까닭,
##      낀 것과 비교(▲ 초록 · ▼ 빨강) · 장착/해제 · 잠금. 아무것도 안 골랐으면 낀 장비로 오른 능력치 합계).
## 아래 = 아이템 칸(낀 장비는 빼고, 한 칸에 하나) + 부위 거르기 · 정렬(등급순 · 레벨순 · 부위순 · 최근순).
## 조작(휴대폰 터치 · PC 마우스 같음): 칸을 누르면 고르고, 같은 칸을 빨리 두 번 누르면 바로 장착(낀 칸이면 해제).
## 인형 칸을 누르면 아이템 칸을 그 부위로 거르고, 낀 칸이면 그 장비를 고른다. 자리 · 크기는 gear_view.tscn에서.

const TITLE_FONT_SIZE := 18
const NAME_FONT_SIZE := 22
const TEXT_FONT_SIZE := 16
const LINE_FONT_SIZE := 16
const BUTTON_FONT_SIZE := 16

var _gear: GearBag
var _job: JobState
var _progress: PlayerProgress
var _selected: GearItem
var _filter := ""  # 부위(""= 모든 부위)
var _last_tap_uid := -1
var _last_tap_time := -1.0
var _refresh_queued := false

@onready var _title: Label = %GearTitle
@onready var _doll: GearDoll = %Doll
@onready var _detail: PanelContainer = %Detail
@onready var _item_name: Label = %ItemName
@onready var _item_kind: Label = %ItemKind
@onready var _lines: VBoxContainer = %Lines
@onready var _equip: Button = %Equip
@onready var _lock: Button = %Lock
@onready var _items_title: Label = %ItemsTitle
@onready var _count: Label = %Count
@onready var _filter_box: OptionButton = %Filter
@onready var _sort: OptionButton = %Sort
@onready var _scroll: ScrollContainer = %Scroll
@onready var _grid: GridContainer = %Grid


func _ready() -> void:
	for label: Label in [_title, _items_title]:
		UiKit.style_label(label, TITLE_FONT_SIZE, Palette.TEXT)
		label.add_theme_font_override("font", UiKit.bold_font())
	_title.text = UiText.GEAR_TITLE
	_items_title.text = UiText.GEAR_ITEMS_TITLE
	UiKit.style_caption(_count, TEXT_FONT_SIZE)
	var box := StyleBoxFlat.new()
	box.bg_color = Palette.JOB_SECTION_BG
	box.set_corner_radius_all(UiKit.PANEL_CORNER)
	box.set_content_margin_all(12)
	_detail.add_theme_stylebox_override("panel", box)
	UiKit.style_label(_item_name, NAME_FONT_SIZE, Palette.TEXT)
	_item_name.add_theme_font_override("font", UiKit.bold_font())
	UiKit.style_caption(_item_kind, TEXT_FONT_SIZE)
	for button: BaseButton in [_equip, _lock, _filter_box, _sort]:
		UiKit.style_button(button, BUTTON_FONT_SIZE)
	_filter_box.add_item(UiText.GEAR_FILTER_ALL)
	for kind in GearDb.kinds():
		_filter_box.add_item(UiText.GEAR_SLOT_NAMES.get(kind, kind))
	for sort_name: String in UiText.GEAR_SORTS:
		_sort.add_item(sort_name)
	for option: OptionButton in [_filter_box, _sort]:
		option.get_popup().add_theme_font_size_override("font_size", BUTTON_FONT_SIZE)
	_filter_box.item_selected.connect(func(index: int) -> void:
		_filter = GearDb.kinds()[index - 1] if index > 0 else ""
		_queue_refresh())
	_sort.item_selected.connect(func(_index: int) -> void: _queue_refresh())
	_equip.pressed.connect(_toggle_equip)
	_lock.pressed.connect(func() -> void:
		if _selected != null:
			_gear.toggle_lock(_selected))
	_doll.slot_pressed.connect(_on_slot_pressed)
	_scroll.resized.connect(_fit_columns)


func bind(gear: GearBag, job: JobState, progress: PlayerProgress) -> void:
	_gear = gear
	_job = job
	_progress = progress
	_gear.changed.connect(_queue_refresh)


## 바뀐 것을 한 번에 다시 그린다(누른 버튼을 그 신호 안에서 지우지 않게 다음 프레임에).
func _queue_refresh() -> void:
	if _refresh_queued or not is_visible_in_tree():
		return
	_refresh_queued = true
	refresh.call_deferred()


func refresh() -> void:
	_refresh_queued = false
	if _gear == null:
		return
	if _selected != null and _gear.find(_selected.uid) != _selected:
		_selected = null
	var level := _progress.level
	var job_id := _job.job_id
	var worn := {}
	for slot: String in GearRules.SLOTS:
		var item := _gear.in_slot(slot)
		if item != null:
			worn[slot] = item
	_doll.job_id = job_id
	_doll.items = worn
	_doll.selected_slot = _gear.slot_of(_selected) if _selected != null else ""
	var list: Array[GearItem] = []
	for item in _gear.inventory():
		if _filter == "" or item.kind == _filter:
			list.append(item)
	list = GearRules.sorted(list, _sort.selected as GearRules.Sort)
	for child in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	for item in list:
		var card := GearCard.create(item)
		card.problem = GearRules.problem(item, job_id, level)
		card.upgrade = GearRules.is_upgrade(item, _gear.worn_of_kind(item.kind), GearRules.slots_for(item.kind).size())
		card.selected = item == _selected
		card.pressed.connect(_on_card_pressed.bind(item))
		_grid.add_child(card)
	_count.text = UiText.GEAR_COUNT % _gear.inventory().size()
	_fit_columns()
	_show_detail()


## 고른 것만 바뀌었을 때: 칸을 다시 만들지 않고 표시만(두 번 누르기가 같은 칸에 들어가게).
func _show_selection() -> void:
	for card: GearCard in _grid.get_children():
		card.selected = card.item == _selected
	_doll.selected_slot = _gear.slot_of(_selected) if _selected != null else ""
	_show_detail()


func _fit_columns() -> void:
	var gap := float(_grid.get_theme_constant("h_separation"))
	_grid.columns = maxi(int((_scroll.size.x - 12.0 + gap) / (GearCard.SIZE.x + gap)), 1)


# ─── 누르기 ───────────────────────────────────────

func _on_card_pressed(item: GearItem) -> void:
	_tap(item)


## 인형 칸을 누름: 아이템 칸을 그 부위로 거르고(바꿔 낄 것을 바로 보게), 낀 칸이면 그 장비를 고른다.
func _on_slot_pressed(slot: String) -> void:
	var kind := GearRules.slot_kind(slot)
	if _filter != kind:
		_filter = kind
		_filter_box.select(GearDb.kinds().find(kind) + 1)
		_queue_refresh()
	var item := _gear.in_slot(slot)
	if item != null:
		_tap(item)
	else:
		_selected = null
		_show_selection()


## 고르기 · 두 번 누르면 장착(낀 것이면 해제).
func _tap(item: GearItem) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var double := item.uid == _last_tap_uid and now - _last_tap_time <= GameConfig.DOUBLE_TAP_SECONDS
	_last_tap_uid = item.uid
	_last_tap_time = now
	_selected = item
	if double:
		_last_tap_uid = -1
		_toggle_equip()
		return
	_show_selection()


## 고른 장비를 낀다(낀 것이면 뺀다). 가방이 바뀌면 다음 프레임에 다시 그린다.
func _toggle_equip() -> void:
	if _selected == null:
		return
	var slot := _gear.slot_of(_selected)
	if slot != "":
		_gear.unequip(slot)
	else:
		_gear.equip(_selected, _job.job_id, _progress.level)


# ─── 아이템 정보 ───────────────────────────────────

func _show_detail() -> void:
	for child in _lines.get_children():
		_lines.remove_child(child)
		child.queue_free()
	var item := _selected
	_equip.visible = item != null
	_lock.visible = item != null
	if item == null:
		_item_name.text = UiText.GEAR_TOTAL_TITLE
		_item_name.add_theme_color_override("font_color", Palette.TEXT)
		_item_kind.text = ""
		_item_kind.visible = false
		var total := _gear.bonus()
		if total.is_empty():
			_add_line(UiText.GEAR_TOTAL_NONE, Palette.TEXT_LABEL)
		for stat in GearRules.stat_order():
			if total.has(stat):
				_add_line("%s %s" % [GearRules.stat_name(stat), GearRules.value_text(stat, float(total[stat]))], Palette.TEXT)
		return
	var grade_color: Color = Palette.GEAR_GRADE_COLORS[item.grade]
	_item_name.text = item.base_name
	_item_name.add_theme_color_override("font_color", grade_color)
	_item_kind.visible = true
	_item_kind.text = UiText.GEAR_KIND_LINE % [UiText.GEAR_GRADES[item.grade], UiText.GEAR_QUALITIES[item.quality], UiText.GEAR_SLOT_NAMES.get(item.kind, item.kind), item.level]
	if item.job_id != "":
		_item_kind.text += " · " + UiText.GEAR_JOB_ONLY % JobDb.get_job(item.job_id).name
	var worn_slot := _gear.slot_of(item)
	if worn_slot != "":
		_item_kind.text += " · " + UiText.GEAR_WORN_TAG
	_add_line("%s %s" % [GearRules.stat_name(item.main_stat), GearRules.value_text(item.main_stat, item.main_value)], Palette.TEXT, true)
	for option in item.options:
		var stat := str(option["stat"])
		_add_line("+ %s %s" % [GearRules.stat_name(stat), GearRules.value_text(stat, float(option["value"])).trim_prefix("+")], Palette.GEAR_OPTION)
	var why := GearRules.problem(item, _job.job_id, _progress.level)
	if why == GearRules.Problem.WRONG_JOB:
		_add_line(UiText.GEAR_PROBLEMS[why] % JobDb.get_job(item.job_id).name, Palette.GEAR_DOWN)
	elif why == GearRules.Problem.LEVEL:
		_add_line(UiText.GEAR_PROBLEMS[why] % item.level, Palette.GEAR_DOWN)
	elif worn_slot == "":
		_show_compare(item)
	_equip.text = UiText.BTN_UNEQUIP if worn_slot != "" else UiText.BTN_EQUIP
	_equip.disabled = worn_slot == "" and why != GearRules.Problem.OK
	if worn_slot == "" and why == GearRules.Problem.OK:
		UiKit.accent_button(_equip)
	else:
		_plain(_equip)
	_lock.text = UiText.BTN_UNLOCK if item.locked else UiText.BTN_LOCK


## 끼면 바뀌는 것: 바뀔 칸의 장비와 비교해 ▲ 초록 · ▼ 빨강. 빈 칸이 있으면 모두 오르므로 한 줄("빈 칸에 낌")만.
func _show_compare(item: GearItem) -> void:
	var slots := GearRules.slots_for(item.kind)
	var replaced: GearItem = null
	for slot in slots:
		replaced = _gear.in_slot(slot)
		if replaced == null:
			break
	if replaced == null:
		_add_line(UiText.GEAR_COMPARE_EMPTY, Palette.GEAR_UP)
		return
	_add_line(UiText.GEAR_COMPARE % replaced.base_name, Palette.TEXT_LABEL)
	var change := GearRules.diff(item.bonus(), replaced.bonus())
	for stat: String in change:
		var up := float(change[stat]) > 0.0
		_add_line("%s %s %s" % [GearRules.stat_name(stat), GearRules.value_text(stat, float(change[stat])), "▲" if up else "▼"], Palette.GEAR_UP if up else Palette.GEAR_DOWN)


## 강조색을 걷어 보통 버튼으로.
func _plain(button: Button) -> void:
	for state: String in ["normal", "hover", "pressed", "focus"]:
		button.remove_theme_stylebox_override(state)
	button.remove_theme_color_override("font_color")
	button.remove_theme_color_override("font_hover_color")
	button.remove_theme_font_override("font")


func _add_line(text: String, color: Color, bold := false) -> void:
	var label := Label.new()
	UiKit.style_label(label, LINE_FONT_SIZE, color)
	if bold:
		label.add_theme_font_override("font", UiKit.bold_font())
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lines.add_child(label)


# ─── 실행 검사용 ──────────────────────────────────

## 아이템 칸(없으면 null).
func card_for(item: GearItem) -> GearCard:
	for card: GearCard in _grid.get_children():
		if card.item == item:
			return card
	return null


## 아이템 칸에 보이는 장비들(보이는 차례).
func shown_items() -> Array[GearItem]:
	var list: Array[GearItem] = []
	for card: GearCard in _grid.get_children():
		list.append(card.item)
	return list


func doll() -> GearDoll:
	return _doll


func selected_item() -> GearItem:
	return _selected


## 아이템 정보의 글자들: [이름, 종류 줄, 줄들…].
func detail_texts() -> PackedStringArray:
	var texts := PackedStringArray([_item_name.text, _item_kind.text])
	for label: Label in _lines.get_children():
		texts.append(label.text)
	return texts


## 정렬을 바꾼다(실행 검사용 — 화면에서는 정렬 버튼으로).
func set_sort(by: GearRules.Sort) -> void:
	_sort.select(by)
	refresh()

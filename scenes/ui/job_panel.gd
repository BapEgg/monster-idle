class_name JobPanel
extends PanelContainer
## 직업 창(기획서 3장 스킬 시스템, 직업 1차): 오른쪽 위 "직업" 버튼으로 열고 닫는다.
## 왼쪽 = 주인공(직업 색 도형) · 직업 이름 · 역할 · 무기 · 인물 / 능력치 9종(코어와 같은 능력치, 패시브 포함) + 전투 값 한 줄 / 직업 바꾸기(개발용).
## 오른쪽 = 액티브 · 패시브 · 궁극기 한 섹터씩 위아래로(사용자 결정 2026-10-03). 섹터마다 왼쪽에 장착 칸(JobSlot), 오른쪽에 그 종류의 스킬 목록
## (JobSkillTile, 가로로 넘겨 본다 — 업데이트로 스킬 · 궁극기가 늘어도 그대로 들어간다).
## 스킬을 누르면 고르고(흰 테두리 + 체크), 아래 행동 줄에서 배우기 · 장착 · 해제 · 레벨 올리기. 고른 스킬을 한 번 더 누르거나 "미리보기"를 누르면
## 스킬 상세 창(보기 전용: 모션 미리보기 · 설명 · 계수). 스킬을 고른 채 장착 칸을 누르면 그 칸에 장착한다. 칸이 다 찼으면 "장착" 뒤 바꿀 칸을 누른다.
## 위치 · 크기는 job_panel.tscn에서 에디터로 정한다.

const TITLE_FONT_SIZE := 24
const TEXT_FONT_SIZE := 18
const NAME_FONT_SIZE := 26
const SMALL_FONT_SIZE := 15
const STAT_FONT_SIZE := 17
const STAT_NUMBER_WIDTH := 52.0
const SWITCH_FONT_SIZE := 15
const SECTION_TITLE_FONT_SIZE := 18
const SECTION_PAD := 10.0
const ACTION_NAME_FONT_SIZE := 20
const ACTION_FONT_SIZE := 16
const ACTION_PAD := 12.0

var _job: JobState
var _progress: PlayerProgress
var _window: SkillWindow
var _confirm: ConfirmBox
var _selected := ""  # 고른 직업 스킬(아래 행동 줄)
var _picking := false  # 칸이 다 차서 바꿀 칸을 고르는 중
var _shown_skill := ""  # 스킬 상세 창에 띄운 직업 스킬(바뀌면 창도 다시 그린다)
var _refresh_queued := false
var _main_action := Callable()  # 행동 줄 가운데 버튼이 할 일(배우기 · 장착 · 해제)

@onready var _title: Label = %Title
@onready var _points: Label = %Points
@onready var _close: Button = %Close
@onready var _portrait: JobPortrait = %Portrait
@onready var _job_name: Label = %JobName
@onready var _kind: Label = %Kind
@onready var _person: Label = %Person
@onready var _stats: GridContainer = %Stats
@onready var _combat: Label = %Combat
@onready var _mods: Label = %Mods
@onready var _switch_title: Label = %SwitchTitle
@onready var _switch: HBoxContainer = %Switch
@onready var _divider: VSeparator = %Divider
@onready var _action_bar: PanelContainer = %ActionBar
@onready var _icon: TextureRect = %Icon
@onready var _sel_name: Label = %SelName
@onready var _status: Label = %Status
@onready var _buttons: HBoxContainer = %Buttons
@onready var _preview: Button = %Preview
@onready var _main: Button = %Main
@onready var _level_up: Button = %LevelUp
## 종류(active · passive · ultimate) → 섹터
@onready var _sections := {"active": %ActiveSection as PanelContainer, "passive": %PassiveSection as PanelContainer, "ultimate": %UltimateSection as PanelContainer}


func _ready() -> void:
	add_theme_stylebox_override("panel", UiKit.panel_box())
	UiKit.style_label(_title, TITLE_FONT_SIZE, Palette.TEXT)
	_title.add_theme_font_override("font", UiKit.bold_font())
	_title.text = UiText.JOB_TITLE
	UiKit.style_label(_points, TEXT_FONT_SIZE, Palette.CORE_SHINE)
	UiKit.style_button(_close, TEXT_FONT_SIZE)
	_close.text = UiText.JOB_CLOSE
	_close.pressed.connect(close)
	UiKit.style_label(_job_name, NAME_FONT_SIZE, Palette.TEXT)
	_job_name.add_theme_font_override("font", UiKit.bold_font())
	UiKit.style_caption(_kind, TEXT_FONT_SIZE)
	UiKit.style_caption(_person, SMALL_FONT_SIZE)
	UiKit.style_caption(_combat, SMALL_FONT_SIZE)
	UiKit.style_label(_mods, SMALL_FONT_SIZE, Palette.STAT_BOOSTED)
	UiKit.style_caption(_switch_title, SMALL_FONT_SIZE)
	_switch_title.text = UiText.JOB_SWITCH
	for type: String in _sections:
		var section: PanelContainer = _sections[type]
		section.add_theme_stylebox_override("panel", _box(Palette.JOB_SECTION_BG, SECTION_PAD))
		var title := _section_part(type, "Title") as Label
		UiKit.style_label(title, SECTION_TITLE_FONT_SIZE, Palette.TEXT)
		title.add_theme_font_override("font", UiKit.bold_font())
		title.text = UiText.JOB_SECTION_TITLES[type]
		UiKit.style_caption(_section_part(type, "Info") as Label, SMALL_FONT_SIZE)
	var line := StyleBoxLine.new()
	line.vertical = true
	line.color = Palette.PANEL_DIVIDER
	line.thickness = 1
	_divider.add_theme_stylebox_override("separator", line)
	_action_bar.add_theme_stylebox_override("panel", _box(Palette.JOB_ACTION_BG, ACTION_PAD))
	UiKit.style_label(_sel_name, ACTION_NAME_FONT_SIZE, Palette.TEXT)
	_sel_name.add_theme_font_override("font", UiKit.bold_font())
	UiKit.style_caption(_status, SMALL_FONT_SIZE)
	for button: Button in [_preview, _main, _level_up]:
		UiKit.style_button(button, ACTION_FONT_SIZE)
	_preview.text = UiText.JOB_ACT_PREVIEW
	_preview.pressed.connect(func() -> void: show_skill(_selected))
	_main.pressed.connect(func() -> void:
		if _main_action.is_valid():
			_main_action.call())
	_level_up.pressed.connect(func() -> void: _job.level_up(_selected, _progress.level))
	_build_stat_table()


static func _box(color: Color, pad: float) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = Palette.PANEL_DIVIDER
	box.set_border_width_all(1)
	box.set_corner_radius_all(UiKit.PANEL_CORNER)
	box.set_content_margin_all(pad)
	return box


## 직업 상태 · 주인공 레벨 · 스킬 상세 창 · 확인 창을 잇는다(HUD).
func bind(job: JobState, progress: PlayerProgress, window: SkillWindow, confirm: ConfirmBox) -> void:
	_job = job
	_progress = progress
	_window = window
	_confirm = confirm
	_job.changed.connect(_queue_refresh)
	_progress.changed.connect(_queue_refresh)
	_window.visibility_changed.connect(func() -> void:
		if not _window.visible:
			_shown_skill = "")
	_build_switch()


func open() -> void:
	visible = true
	refresh()


func close() -> void:
	visible = false
	_picking = false
	if _shown_skill != "":
		_window.hide()


## 바뀐 것을 한 번에 다시 그린다(버튼을 누르는 도중에 그 버튼을 지우지 않게 다음 프레임에).
func _queue_refresh() -> void:
	if _refresh_queued or not visible:
		return
	_refresh_queued = true
	refresh.call_deferred()


func refresh() -> void:
	_refresh_queued = false
	if _job == null:
		return
	var job := _job.job()
	var level := _progress.level
	var mods := _job.mods(level)
	var chosen := JobDb.get_skill(_selected)
	if chosen == null or chosen.job_id != job.id:
		_selected = ""
		_picking = false
	_points.text = UiText.JOB_POINTS % _job.points(level)
	_portrait.body_color = job.color
	_job_name.text = job.name
	_kind.text = UiText.JOB_KIND % [UiText.ROLE_NAMES.get(job.role, job.role), job.weapon]
	_person.text = job.person
	_show_stats(JobRules.player_sheet(job.id, level, mods), JobRules.player_stats(job.id, level, mods), mods)
	var parts := PackedStringArray()
	for key: String in mods:
		parts.append(UiText.JOB_MOD_NAMES.get(key, key + " %d%%") % roundi(float(mods[key]) * 100.0))
	_mods.text = UiText.JOB_MODS_LINE % UiText.LIST_SEPARATOR.join(parts) if not parts.is_empty() else ""
	_mods.visible = not parts.is_empty()
	for button: Button in _switch.get_children():
		button.disabled = button.name == job.id
	for type: String in JobDb.TYPES:
		_build_section(job, type, level)
	_show_action_bar(level)
	if _shown_skill != "" and _window.visible:
		show_skill(_shown_skill)


# ─── 왼쪽: 능력치 ─────────────────────────────────

## 능력치 표: HP · MP 다음 9종(코어 정보창과 같은 이름 · 순서). 칸마다 이름(회색) + 숫자(흰색 굵게, 패시브로 오른 값은 초록).
func _build_stat_table() -> void:
	var ids := PackedStringArray(["hp", "mp"])
	ids.append_array(SuffixDb.ids())
	for stat in ids:
		var cell := HBoxContainer.new()
		cell.name = stat
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var caption := Label.new()
		UiKit.style_caption(caption, STAT_FONT_SIZE)
		caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		match stat:
			"hp":
				caption.text = UiText.JOB_SHEET_HP
			"mp":
				caption.text = UiText.JOB_SHEET_MP
			_:
				caption.text = SuffixDb.stat_name(stat)
		var number := Label.new()
		number.name = "Value"
		UiKit.style_number(number, STAT_FONT_SIZE)
		number.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		number.custom_minimum_size.x = STAT_NUMBER_WIDTH
		cell.add_child(caption)
		cell.add_child(number)
		_stats.add_child(cell)


func _show_stats(sheet: Dictionary, stats: UnitStats, mods: Dictionary) -> void:
	var boosted := {}
	for key: String in JobRules.MOD_STATS:
		if float(mods.get(key, 0.0)) > 0.0:
			boosted[JobRules.MOD_STATS[key]] = true
	if boosted.has("tough"):
		boosted["hp"] = true
	if boosted.has("abundant"):
		boosted["mp"] = true
	for cell: Control in _stats.get_children():
		var value := cell.get_node("Value") as Label
		value.text = str(int(sheet.get(cell.name, 0)))
		value.add_theme_color_override("font_color", Palette.STAT_BOOSTED if boosted.has(str(cell.name)) else Palette.TEXT)
	_combat.text = UiText.JOB_COMBAT_LINE % [roundi(stats.attack), SkillSheet.seconds(snappedf(stats.attack_interval, 0.01)), roundi(stats.attack_range)]


## 그 능력치의 숫자 글자(실행 검사용, hp · mp · 9종 id).
func stat_text(stat: String) -> String:
	var cell := _stats.get_node_or_null(stat)
	return (cell.get_node("Value") as Label).text if cell != null else ""


func _build_switch() -> void:
	for id in JobDb.ids():
		var job := JobDb.get_job(id)
		var button := Button.new()
		button.name = id
		button.text = job.name
		button.custom_minimum_size.y = 40.0
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UiKit.style_button(button, SWITCH_FONT_SIZE)
		button.pressed.connect(func() -> void:
			_confirm.ask(UiText.JOB_SWITCH_ASK % job.name, func() -> void: _job.change_job(id, _progress.level)))
		_switch.add_child(button)


# ─── 오른쪽: 섹터 ─────────────────────────────────

func _section_part(type: String, part: String) -> Control:
	return (_sections[type] as PanelContainer).find_child(part, true, false) as Control


static func _clear(box: Control) -> void:
	for child in box.get_children():
		box.remove_child(child)
		child.queue_free()


## 섹터 하나: 제목 옆에 장착 수 / 열린 칸 수, 왼쪽에 장착 칸, 오른쪽에 그 종류의 스킬마다 네모 칸.
func _build_section(job: JobDb.Job, type: String, level: int) -> void:
	var slots := _slots_of(type)
	var open_slots := _open_slot_count(type, level)
	var used := 0
	for i in open_slots:
		if slots[i] != "":
			used += 1
	(_section_part(type, "Info") as Label).text = UiText.JOB_SECTION_INFO[type] % [used, open_slots]
	var chosen := JobDb.get_skill(_selected)
	var picks_here := _picking and chosen != null and chosen.type == type
	var slot_box := _section_part(type, "Slots")
	_clear(slot_box)
	for i in slots.size():
		var locked := 0 if i < open_slots else int(GameConfig.JOB_PASSIVE_SLOT_LEVELS[i])
		var caption := UiText.JOB_SLOT_ULTIMATE if type == "ultimate" else UiText.JOB_SLOT_CAPTION % (i + 1)
		if locked > 0:
			caption = UiText.JOB_SLOT_LOCKED % locked
		var card := JobSlot.create(JobDb.get_skill(slots[i]) if locked == 0 else null, caption, locked)
		card.name = "Slot%d" % i
		card.selected = _selected != "" and slots[i] == _selected
		card.picking = picks_here and locked == 0
		card.pressed.connect(_on_slot_pressed.bind(type, i))
		slot_box.add_child(card)
	var tiles := _section_part(type, "Tiles")
	_clear(tiles)
	for skill in job.skills_of(type):
		var state := JobSkillTile.State.LEARNED
		if _job.skill_level(skill.id) <= 0:
			state = JobSkillTile.State.LEARNABLE if JobRules.is_unlocked(skill, level) else JobSkillTile.State.LOCKED
		var slot := slots.find(skill.id)
		var badge := ""
		if slot >= 0:
			badge = UiText.JOB_EQUIPPED_BADGE if type == "ultimate" else str(slot + 1)
		var tile := JobSkillTile.create(skill, state, _job.skill_level(skill.id), badge, skill.id == _selected)
		tile.pressed.connect(_on_tile_pressed.bind(skill.id))
		tiles.add_child(tile)


## 그 종류의 장착 칸들(패시브는 닫힌 칸까지). 궁극기 칸은 하나.
func _slots_of(type: String) -> Array[String]:
	match type:
		"active":
			return _job.actives
		"passive":
			return _job.passives
	var ultimate: Array[String] = [_job.ultimate]
	return ultimate


func _open_slot_count(type: String, level: int) -> int:
	match type:
		"active":
			return _job.actives.size()
		"passive":
			return JobRules.passive_slot_count(level)
	return 1


## 스킬 칸을 누름: 고른다. 이미 고른 칸이면 미리보기.
func _on_tile_pressed(id: String) -> void:
	if id == _selected:
		show_skill(id)
		return
	_selected = id
	_picking = false
	_queue_refresh()


## 장착 칸을 누름: 같은 종류의 배운 스킬을 골랐으면 그 칸에 장착(바꾸기). 아니면 그 칸의 스킬을 고른다.
func _on_slot_pressed(type: String, index: int) -> void:
	var level := _progress.level
	if index >= _open_slot_count(type, level):
		return
	var chosen := JobDb.get_skill(_selected)
	var slots := _slots_of(type)
	if chosen != null and chosen.type == type and _job.skill_level(_selected) > 0 and slots[index] != _selected:
		_picking = false
		_job.equip(_selected, index, level)
		return
	if slots[index] != "":
		_selected = slots[index]
		_picking = false
		_queue_refresh()


# ─── 아래: 행동 줄 ────────────────────────────────

## 고른 스킬의 그림 · 이름 · 상태 줄과 버튼(미리보기 · 배우기/장착/해제 · 레벨 올리기). 아무것도 안 골랐으면 안내 한 줄.
func _show_action_bar(level: int) -> void:
	var skill := JobDb.get_skill(_selected)
	_icon.visible = skill != null
	_sel_name.visible = skill != null
	_buttons.visible = skill != null
	_status.add_theme_color_override("font_color", Palette.TEXT_LABEL)
	_main_action = Callable()
	if skill == null:
		_status.text = UiText.JOB_HINT
		return
	_icon.texture = JobDb.icon(skill)
	_sel_name.text = skill.name
	var type_name: String = UiText.JOB_TYPE_NAMES.get(skill.type, skill.type)
	var skill_level := _job.skill_level(skill.id)
	_main.visible = true
	_main.disabled = false
	for state: String in ["normal", "hover", "pressed", "focus"]:  # 강조(UiKit.accent_button)를 걷는다
		_main.remove_theme_stylebox_override(state)
	for color: String in ["font_color", "font_hover_color"]:
		_main.remove_theme_color_override(color)
	_main.remove_theme_font_override("font")
	_level_up.visible = skill_level > 0
	if skill_level <= 0:
		if _job.can_learn(skill.id, level):
			_status.text = UiText.JOB_STATUS_LEARNABLE % [type_name, skill.unlock]
			_status.add_theme_color_override("font_color", Palette.JOB_LEVEL_READY_TEXT)
			_main.text = UiText.JOB_ACT_LEARN
			UiKit.accent_button(_main)
			_main_action = func() -> void: _job.learn(skill.id, _progress.level)
		else:
			_status.text = UiText.JOB_STATUS_LOCKED % [type_name, skill.unlock]
			_status.add_theme_color_override("font_color", Palette.JOB_LEVEL_SHORT)
			_main.text = UiText.JOB_ACT_LOCKED % skill.unlock
			_main.disabled = true
		return
	var slot := _slots_of(skill.type).find(skill.id)
	if slot >= 0:
		var where := UiText.JOB_SLOT_ULTIMATE if skill.type == "ultimate" else UiText.JOB_SLOT_CAPTION % (slot + 1)
		_status.text = UiText.JOB_STATUS_EQUIPPED % [type_name, skill_level, GameConfig.JOB_SKILL_MAX_LEVEL, where]
		_main.text = UiText.JOB_ACT_UNEQUIP
		_main_action = func() -> void: _job.unequip(skill.id)
	else:
		_status.text = UiText.JOB_STATUS_FREE % [type_name, skill_level, GameConfig.JOB_SKILL_MAX_LEVEL]
		_main.text = UiText.JOB_ACT_EQUIP
		UiKit.accent_button(_main)
		_main_action = _equip_selected
	if _picking:
		_status.text = UiText.JOB_PICK_SLOT
		_status.add_theme_color_override("font_color", Palette.JOB_PICK_TEXT)
	if skill_level >= GameConfig.JOB_SKILL_MAX_LEVEL:
		_level_up.text = UiText.JOB_ACT_MAX
		_level_up.disabled = true
	elif _job.points(level) <= 0:
		_level_up.text = UiText.JOB_ACT_NO_POINTS
		_level_up.disabled = true
	else:
		_level_up.text = UiText.JOB_ACT_LEVEL
		_level_up.disabled = false


## "장착": 빈 칸이 있으면 거기에, 다 찼으면 바꿀 칸을 고르게 한다(칸 테두리가 깜빡임).
func _equip_selected() -> void:
	var skill := JobDb.get_skill(_selected)
	if skill == null:
		return
	var level := _progress.level
	var empty := _job.empty_slot(skill.type, level)
	if empty >= 0:
		_job.equip(skill.id, empty, level)
		return
	_picking = true
	_queue_refresh()


## 그 직업 스킬의 상세 창(보기 전용: 모션 미리보기 · 설명 · 계수).
func show_skill(id: String) -> void:
	var skill := JobDb.get_skill(id)
	if skill == null:
		return
	var level := _progress.level
	var mods := _job.mods(level)
	var sheet := SkillSheet.job_skill(skill, _job.skill_level(id), JobRules.player_stats(_job.job_id, level, mods), mods, level)
	_shown_skill = id
	_window.open(sheet, _job.job().color)


# ─── 실행 검사용 ──────────────────────────────────

## 그 스킬의 네모 칸. 없으면 null.
func skill_tile(id: String) -> JobSkillTile:
	var skill := JobDb.get_skill(id)
	if skill == null:
		return null
	return _section_part(skill.type, "Tiles").get_node_or_null(id) as JobSkillTile


## 그 종류의 장착 칸(index번째). 없으면 null.
func slot_card(type: String, index: int) -> JobSlot:
	return _section_part(type, "Slots").get_node_or_null("Slot%d" % index) as JobSlot


## 섹터 제목 옆 장착 수 글자.
func section_info(type: String) -> String:
	return (_section_part(type, "Info") as Label).text


## 섹터의 스킬 목록 가로 스크롤.
func section_scroll(type: String) -> ScrollContainer:
	return _section_part(type, "Scroll") as ScrollContainer


## 고른 스킬 id("" = 없음).
func selected_skill() -> String:
	return _selected


func is_picking() -> bool:
	return _picking


## 행동 줄: 상태 글 · 버튼들(보이는 것만, 글자).
func status_text() -> String:
	return _status.text


func action_button(which: String) -> Button:
	match which:
		"preview":
			return _preview
		"main":
			return _main
		"level":
			return _level_up
	return null


## 직업 바꾸기 버튼.
func switch_button(id: String) -> Button:
	return _switch.get_node_or_null(id) as Button

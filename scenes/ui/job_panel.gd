class_name JobPanel
extends PanelContainer
## 직업 창(기획서 3장 스킬 시스템, 직업 1차): 오른쪽 위 "직업" 버튼으로 열고 닫는다.
## 왼쪽 = 주인공(직업 색 도형) · 직업 이름 · 역할 · 무기 · 인물 / 지금 능력치(패시브 포함) / 직업 바꾸기(개발용).
## 오른쪽 = 장착 칸(액티브 3 · 패시브(Lv 10 · 30에 열림) · 궁극기) + 스킬 목록(액티브 5 · 패시브 2 · 궁극기 1).
## 스킬을 누르면 스킬 상세 창(모션 미리보기 · 설명 · 계수, 사용자 결정 2026-10-03)이 뜨고, 그 아래 버튼으로 장착 · 해제 · 레벨 올리기.
## 위치 · 크기는 job_panel.tscn에서 에디터로 정한다.

const TITLE_FONT_SIZE := 24
const TEXT_FONT_SIZE := 18
const NAME_FONT_SIZE := 26
const SMALL_FONT_SIZE := 15
const STAT_FONT_SIZE := 17
const SWITCH_FONT_SIZE := 15
const CHIP_HEIGHT := 50.0
const LOCKED_ALPHA := 0.5

var _job: JobState
var _progress: PlayerProgress
var _window: SkillWindow
var _confirm: ConfirmBox
var _shown_skill := ""  # 스킬 상세 창에 띄운 직업 스킬(바뀌면 창도 다시 그린다)
var _refresh_queued := false

@onready var _title: Label = %Title
@onready var _points: Label = %Points
@onready var _close: Button = %Close
@onready var _portrait: JobPortrait = %Portrait
@onready var _job_name: Label = %JobName
@onready var _kind: Label = %Kind
@onready var _person: Label = %Person
@onready var _stats: GridContainer = %Stats
@onready var _mods: Label = %Mods
@onready var _switch_title: Label = %SwitchTitle
@onready var _switch: HBoxContainer = %Switch
@onready var _divider: VSeparator = %Divider
@onready var _equip_title: Label = %EquipTitle
@onready var _equip: GridContainer = %Equip
@onready var _list_title: Label = %ListTitle
@onready var _list: GridContainer = %List


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
	UiKit.style_label(_mods, SMALL_FONT_SIZE, Palette.STAT_BOOSTED)
	for caption: Label in [_switch_title, _equip_title, _list_title]:
		UiKit.style_caption(caption, SMALL_FONT_SIZE)
	_switch_title.text = UiText.JOB_SWITCH
	_equip_title.text = UiText.JOB_EQUIP_TITLE
	_list_title.text = UiText.JOB_LIST_TITLE
	var line := StyleBoxLine.new()
	line.vertical = true
	line.color = Palette.PANEL_DIVIDER
	line.thickness = 1
	_divider.add_theme_stylebox_override("separator", line)


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
	_points.text = UiText.JOB_POINTS % _job.points(level)
	_portrait.body_color = job.color
	_job_name.text = job.name
	_kind.text = UiText.JOB_KIND % [UiText.ROLE_NAMES.get(job.role, job.role), job.weapon]
	_person.text = job.person
	_show_stats(JobRules.player_stats(job.id, level, mods))
	var parts := PackedStringArray()
	for key: String in mods:
		parts.append(UiText.JOB_MOD_NAMES.get(key, key + " %d%%") % roundi(float(mods[key]) * 100.0))
	_mods.text = UiText.JOB_MODS_LINE % UiText.LIST_SEPARATOR.join(parts) if not parts.is_empty() else ""
	_mods.visible = not parts.is_empty()
	for button: Button in _switch.get_children():
		button.disabled = button.name == job.id
	_build_equip(job, level)
	_build_list(job)
	if _shown_skill != "" and _window.visible:
		show_skill(_shown_skill)


func _show_stats(stats: UnitStats) -> void:
	for child in _stats.get_children():
		_stats.remove_child(child)
		child.queue_free()
	var values := [roundi(stats.max_hp), roundi(stats.attack), SkillSheet.seconds(snappedf(stats.attack_interval, 0.01)), roundi(stats.attack_range)]
	for i in UiText.JOB_STAT_ROWS.size():
		var caption := Label.new()
		UiKit.style_caption(caption, STAT_FONT_SIZE)
		caption.text = UiText.JOB_STAT_ROWS[i][0]
		var value := Label.new()
		UiKit.style_number(value, STAT_FONT_SIZE)
		value.text = UiText.JOB_STAT_ROWS[i][1] % values[i]
		_stats.add_child(caption)
		_stats.add_child(value)


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


## 장착 칸: 액티브 1~3 / 패시브 1~2 / 궁극기. 칸을 누르면 그 스킬의 상세 창.
func _build_equip(job: JobDb.Job, level: int) -> void:
	for child in _equip.get_children():
		_equip.remove_child(child)
		child.queue_free()
	for i in _job.actives.size():
		_add_slot_chip("active", i, _job.actives[i], true, 0)
	var open_count := JobRules.passive_slot_count(level)
	for i in _job.passives.size():
		_add_slot_chip("passive", i, _job.passives[i], i < open_count, int(GameConfig.JOB_PASSIVE_SLOT_LEVELS[i]))
	var ultimate := job.skills_of("ultimate")
	_add_slot_chip("ultimate", 0, _job.ultimate, ultimate.is_empty() or level >= ultimate[0].unlock, ultimate[0].unlock if not ultimate.is_empty() else 0)


func _add_slot_chip(type: String, index: int, id: String, is_open: bool, open_level: int) -> void:
	var chip := SkillChip.new()
	chip.custom_minimum_size.y = CHIP_HEIGHT
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chip.glyph = type
	chip.caption = UiText.JOB_SLOT_CAPTIONS[type] % (index + 1) if type != "ultimate" else UiText.JOB_SLOT_CAPTIONS[type]
	chip.accent = _accent(type)
	var skill := JobDb.get_skill(id)
	if skill != null:
		chip.title = skill.name
		chip.pressed.connect(show_skill.bind(id))
	else:
		chip.title = UiText.JOB_SLOT_EMPTY if is_open else UiText.JOB_SLOT_LOCKED % open_level
		chip.modulate.a = 1.0 if is_open else LOCKED_ALPHA
	_equip.add_child(chip)


## 스킬 목록: 액티브 5 · 패시브 2 · 궁극기 1(해금 레벨 순). 못 배운 스킬은 흐리게 "Lv n에 배움".
func _build_list(job: JobDb.Job) -> void:
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	for type: String in JobDb.TYPES:
		for skill in job.skills_of(type):
			var chip := SkillChip.new()
			chip.name = skill.id
			chip.custom_minimum_size.y = CHIP_HEIGHT
			chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			chip.glyph = type
			chip.accent = _accent(type)
			chip.title = skill.name
			var learned := _job.skill_level(skill.id)
			var type_name: String = UiText.JOB_TYPE_NAMES[type]
			if learned > 0:
				chip.caption = UiText.JOB_CARD_CAPTION % [type_name, learned, GameConfig.JOB_SKILL_MAX_LEVEL]
				if _job.is_equipped(skill.id):
					chip.caption += UiText.JOB_CARD_EQUIPPED
			else:
				chip.caption = UiText.JOB_CARD_LOCKED % [type_name, skill.unlock]
				chip.modulate.a = LOCKED_ALPHA
			chip.pressed.connect(show_skill.bind(skill.id))
			_list.add_child(chip)


func _accent(type: String) -> Color:
	match type:
		"passive":
			return Palette.CHIP_PASSIVE
		"ultimate":
			return Palette.JOB_ULTIMATE
	return _job.job().color if _job != null else Palette.CHIP_PASSIVE


## 그 직업 스킬의 상세 창(모션 미리보기 · 설명 · 계수) + 아래 버튼(장착 · 해제 · 레벨 올리기).
func show_skill(id: String) -> void:
	var skill := JobDb.get_skill(id)
	if skill == null:
		return
	var level := _progress.level
	var mods := _job.mods(level)
	var sheet := SkillSheet.job_skill(skill, _job.skill_level(id), JobRules.player_stats(_job.job_id, level, mods), mods)
	_shown_skill = id
	_window.open(sheet, _job.job().color, _actions_for(skill))


func _actions_for(skill: JobDb.Skill) -> Array:
	var actions := []
	var level := _progress.level
	var id := skill.id
	var skill_level := _job.skill_level(id)
	if skill_level <= 0:
		return actions
	if _job.is_equipped(id):
		actions.append({"text": UiText.JOB_ACT_UNEQUIP, "call": func() -> void: _job.unequip(id)})
	else:
		var empty := _job.empty_slot(skill.type, level)
		var slots := 1 if skill.type == "ultimate" else (_job.actives.size() if skill.type == "active" else JobRules.passive_slot_count(level))
		if empty >= 0:
			actions.append({"text": UiText.JOB_ACT_EQUIP, "call": func() -> void: _job.equip(id, empty, level), "accent": true})
		else:
			for i in slots:
				var slot := i
				actions.append({"text": UiText.JOB_ACT_EQUIP_AT % (i + 1), "call": func() -> void: _job.equip(id, slot, level)})
	if skill_level >= GameConfig.JOB_SKILL_MAX_LEVEL:
		actions.append({"text": UiText.JOB_ACT_MAX, "disabled": true})
	elif _job.points(level) <= 0:
		actions.append({"text": UiText.JOB_ACT_NO_POINTS, "disabled": true})
	else:
		actions.append({"text": UiText.JOB_ACT_LEVEL, "call": func() -> void: _job.level_up(id, level)})
	return actions


## 스킬 목록의 그 스킬 카드(실행 검사용). 없으면 null.
func skill_chip(id: String) -> SkillChip:
	return _list.get_node_or_null(id) as SkillChip


## 장착 칸 카드(실행 검사용): 0~2 = 액티브, 3~4 = 패시브, 5 = 궁극기.
func equip_chip(index: int) -> SkillChip:
	return _equip.get_child(index) as SkillChip


## 직업 바꾸기 버튼(실행 검사용).
func switch_button(id: String) -> Button:
	return _switch.get_node_or_null(id) as Button

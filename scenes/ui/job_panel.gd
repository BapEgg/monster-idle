class_name JobPanel
extends PanelContainer
## 직업 창(기획서 3장 스킬 시스템, 직업 1차): 오른쪽 위 "직업" 버튼으로 열고 닫는다.
## 왼쪽 = 주인공(직업 색 도형) · 직업 이름 · 역할 · 무기 · 인물 / 지금 능력치(패시브 포함) / 직업 바꾸기(개발용).
## 오른쪽 = 3섹터(사용자 결정 2026-10-03): 액티브(5) · 패시브(2) · 궁극기(1). 섹터마다 장착 수, 스킬마다 네모 그림 칸(JobSkillTile:
## 오른쪽 위 레벨 배지 — 모자라면 빨강, 됐는데 안 배웠으면 회색, 배웠으면 없음 / 장착한 칸은 흰 테두리 + 칸 번호).
## 스킬을 누르면 스킬 상세 창(모션 미리보기 · 설명 · 계수)이 뜨고, 그 아래 버튼으로 배우기 · 장착 · 해제 · 레벨 올리기.
## 위치 · 크기는 job_panel.tscn에서 에디터로 정한다.

const TITLE_FONT_SIZE := 24
const TEXT_FONT_SIZE := 18
const NAME_FONT_SIZE := 26
const SMALL_FONT_SIZE := 15
const STAT_FONT_SIZE := 17
const SWITCH_FONT_SIZE := 15
const SECTION_TITLE_FONT_SIZE := 18
const SECTION_PAD := 12.0

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
@onready var _hint: Label = %Hint
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
	UiKit.style_label(_mods, SMALL_FONT_SIZE, Palette.STAT_BOOSTED)
	for caption: Label in [_switch_title, _hint]:
		UiKit.style_caption(caption, SMALL_FONT_SIZE)
	_switch_title.text = UiText.JOB_SWITCH
	_hint.text = UiText.JOB_HINT
	for type: String in _sections:
		var section: PanelContainer = _sections[type]
		var box := StyleBoxFlat.new()
		box.bg_color = Palette.JOB_SECTION_BG
		box.border_color = Palette.PANEL_DIVIDER
		box.set_border_width_all(1)
		box.set_corner_radius_all(UiKit.PANEL_CORNER)
		box.set_content_margin_all(SECTION_PAD)
		section.add_theme_stylebox_override("panel", box)
		var title := _section_part(type, "Title")
		UiKit.style_label(title, SECTION_TITLE_FONT_SIZE, Palette.TEXT)
		title.add_theme_font_override("font", UiKit.bold_font())
		title.text = UiText.JOB_SECTION_TITLES[type]
		UiKit.style_caption(_section_part(type, "Info"), SMALL_FONT_SIZE)
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
	for type: String in JobDb.TYPES:
		_build_section(job, type, level)
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


func _section_part(type: String, part: String) -> Control:
	return (_sections[type] as PanelContainer).find_child(part, true, false) as Control


## 섹터 하나: 제목 옆에 장착 수 / 칸 수, 그 종류의 스킬마다 네모 칸.
func _build_section(job: JobDb.Job, type: String, level: int) -> void:
	var slots: Array[String] = _slots_of(type)
	var open_slots := _open_slot_count(type, level)
	var used := 0
	for i in open_slots:
		if slots[i] != "":
			used += 1
	(_section_part(type, "Info") as Label).text = UiText.JOB_SECTION_INFO[type] % [used, open_slots]
	var tiles := _section_part(type, "Tiles")
	for child in tiles.get_children():
		tiles.remove_child(child)
		child.queue_free()
	for skill in job.skills_of(type):
		var state := JobSkillTile.State.LEARNED
		if _job.skill_level(skill.id) <= 0:
			state = JobSkillTile.State.LEARNABLE if JobRules.is_unlocked(skill, level) else JobSkillTile.State.LOCKED
		var slot := slots.find(skill.id)
		var badge := ""
		if slot >= 0:
			badge = str(slot + 1) if type != "ultimate" else UiText.JOB_SECTION_TITLES[type]
		var tile := JobSkillTile.create(skill, state, _job.skill_level(skill.id), badge)
		tile.pressed.connect(show_skill.bind(skill.id))
		tiles.add_child(tile)


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


## 그 직업 스킬의 상세 창(모션 미리보기 · 설명 · 계수) + 아래 버튼(장착 · 해제 · 레벨 올리기).
func show_skill(id: String) -> void:
	var skill := JobDb.get_skill(id)
	if skill == null:
		return
	var level := _progress.level
	var mods := _job.mods(level)
	var sheet := SkillSheet.job_skill(skill, _job.skill_level(id), JobRules.player_stats(_job.job_id, level, mods), mods, level)
	_shown_skill = id
	_window.open(sheet, _job.job().color, _actions_for(skill))


func _actions_for(skill: JobDb.Skill) -> Array:
	var actions := []
	var level := _progress.level
	var id := skill.id
	var skill_level := _job.skill_level(id)
	if skill_level <= 0:
		if _job.can_learn(id, level):
			actions.append({"text": UiText.JOB_ACT_LEARN, "call": func() -> void: _job.learn(id, level), "accent": true})
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


## 그 스킬의 네모 칸(실행 검사용). 없으면 null.
func skill_tile(id: String) -> JobSkillTile:
	var skill := JobDb.get_skill(id)
	if skill == null:
		return null
	return _section_part(skill.type, "Tiles").get_node_or_null(id) as JobSkillTile


## 섹터 제목 옆 장착 수 글자(실행 검사용).
func section_info(type: String) -> String:
	return (_section_part(type, "Info") as Label).text


## 직업 바꾸기 버튼(실행 검사용).
func switch_button(id: String) -> Button:
	return _switch.get_node_or_null(id) as Button

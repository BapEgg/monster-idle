class_name JobPanel
extends PanelContainer
## 직업 창(기획서 3장 스킬 시스템, 직업 1차): 오른쪽 위 "직업" 버튼으로 열고 닫는다.
## 위 탭 "캐릭터 / 스킬"로 나눈다(사용자 결정 2026-10-03: 능력치와 장비를 나누지 않고 한 탭에).
## - 캐릭터: 왼쪽 = 주인공(직업 색 도형) · 직업 이름 · 역할 · 무기 · "이야기"(누르면 인물 · 섬에 온 계기 · 갈등 · 전직 갈래 창) · 패시브 보정 ·
##   능력치 표(HP · MP · 9종 · 치명 확률 · 치명 피해, 장비 · 패시브로 오른 값은 초록) · 전투 값 · 직업 바꾸기(개발용),
##   오른쪽 = 장비(GearView: 인형 7칸 · 아이템 정보 · 아이템 칸 · 정렬).
## - 스킬: 액티브 · 패시브 · 궁극기 한 섹터씩 위아래로. 섹터마다 이름 + "장착 n/m", 큰 장착 칸(JobSlot, 아직 안 열린 칸은 잠긴 모양),
##   그 종류의 스킬 목록(작은 카드 JobSkillTile, 가로로 넘겨 본다 — 업데이트로 스킬 · 궁극기가 늘어도 그대로 들어간다).
##   카드 상태: 잠김 = 회색 + 자물쇠 + 필요 레벨 / 배울 수 있음 = 빛나는 테두리 + "+" / 배움 = 컬러 + 레벨 점 / 장착 중 = 칸 번호 배지.
##   스킬을 누르면 고르고(흰 테두리 + 체크), 아래 행동 줄에서 배우기 · 장착 · 해제 · 레벨 올리기. 고른 스킬을 한 번 더 누르거나 "미리보기"를 누르면
##   스킬 상세 창(툴팁, 보기 전용). 스킬을 고른 채 장착 칸을 누르면 그 칸에 장착. 칸이 다 찼는데 "장착"이면 장착 모드(칸이 깜빡임) → 바꿀 칸을 누른다.
## 위치 · 크기는 job_panel.tscn에서 에디터로 정한다.

const TITLE_FONT_SIZE := 24
const TEXT_FONT_SIZE := 18
const NAME_FONT_SIZE := 26
const SMALL_FONT_SIZE := 15
const STAT_FONT_SIZE := 17
const STAT_NUMBER_WIDTH := 58.0
const STORY_TITLE_FONT_SIZE := 24
const STORY_HEAD_FONT_SIZE := 16
const STORY_TEXT_FONT_SIZE := 18
const TAB_FONT_SIZE := 18
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
var _tab := "skills"  # 지금 탭(character · skills). 다시 열어도 그대로
var _gear: GearBag

@onready var _title: Label = %Title
@onready var _points: Label = %Points
@onready var _close: Button = %Close
@onready var _portrait: JobPortrait = %Portrait
@onready var _job_name: Label = %JobName
@onready var _kind: Label = %Kind
@onready var _story_button: Button = %StoryButton
@onready var _story_layer: ColorRect = %StoryLayer
@onready var _story_card: PanelContainer = %StoryCard
@onready var _story_title: Label = %StoryTitle
@onready var _story_body: VBoxContainer = %StoryBody
@onready var _story_close: Button = %StoryClose
@onready var _gear_view: GearView = %GearView
@onready var _stats: GridContainer = %Stats
@onready var _combat: Label = %Combat
@onready var _mods: Label = %Mods
@onready var _switch_title: Label = %SwitchTitle
@onready var _switch: HBoxContainer = %Switch
@onready var _divider: VSeparator = %Divider
@onready var _stats_title: Label = %StatsTitle
## 탭 이름 → [탭 버튼, 페이지]
@onready var _tabs := {"character": [%TabCharacter, %CharacterPage], "skills": [%TabSkills, %SkillsPage]}
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
	UiKit.style_button(_story_button, SMALL_FONT_SIZE)
	_story_button.text = UiText.STORY_BUTTON
	_story_button.pressed.connect(open_story)
	_story_card.add_theme_stylebox_override("panel", UiKit.panel_box())
	UiKit.style_label(_story_title, STORY_TITLE_FONT_SIZE, Palette.TEXT)
	_story_title.add_theme_font_override("font", UiKit.bold_font())
	UiKit.style_button(_story_close, TEXT_FONT_SIZE)
	_story_close.text = UiText.JOB_CLOSE
	_story_close.pressed.connect(_story_layer.hide)
	_story_layer.gui_input.connect(func(event: InputEvent) -> void:
		var press := event as InputEventMouseButton
		if press != null and press.pressed:
			_story_layer.hide())
	UiKit.style_caption(_combat, SMALL_FONT_SIZE)
	UiKit.style_label(_mods, SMALL_FONT_SIZE, Palette.STAT_BOOSTED)
	UiKit.style_caption(_switch_title, SMALL_FONT_SIZE)
	_switch_title.text = UiText.JOB_SWITCH
	UiKit.style_label(_stats_title, SECTION_TITLE_FONT_SIZE, Palette.TEXT)
	_stats_title.add_theme_font_override("font", UiKit.bold_font())
	_stats_title.text = UiText.JOB_STATS_TITLE
	for tab: String in _tabs:
		var button: Button = _tabs[tab][0]
		button.text = UiText.JOB_TABS[tab]
		UiKit.style_button(button, TAB_FONT_SIZE)
		button.pressed.connect(show_tab.bind(tab))
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


## 주인공 장비(캐릭터 탭 오른쪽)를 잇는다(HUD). 장비가 바뀌면 왼쪽 능력치 표도 다시 그린다.
func bind_gear(gear: GearBag) -> void:
	_gear = gear
	_gear_view.bind(gear, _job, _progress)
	_gear.changed.connect(_queue_refresh)


## 이야기 창: 인물 · 섬에 온 계기 / 지금의 갈등 / 전직 갈래(기획서 3장 표, data/jobs.json). 창 밖이나 닫기를 누르면 닫힌다.
func open_story() -> void:
	var job := _job.job()
	_story_title.text = UiText.STORY_TITLE % job.name
	for child in _story_body.get_children():
		_story_body.remove_child(child)
		child.queue_free()
	for part: Array in [[UiText.STORY_PERSON, job.person], [UiText.STORY_CONFLICT, job.conflict], [UiText.STORY_PATHS, job.paths]]:
		if str(part[1]) == "":
			continue
		var head := Label.new()
		UiKit.style_caption(head, STORY_HEAD_FONT_SIZE)
		head.text = part[0]
		var text := Label.new()
		UiKit.style_label(text, STORY_TEXT_FONT_SIZE, Palette.TEXT)
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.text = part[1]
		_story_body.add_child(head)
		_story_body.add_child(text)
	_story_layer.visible = true


## 이야기 창 글자(실행 검사용): 제목 + 줄들.
func story_texts() -> PackedStringArray:
	var texts := PackedStringArray([_story_title.text])
	for label: Label in _story_body.get_children():
		texts.append(label.text)
	return texts


func is_story_open() -> bool:
	return _story_layer.visible


func gear_view() -> GearView:
	return _gear_view


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
	show_tab(_tab)
	refresh()


## 탭을 바꾼다(character · skills). 고른 탭 버튼은 밝은 바탕 + 아래 청록 줄.
func show_tab(tab: String) -> void:
	if not _tabs.has(tab):
		return
	_tab = tab
	if tab != "skills":
		_picking = false
	# 스킬 포인트는 스킬 탭에서만(능력치는 장비 · 패시브로 바뀐 능력치를 보는 곳이지 포인트를 나누는 곳이 아니다 — 사용자 결정 2026-10-03)
	_points.visible = tab == "skills"
	_story_layer.visible = false
	for each: String in _tabs:
		var on := each == tab
		(_tabs[each][1] as Control).visible = on
		var button: Button = _tabs[each][0]
		for state: String in ["normal", "hover", "pressed", "focus"]:
			button.add_theme_stylebox_override(state, _tab_box(on))
		button.add_theme_color_override("font_color", Palette.TEXT if on else Palette.TEXT_LABEL)
		button.add_theme_font_override("font", UiKit.bold_font() if on else ThemeDB.fallback_font)
	if tab == "character" and _gear != null:
		_gear_view.refresh()


static func _tab_box(on: bool) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Palette.JOB_TAB_ON if on else Palette.JOB_TAB_OFF
	box.border_color = Palette.JOB_TAB_LINE
	box.border_width_bottom = 3 if on else 0
	box.set_corner_radius_all(UiKit.ACCENT_CORNER)
	box.set_content_margin_all(6.0)
	return box


## 지금 탭(실행 검사용).
func current_tab() -> String:
	return _tab


func tab_button(tab: String) -> Button:
	return _tabs[tab][0] if _tabs.has(tab) else null


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
	var gear_bonus := _gear.bonus() if _gear != null else {}
	_show_stats(JobRules.player_sheet(job.id, level, mods, gear_bonus), JobRules.player_stats(job.id, level, mods, gear_bonus), mods, gear_bonus)
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

## 능력치 표: HP · MP 다음 9종(코어 정보창과 같은 이름 · 순서), 끝에 치명 확률 · 치명 피해. 칸마다 이름(회색) + 숫자(흰색 굵게, 패시브로 오른 값은 초록).
func _build_stat_table() -> void:
	var ids := PackedStringArray(["hp", "mp"])
	ids.append_array(SuffixDb.ids())
	ids.append_array(UnitStats.CRIT_STATS)
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
				caption.text = UiText.STAT_CRIT_NAMES.get(stat, SuffixDb.stat_name(stat))
		var number := Label.new()
		number.name = "Value"
		UiKit.style_number(number, STAT_FONT_SIZE)
		number.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		number.custom_minimum_size.x = STAT_NUMBER_WIDTH
		cell.add_child(caption)
		cell.add_child(number)
		_stats.add_child(cell)


func _show_stats(sheet: Dictionary, stats: UnitStats, mods: Dictionary, gear_bonus: Dictionary) -> void:
	var boosted := {}
	for stat: String in gear_bonus:  # 장비로 오른 능력치도 초록
		boosted[stat] = true
	for key: String in JobRules.MOD_STATS:
		if float(mods.get(key, 0.0)) > 0.0:
			boosted[JobRules.MOD_STATS[key]] = true
	if boosted.has("tough"):
		boosted["hp"] = true
	if boosted.has("abundant"):
		boosted["mp"] = true
	for cell: Control in _stats.get_children():
		var value := cell.get_node("Value") as Label
		value.text = stats.crit_text(cell.name) if UnitStats.CRIT_STATS.has(str(cell.name)) else str(int(sheet.get(cell.name, 0)))
		value.add_theme_color_override("font_color", Palette.STAT_BOOSTED if boosted.has(str(cell.name)) else Palette.TEXT)
	_combat.text = UiText.JOB_COMBAT_LINE % [roundi(stats.attack), SkillSheet.seconds(snappedf(stats.attack_interval, 0.01)), roundi(stats.attack_range)]


## 그 능력치의 숫자 글자(실행 검사용, hp · mp · 9종 · 치명타 id).
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
	(_section_part(type, "Info") as Label).text = UiText.JOB_SECTION_INFO % [used, open_slots]
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
	var sheet := SkillSheet.job_skill(skill, _job.skill_level(id), JobRules.player_stats(_job.job_id, level, mods, _gear.bonus() if _gear != null else {}), mods, level)
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

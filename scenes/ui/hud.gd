class_name Hud
extends CanvasLayer
## 화면 위 UI: 가상 조이스틱, 오른쪽 위 재화(골드 · 경험치 조각) · 사냥 상태 · 처치 수, 가방 버튼·가방 창, 대상 창(위 가운데),
## 오른쪽 아래의 공격 버튼(늘 보임) · 오토 버튼 · 스킬 칸(메이플키우기 배치를 따름, 사용자 결정 2026-10-02).
## 스킬 칸 1~3 = 파티 헨치 1~3의 고유 액티브(누르면 씀), 4~6 = 나중에 주인공 직업 스킬.
## 위치·크기는 이 장면(hud.tscn)을 에디터에서 열어 끌어서 정한다. 코드는 자리를 건드리지 않는다.
## 오른쪽 아래 버튼들은 화면 오른쪽 아래 모서리에 붙은 Controls 아래에 있어서, 휴대폰이 길어져도 모서리에서 같은 거리에 남는다.
## 조이스틱은 Godot 4.7 기본 노드(VirtualJoystick, 동적 모드)를 쓴다.
## 자기 영역(화면 왼쪽)을 누르면 그 자리에 생기고, 기울인 만큼 move_* 입력 액션을 눌러 준다.
## 그래서 주인공은 키보드와 똑같이 Input.get_vector()로 읽는다.
## PC에서는 마우스 왼쪽 버튼도 터치로 취급된다(project.godot: emulate_touch_from_mouse).

## 오토 버튼으로 사냥 방식을 바꿨을 때. main이 받아 주인공에게 알려 준다.
signal control_mode_selected(mode: AutoControl.Mode)
## 가방 창에서 코어를 파티에 넣거나 뺄 때. main이 필드의 헨치를 바꾼다.
signal party_requested(item: CoreItem, slot: int)
signal party_leave_requested(item: CoreItem)
## 스킬 칸을 눌렀을 때(0부터 센 칸 번호). main이 그 자리의 헨치에게 스킬을 쓰게 한다.
signal skill_requested(slot: int)
## 섬의 왕 버튼(보스전 밖 = 도전, 안 = 포기). main이 확인 창을 띄운다.
signal boss_requested
## 지휘 버튼을 필드로 끌어다 놓았을 때(화면 좌표) / 끌지 않고 뗐을 때("모여")
signal command_dragged(group: CommandButton.Group, screen_point: Vector2)
signal command_tapped(group: CommandButton.Group)
## 섬 지도 창에서 "이동"을 누름(섬 id, 지역 id)
signal travel_requested(island_id: String, region_id: String)

const MODE_FONT_SIZE := 22
const KILLS_FONT_SIZE := 18
const BANNER_FONT_SIZE := 34
const BANNER_SUB_FONT_SIZE := 20
## 미니맵 바닥에 섞는 섬 종족 색의 양(임시 도형 값)
const MINIMAP_TINT := 0.45
const OUTLINE_SIZE := 6
const JOYSTICK_RING_WIDTH := 3
## 스킬 칸 수(hud.tscn의 Controls/SkillSlot1~6)
const SKILL_SLOT_COUNT := 6
## 오른쪽 아래 버튼들 둘레의 여유(px). 이 안을 누르면 몹을 대상으로 지정하지 않는다(버튼을 누른 것으로 본다).
const CONTROLS_PADDING := 8.0

@onready var joystick: VirtualJoystick = $Joystick
@onready var attack_button: AttackButton = $Controls/AttackButton
@onready var auto_button: AutoButton = $Controls/AutoButton
@onready var target_frame: TargetFrame = $TargetFrame
@onready var level_bar: LevelBar = $LevelBar
@onready var currency_bar: CurrencyBar = $Currency
@onready var bag_button: BagButton = $TopControls/BagButton
@onready var bag_panel: BagPanel = $BagPanel
@onready var debug_button: TextButton = $TopControls/DebugButton
@onready var debug_panel: DebugPanel = $DebugPanel
@onready var boss_button: TextButton = $TopControls/BossButton
@onready var job_button: TextButton = $TopControls/JobButton
@onready var job_panel: JobPanel = $JobPanel
@onready var ultimate_slot: SkillSlot = $Controls/UltimateSlot
@onready var _commands: Array[CommandButton] = [$Controls/CommandAll, $Controls/CommandMelee, $Controls/CommandRanged]
@onready var mix_panel: MixPanel = $MixPanel
@onready var skill_window: SkillWindow = $SkillWindow
@onready var confirm_box: ConfirmBox = $ConfirmBox
@onready var minimap: Minimap = $Minimap
@onready var island_map: IslandMap = $IslandMap
@onready var map_button: TextButton = $TopControls/MapButton
@onready var _banner: Control = $RegionBanner
@onready var _banner_title: Label = $RegionBanner/BannerTitle
@onready var _banner_sub: Label = $RegionBanner/BannerSub
@onready var _controls: Control = $Controls
@onready var _top_controls: Control = $TopControls
@onready var _mode: Label = $Mode
@onready var _kills: Label = $Kills

var _player: Player
var _party: Array[Hench] = []
var _hunt_log: HuntLog
var _skill_slots: Array[SkillSlot] = []
var _job: JobState
var _progress: PlayerProgress
var _world: WorldState
var _banner_tween: Tween


func _ready() -> void:
	_style_label(_mode, MODE_FONT_SIZE)
	_style_label(_kills, KILLS_FONT_SIZE)
	_setup_joystick()
	auto_button.pressed.connect(_on_auto_button)
	for i in SKILL_SLOT_COUNT:
		var slot := _controls.get_node("SkillSlot%d" % (i + 1)) as SkillSlot
		var index := i
		slot.pressed.connect(func() -> void: skill_requested.emit(index))
		_skill_slots.append(slot)
	bag_button.pressed.connect(_on_bag_button)
	job_button.text = UiText.JOB_BUTTON
	job_button.pressed.connect(func() -> void:
		if job_panel.visible:
			job_panel.close()
		else:
			job_panel.open())
	ultimate_slot.pressed.connect(func() -> void: skill_requested.emit(SKILL_SLOT_COUNT))
	debug_button.text = UiText.DEBUG_BUTTON
	debug_button.visible = GameConfig.DEV_DEBUG_PANEL
	boss_button.pressed.connect(func() -> void: boss_requested.emit())
	for command in _commands:
		command.dragged_to.connect(func(group: CommandButton.Group, at: Vector2) -> void: command_dragged.emit(group, at))
		command.tapped.connect(func(group: CommandButton.Group) -> void: command_tapped.emit(group))
	set_boss_mode(false)
	debug_button.pressed.connect(func() -> void:
		if debug_panel.visible:
			debug_panel.hide()
		else:
			debug_panel.open())
	for modal: Control in _modals():
		modal.visibility_changed.connect(_on_modal_toggled)
	map_button.text = UiText.MAP_BUTTON
	map_button.pressed.connect(toggle_map)
	minimap.pressed.connect(toggle_map)
	island_map.travel_requested.connect(func(island_id: String, region_id: String) -> void: travel_requested.emit(island_id, region_id))
	_style_label(_banner_title, BANNER_FONT_SIZE)
	_style_label(_banner_sub, BANNER_SUB_FONT_SIZE)
	bag_panel.mix_requested.connect(mix_panel.open)
	bag_panel.party_requested.connect(func(item: CoreItem, slot: int) -> void: party_requested.emit(item, slot))
	bag_panel.party_leave_requested.connect(func(item: CoreItem) -> void: party_leave_requested.emit(item))
	mix_panel.core_shown.connect(bag_panel.select)
	bag_panel.info().skill_detail_requested.connect(skill_window.open)
	mix_panel.info().skill_detail_requested.connect(skill_window.open)


func bind_player(player: Player) -> void:
	_player = player
	auto_button.mode = player.control.mode


## 주인공 레벨 · 경험치를 왼쪽 위 막대에 이어 준다.
func bind_progress(progress: PlayerProgress) -> void:
	level_bar.bind(progress)


## 파티(헨치 배열, main이 자리마다 바꿔 끼운다)를 스킬 칸에 이어 준다.
func bind_party(party: Array[Hench]) -> void:
	_party = party
	debug_panel.bind(_hunt_log, party)


## 보스전 화면으로(on) 또는 보통 화면으로: 섬의 왕 버튼 글자(도전 ↔ 포기), 지휘 버튼 보이기.
func set_boss_mode(on: bool) -> void:
	boss_button.text = UiText.BOSS_GIVE_UP if on else UiText.BOSS_BUTTON
	for command in _commands:
		command.visible = on


## 지휘 버튼 하나(0 = 전원, 1 = 근접조, 2 = 원거리조; 실행 검사용).
func command_button(index: int) -> CommandButton:
	return _commands[index]


## 스킬 칸 하나(0부터, 실행 검사용).
func skill_slot(index: int) -> SkillSlot:
	return _skill_slots[index]


func set_kills(count: int) -> void:
	_kills.text = UiText.KILLS % count


## 주인공 직업(직업 창 · 직업 스킬 칸)을 잇는다.
func bind_job(job: JobState, progress: PlayerProgress) -> void:
	_job = job
	_progress = progress
	job_panel.bind(job, progress, skill_window, confirm_box)


## 지갑·코어 다루기(믹스·분해·잠금)·파티 이름을 가방 창과 믹스창에 이어 준다.
func bind_collection(wallet: Wallet, workshop: Workshop, party_names: Callable) -> void:
	currency_bar.bind(wallet)
	bag_panel.bind_collection(wallet, workshop, confirm_box, party_names)
	mix_panel.bind(workshop, confirm_box)


## 가방을 가방 버튼·가방 창에, 사냥 기록을 디버그 화면에 이어 준다.
func bind_hunt(bag: Bag, hunt_log: HuntLog) -> void:
	bag_panel.bind(bag)
	_hunt_log = hunt_log
	bag_button.count = bag.count()
	bag.changed.connect(func() -> void: bag_button.count = bag.count())


## 그 자리(화면 좌표)가 버튼(공격 · 오토 · 스킬 칸 · 가방)이나 열린 창(가방 · 믹스 · 확인) 위인가.
## 이런 곳을 누른 것은 몹 지정이 아니다.
func is_over_controls(point: Vector2) -> bool:
	for modal in _modals():
		if modal.visible and modal.get_global_rect().has_point(point):
			return true
	if minimap.is_visible_in_tree() and minimap.get_global_rect().grow(CONTROLS_PADDING).has_point(point):
		return true
	for node in find_children("*", "TouchScreenButton", true, false):
		var button := node as TouchScreenButton
		if button.is_visible_in_tree() and covers(button, point):
			return true
	return false


## 버튼 모양(shape) 안인가(둘레 CONTROLS_PADDING까지).
static func covers(button: TouchScreenButton, point: Vector2) -> bool:
	var local := button.get_global_transform().affine_inverse() * point
	if button.shape is CircleShape2D:
		return local.length() <= (button.shape as CircleShape2D).radius + CONTROLS_PADDING
	if button.shape is RectangleShape2D:
		var size := (button.shape as RectangleShape2D).size
		return Rect2(-size * 0.5, size).grow(CONTROLS_PADDING).has_point(local)
	return false


func _process(_delta: float) -> void:
	if _player == null:
		return
	target_frame.unit = _player.target if is_instance_valid(_player.target) else null
	_show_skills()
	var control := _player.control
	if not _player.is_alive():
		_show_mode(UiText.MODE_DOWN, Palette.MODE_DOWN)
	elif control.mode == AutoControl.Mode.SEMI_AUTO:
		_show_mode(UiText.MODE_SEMI_AUTO, Palette.MODE_MANUAL)
	elif control.mode == AutoControl.Mode.MANUAL:
		_show_mode(UiText.MODE_FULL_MANUAL, Palette.MODE_MANUAL)
	elif not control.is_manual():
		_show_mode(UiText.MODE_AUTO, Palette.MODE_AUTO)
	elif control.is_held():
		_show_mode(UiText.MODE_MANUAL, Palette.MODE_MANUAL)
	else:
		_show_mode(UiText.MODE_RETURNING % ceili(control.seconds_until_auto()), Palette.MODE_MANUAL)


## 스킬 칸 1~3에 파티 헨치의 스킬, 4~6에 직업 액티브, 궁극기 칸에 궁극기(대기 시간 · 기다리는 중)를 보여 준다.
func _show_skills() -> void:
	var party_count := mini(_party.size(), SKILL_SLOT_COUNT)
	for i in _skill_slots.size():
		if i < party_count:
			var hench: Hench = _party[i] if is_instance_valid(_party[i]) else null
			if hench == null or hench.skill == null:
				_skill_slots[i].show_skill(null, Color.TRANSPARENT, false)
			else:
				_skill_slots[i].show_skill(hench.skill, hench.species.color, hench.is_skill_requested())
		else:
			_show_job_slot(_skill_slots[i], i - party_count)
	_show_job_slot(ultimate_slot, JobCaster.SLOT_COUNT - 1)


## 직업 스킬 칸 하나(index = JobCaster 칸). 비었으면 그 칸이 열리는 레벨(궁극기 칸)을 흐리게.
func _show_job_slot(slot: SkillSlot, index: int) -> void:
	var caster := _player.caster
	var skill: JobSkill = caster.skills[index] if index < caster.skills.size() else null
	var job := JobDb.get_job(_player.job_id)
	var locked := ""
	var locked_color := Palette.JOB_LEVEL_READY
	if skill == null and index == JobCaster.SLOT_COUNT - 1 and job != null and _job != null and _progress != null:
		var ultimate := job.skills_of("ultimate")
		if not ultimate.is_empty() and _job.skill_level(ultimate[0].id) <= 0:
			locked = UiText.SKILL_SLOT_LOCKED % ultimate[0].unlock
			if _progress.level < ultimate[0].unlock:
				locked_color = Palette.JOB_LEVEL_SHORT
	slot.show_skill(skill, job.color if job != null else Color.TRANSPARENT, caster.is_requested(index), locked, locked_color)


func _on_bag_button() -> void:
	if bag_panel.visible:
		bag_panel.close()
		mix_panel.hide()
	else:
		bag_panel.open()


## 화면을 덮는 창들(가방 · 믹스 · 직업 · 섬 지도 · 디버그 · 스킬 상세 · 확인).
func _modals() -> Array[Control]:
	return [bag_panel, mix_panel, job_panel, island_map, debug_panel, skill_window, confirm_box]


## 섬 · 지역을 미니맵 · 섬 지도 창에 이어 준다(player = 미니맵 점 · 사냥 경로).
func bind_world(world: WorldState, progress: PlayerProgress, player: Player) -> void:
	_world = world
	island_map.bind(world, progress)
	minimap.player = player
	world.moved.connect(_show_world)
	_show_world()
	debug_panel.islands_toggled.connect(func() -> void:
		if island_map.visible:
			island_map.refresh())


## 미니맵 위 띠(섬 · 지역 · 레벨대)와 바닥 색.
func _show_world() -> void:
	var island := IslandDb.get_island(_world.island)
	var region := IslandDb.get_region(_world.region)
	var levels := IslandDb.level_range(_world.island, _world.region)
	minimap.title = UiText.WORLD_TITLE % [island.name, region.name, levels.x, levels.y]
	var tribe := TribeDb.get_tribe(island.tribe)
	minimap.field_tint = Palette.MINIMAP_FIELD.lerp(tribe.color, MINIMAP_TINT) if tribe != null else Palette.MINIMAP_FIELD


## 지도 버튼 · 미니맵: 섬 지도 창을 열고 닫는다.
func toggle_map() -> void:
	if island_map.visible:
		island_map.hide()
	elif not _any_modal_open():
		island_map.open()


func _any_modal_open() -> bool:
	for modal in _modals():
		if modal.visible:
			return true
	return false


## 지역에 들어설 때 화면 위 가운데에 큰 지역 이름이 잠깐 떴다 사라진다(sub = 작은 줄, 예: 후퇴 안내).
func show_region_banner(title: String, sub := "") -> void:
	_banner_title.text = title
	_banner_sub.text = sub
	_banner_sub.visible = sub != ""
	if _banner_tween != null:
		_banner_tween.kill()
	_banner.modulate.a = 0.0
	_banner_tween = create_tween()
	_banner_tween.tween_property(_banner, "modulate:a", 1.0, GameConfig.REGION_BANNER_FADE)
	_banner_tween.tween_interval(GameConfig.REGION_BANNER_SECONDS)
	_banner_tween.tween_property(_banner, "modulate:a", 0.0, GameConfig.REGION_BANNER_FADE)


## 지역 이름 띠의 글자(실행 검사용): [큰 줄, 작은 줄].
func banner_texts() -> PackedStringArray:
	return PackedStringArray([_banner_title.text, _banner_sub.text])


## 창이 하나라도 열려 있으면 조이스틱과 오른쪽 아래 버튼(공격 · 오토 · 스킬 칸), 오른쪽 위 버튼(가방 · 디버그)을 숨겨,
## 창을 누른 손가락이 주인공을 움직이거나 그 밑의 버튼을 누르지 않게 한다(창은 닫기 버튼으로 닫는다).
func _on_modal_toggled() -> void:
	var any_open := false
	for modal in _modals():
		any_open = any_open or modal.visible
	joystick.visible = not any_open
	_controls.visible = not any_open
	_top_controls.visible = not any_open  # 가방 창이 화면을 덮으면 그 밑의 가방·디버그 버튼이 눌리지 않게
	minimap.visible = not any_open
	target_frame.modulate.a = 0.0 if any_open else 1.0  # 창 위로 겹쳐 보이지 않게


func _on_auto_button() -> void:
	var mode := AutoControl.next_mode(auto_button.mode)
	auto_button.mode = mode
	control_mode_selected.emit(mode)


func _show_mode(text: String, color: Color) -> void:
	_mode.text = text
	_mode.add_theme_color_override("font_color", color)


func _style_label(label: Label, font_size: int) -> void:
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Palette.TEXT)
	label.add_theme_color_override("font_outline_color", Palette.TEXT_OUTLINE)
	label.add_theme_constant_override("outline_size", OUTLINE_SIZE)


# ─── 조이스틱 ────────────────────────────────────

func _setup_joystick() -> void:
	joystick.anchor_right = GameConfig.JOYSTICK_ZONE_WIDTH
	joystick.offset_right = 0.0
	joystick.joystick_size = GameConfig.JOYSTICK_RADIUS * 2.0  # 지름
	joystick.tip_size = GameConfig.JOYSTICK_KNOB_RADIUS * 2.0
	joystick.add_theme_stylebox_override("normal_joystick", _circle(Palette.JOYSTICK_BASE_IDLE, Palette.JOYSTICK_RING_IDLE))
	joystick.add_theme_stylebox_override("pressed_joystick", _circle(Palette.JOYSTICK_BASE, Palette.JOYSTICK_RING))
	joystick.add_theme_stylebox_override("normal_tip", _circle(Palette.JOYSTICK_KNOB_IDLE))
	joystick.add_theme_stylebox_override("pressed_tip", _circle(Palette.JOYSTICK_KNOB))
	joystick.resized.connect(_place_joystick_rest)
	_place_joystick_rest()


## 쉬는 위치를 화면 왼쪽·아래 가장자리에서 정해진 거리만큼 안쪽에 둔다(노치 피하기).
## 기본 노드는 위치를 영역 크기에 대한 비율로 받으므로 화면 크기가 바뀔 때마다 다시 계산한다.
func _place_joystick_rest() -> void:
	var area := joystick.size
	if area.x <= 0.0 or area.y <= 0.0:
		return
	var margin := GameConfig.JOYSTICK_REST_MARGIN
	joystick.initial_offset_ratio = Vector2(margin.x / area.x, 1.0 - margin.y / area.y)


## 둥근 StyleBox. 모서리를 크게 깎아 원으로 만든다.
func _circle(fill: Color, ring := Color.TRANSPARENT) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.set_corner_radius_all(4096)
	box.corner_detail = 24
	if ring.a > 0.0:
		box.border_color = ring
		box.set_border_width_all(JOYSTICK_RING_WIDTH)
	return box

extends Node2D
## 메인 장면: 필드에 주인공과 헨치 3마리를 세우고, 야생 헨치를 풀어 자동 사냥을 돌린다.
## 화면에서 몹을 누르면 대상으로 지정한다(TargetPicker).
## 처치하면 코어가 떨어져 주인공에게 빨려 들어가 가방에 들어간다. 사냥 기록으로 하루 처치 수를 잰다(프로토타입 4).
## 가방 창에서 코어를 파티에 넣거나 믹스·분해·잠금한다(프로토타입 5, 실제 처리는 Workshop).
## 켤 때 저장을 불러오고(가방 · 골드 · 파티 · 사냥 방식), 바뀐 것은 묶어서 저장한다(SaveSchedule, 기획서 9장).
## 끌 때와 앱이 뒤로 갈 때(휴대폰 홈 버튼 · PC 창에서 다른 곳을 누름)는 기다리지 않고 바로 저장한다.
## 섬의 왕 버튼으로 연습 보스전을 연다(프로토타입 6): 같은 필드에서 야생을 치우고 보스를 세운다. 지휘 버튼으로 무리를 움직인다.

## 지금까지 처치한 야생 헨치 수.
var kills := 0
var party: Array[Hench] = []
var bag := Bag.new()
var wallet := Wallet.new()
var workshop := Workshop.new(bag, wallet)
var hunt_log := HuntLog.new()
## 보스전 중인 섬의 왕(보스전 밖이면 null).
var boss: Boss
## 세이브 저장소. 비워 두면 기기 파일(GameConfig.SAVE_PATH). 실행 검사는 장면을 띄우기 전에 따로 쓰는 파일을 넣는다.
var save_store: SaveStore

var _save_schedule := SaveSchedule.new(GameConfig.SAVE_INTERVAL_SECONDS, GameConfig.SAVE_SOON_SECONDS)

## 드랍 판정용 난수(씨앗이 같으면 같은 순서로 떨어진다). 튀어 나가는 방향 같은 연출은 _fx_rng.
var _loot_rng := RandomNumberGenerator.new()
var _fx_rng := RandomNumberGenerator.new()

@onready var _field: Field = $Field
@onready var _player: Player = $Field/Objects/Player
@onready var _hud: Hud = $HUD
@onready var _spawner: WildSpawner = $WildSpawner
@onready var _picker: TargetPicker = $TargetPicker


func _ready() -> void:
	RenderingServer.set_default_clear_color(Palette.SEA)
	_player.field = _field
	_player.set_camera_limits(_field.bounds().grow(GameConfig.CAMERA_LIMIT_MARGIN))
	_player.place_at(_field.spawn_position())
	_player.died.connect(_on_player_died)
	# 조이스틱에 손을 대기만 해도(기울이기 전에도) 수동으로 바뀌게 알려 준다.
	_hud.joystick.pressed.connect(func() -> void: _player.touching = true)
	_hud.joystick.released.connect(func(_tilt: Vector2) -> void: _player.touching = false)
	_hud.control_mode_selected.connect(func(mode: AutoControl.Mode) -> void:
		_player.control.mode = mode
		_save_schedule.mark_dirty(true))
	_load_game()
	_hud.bind_player(_player)
	_picker.setup(_player, _hud)
	_hud.bind_hunt(bag, hunt_log)
	_hud.bind_collection(wallet, workshop, party_names)
	_hud.party_requested.connect(assign_party)
	_hud.party_leave_requested.connect(leave_party)
	_hud.set_kills(kills)
	_loot_rng.seed = GameConfig.FIELD_SEED + 2
	_fx_rng.randomize()
	_spawn_party()
	_hud.bind_party(party)
	_hud.skill_requested.connect(func(slot: int) -> void:
		if slot >= 0 and slot < party.size():
			party[slot].request_skill())
	bag.changed.connect(_save_schedule.mark_dirty)
	wallet.changed.connect(_save_schedule.mark_dirty)
	workshop.acted.connect(_save_schedule.mark_dirty.bind(true))
	_spawner.killed.connect(_on_kill)
	_spawner.setup(_field, _player)
	_hud.boss_requested.connect(_on_boss_button)
	_hud.command_dragged.connect(_on_command_dragged)
	_hud.command_tapped.connect(_on_command_tapped)


## 파티 자리마다: 그 자리에 넣어 둔 코어가 있으면 그 코어의 헨치, 없으면 처음 헨치(GameConfig.PARTY_HENCHES).
func _spawn_party() -> void:
	for i in GameConfig.PARTY_HENCHES.size():
		var item := _party_core(i)
		var species := item.species() if item != null else HenchDb.get_species(GameConfig.PARTY_HENCHES[i])
		party.append(_spawn_party_member(i, species, _player.position + GameConfig.FOLLOW_SLOTS[i], item))


func _party_core(slot: int) -> CoreItem:
	for item in bag.cores:
		if item.party_slot == slot:
			return item
	return null


## item이 있으면 그 코어의 레벨·나이·성별·변이와 능력치(UnitStats.from_core)로 싸운다. 없으면 역할 표의 능력치.
func _spawn_party_member(slot: int, species: HenchSpecies, at: Vector2, item: CoreItem = null) -> Hench:
	var hench := Hench.create(species, Unit.Team.PARTY)
	if item != null:
		hench.stats = UnitStats.from_core(item)
		hench.level = item.level
		hench.age = item.age
		hench.gender = item.gender
		hench.variant = item.variant
	hench.field = _field
	hench.leader = _player
	hench.slot = GameConfig.FOLLOW_SLOTS[slot]
	_field.objects.add_child(hench)
	hench.place_at(at)
	return hench


## 파티 자리마다 지금 헨치 이름(가방 창의 파티 편성 고르기에 보인다).
func party_names() -> PackedStringArray:
	var names := PackedStringArray()
	for hench in party:
		names.append(hench.species.name)
	return names


## 코어를 그 파티 자리에 넣는다. 그 자리에 있던 코어는 파티에서 빠지고, 필드의 헨치가 이 코어의 종으로 바뀐다.
## 헨치는 코어의 능력치로 싸운다(환산은 임시, 밸런스 단계에서 다시 정한다).
func assign_party(item: CoreItem, slot: int) -> void:
	if slot < 0 or slot >= party.size():
		return
	if item.in_party():
		leave_party(item)
	for other in bag.cores:
		if other.party_slot == slot:
			other.party_slot = -1
	item.party_slot = slot
	_replace_party_member(slot, item.species(), item)
	bag.changed.emit()
	_save_schedule.mark_dirty(true)


## 코어를 파티에서 뺀다. 그 자리는 처음 헨치(GameConfig.PARTY_HENCHES)로 돌아간다.
func leave_party(item: CoreItem) -> void:
	var slot := item.party_slot
	if slot < 0:
		return
	item.party_slot = -1
	_replace_party_member(slot, HenchDb.get_species(GameConfig.PARTY_HENCHES[slot]))
	bag.changed.emit()
	_save_schedule.mark_dirty(true)


func _replace_party_member(slot: int, species: HenchSpecies, item: CoreItem = null) -> void:
	var old := party[slot]
	var at := old.position
	old.remove_from_group(Unit.group_name(Unit.Team.PARTY))
	old.queue_free()
	party[slot] = _spawn_party_member(slot, species, at, item)


# ─── 저장 ────────────────────────────────────────

## 저장을 불러와 가방 · 지갑 · 사냥 방식을 되살린다. 저장이 없으면(처음 켤 때) 개발용 시작 가방을 넣는다.
func _load_game() -> void:
	if save_store == null:
		save_store = LocalSaveStore.new(GameConfig.SAVE_PATH)
	var data := save_store.load_data()
	if save_store.last_error != "":
		push_warning(save_store.last_error)
	if data.is_empty():
		if GameConfig.DEV_STARTER_BAG:
			_fill_starter_bag()
			_save_schedule.mark_dirty()
		return
	var dropped := GameSave.restore(data, bag, wallet, GameConfig.PARTY_HENCHES.size(), workshop.mastery, workshop.codex)
	if dropped > 0:
		push_warning("저장의 %s %d개를 읽지 못해 버림(도감에 없는 종)" % [UiText.TERM_CORE, dropped])
	_player.control.mode = GameSave.control_mode(data)


## 지금 상태를 바로 저장한다. 보통은 묶어서(_process) 부르고, 끌 때·앱이 뒤로 갈 때는 바로 부른다.
func save_game() -> bool:
	var data := GameSave.capture(bag, wallet, _player.control.mode, int(Time.get_unix_time_from_system()), workshop.mastery, workshop.codex)
	if not save_store.save_data(data):
		push_warning(save_store.last_error)
		_save_schedule.mark_dirty()  # 다음 차례에 다시 해 본다
		return false
	_save_schedule.clear()
	return true


func _process(delta: float) -> void:
	if _save_schedule.tick(delta):
		save_game()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT:
			if save_store != null and _save_schedule.dirty:
				save_game()


## 개발 확인용 시작 가방(data/dev_starter.json): 믹스·배지를 바로 시험할 수 있게 코어와 골드를 넣는다.
func _fill_starter_bag() -> void:
	var root: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/dev_starter.json"))
	if not root is Dictionary:
		push_error("시작 가방 데이터를 읽지 못함")
		return
	for row: Variant in root.get("cores", []):
		if row is Dictionary:
			var item := CoreItem.from_dict(row)
			workshop.codex.register(item.species_id)
			bag.add(item)
	wallet.add_gold(int(root.get("gold", 0)))


func _physics_process(delta: float) -> void:
	hunt_log.add_time(delta, _player.control.is_manual())


func _on_kill(hench: Hench) -> void:
	kills += 1
	_hud.set_kills(kills)
	hunt_log.add_kill(_player.control.is_manual())
	wallet.add_gold(GameConfig.GOLD_PER_KILL)
	var item := Drops.roll_core(_loot_rng, hench.core_template())
	if item != null:
		drop_core(hench.position, item)


## 코어를 그 자리(몹 발밑)에 떨어뜨린다. 튀어 올랐다 땅에 떨어지고, 잠깐 뒤 주인공에게 빨려 들어가 가방에 들어간다.
func drop_core(at: Vector2, item: CoreItem) -> void:
	var scatter := Vector2.from_angle(_fx_rng.randf() * TAU) * GameConfig.CORE_POP_SCATTER
	scatter.y *= GameConfig.TILE_SIZE.y / GameConfig.TILE_SIZE.x  # 땅 위에서 고르게 흩어지도록 세로는 타일 비율만큼
	var drop := CoreDrop.new()
	drop.setup(at, scatter, item, TribeDb.get_tribe(item.species().tribe).color, _player)
	drop.collected.connect(_on_core_collected)
	_field.objects.add_child(drop)


func _on_core_collected(item: CoreItem) -> void:
	workshop.codex.register(item.species_id)
	bag.add(item)
	hunt_log.add_core(item)
	var label := HenchDb.get_species(item.species_id).name
	if item.shining:
		label = UiText.SHINING + " " + label
	_field.show_number(_player.position + Vector2(0, -_player.overlay_height() - 26.0), UiText.PICKUP % label, Palette.CORE_SHINE if item.shining else Palette.TEXT)


## 주인공이 쓰러지면 잠시 뒤 파티 전체가 시작 지점에서 다시 일어난다(기획서: 패배해도 페널티 없이 후퇴).
## 보스전 중이면 보스전은 패배로 끝난다.
func _on_player_died(_unit: Unit) -> void:
	if boss != null:
		end_boss(UiText.BOSS_LOSE)
	await get_tree().create_timer(GameConfig.PLAYER_REVIVE_SECONDS, false, true).timeout
	var spawn := _field.spawn_position()
	_player.revive_at(spawn)
	for hench in party:
		hench.revive_at(spawn + hench.slot)


# ─── 보스전 (프로토타입 6, 연습용) ──────────────────────

## 섬의 왕 버튼: 보스전 밖이면 도전할지, 안이면 그만둘지 묻는다.
func _on_boss_button() -> void:
	if boss == null:
		_hud.confirm_box.ask(UiText.BOSS_ASK % HenchDb.get_species(GameConfig.BOSS_SPECIES).name, start_boss)
	else:
		_hud.confirm_box.ask(UiText.BOSS_GIVE_UP_ASK, func() -> void: end_boss(UiText.BOSS_GAVE_UP))


## 보스전을 연다: 야생 출현을 멈추고 필드의 야생을 치운 뒤, 주인공 곁에 섬의 왕을 세워 싸움을 건다.
func start_boss() -> void:
	if boss != null or not _player.is_alive():
		return
	_spawner.pause()
	for node in get_tree().get_nodes_in_group(Unit.group_name(Unit.Team.WILD)):
		node.remove_from_group(Unit.group_name(Unit.Team.WILD))
		node.queue_free()
	boss = Boss.create_boss(HenchDb.get_species(GameConfig.BOSS_SPECIES))
	boss.field = _field
	boss.home = _boss_spawn_point()
	boss.position = boss.home
	boss.died.connect(_on_boss_died)
	_field.objects.add_child(boss)
	boss.reset_physics_interpolation()
	boss.engage(_player)
	_player.set_target(boss)
	for hench in party:
		hench.command_regroup()
	_hud.set_boss_mode(true)


## 보스전을 끝낸다(이김 · 짐 · 그만둠): 장판과 보스를 치우고, 지휘를 풀고, 야생 출현을 다시 연다.
func end_boss(message: String) -> void:
	if boss == null:
		return
	var old := boss
	boss = null
	_field.clear_dangers()
	if is_instance_valid(old) and old.is_alive():
		old.remove_from_group(Unit.group_name(Unit.Team.WILD))
		old.queue_free()
	for hench in party:
		hench.command_regroup()
	_hud.set_boss_mode(false)
	_spawner.resume()
	_hud.confirm_box.tell(message)


func _on_boss_died(unit: Unit) -> void:
	end_boss(UiText.BOSS_WIN % unit.display_name)


## 주인공에게서 GameConfig.BOSS_SPAWN_OFFSET만큼 떨어진 걸을 수 있는 곳(막혔으면 방향을 돌려 가며 찾는다).
func _boss_spawn_point() -> Vector2:
	for i in 8:
		var at := _player.position + GameConfig.BOSS_SPAWN_OFFSET.rotated(TAU * i / 8.0)
		if _field.is_walkable(at):
			return at
	return _player.position


## 지휘 버튼을 필드로 끌어다 놓음: 몹 위면 그 몹을 치고, 아니면 그 자리로 가서 버틴다(나란히 조금씩 벌려 선다).
func _on_command_dragged(group: CommandButton.Group, screen_point: Vector2) -> void:
	var members := _command_members(group)
	var on_wild := _picker.wild_at(screen_point)
	var point := get_viewport().get_canvas_transform().affine_inverse() * screen_point
	for i in members.size():
		if on_wild != null:
			members[i].command_attack(on_wild)
		else:
			members[i].command_move(point + Vector2(GameConfig.COMMAND_SPREAD * (i - (members.size() - 1) * 0.5), 0.0))
	_field.show_burst(point, GameConfig.COMMAND_MARK_RADIUS, Palette.COMMAND_LINE)


## 끌지 않고 뗌: "모여"(버티기를 풀고 주인공을 따라간다).
func _on_command_tapped(group: CommandButton.Group) -> void:
	for hench in _command_members(group):
		hench.command_regroup()


## 그 무리의 살아 있는 헨치. 근접조 = 사거리가 GameConfig.MELEE_RANGE_MAX 이하(탱커 · 근접딜러), 원거리조 = 나머지.
func _command_members(group: CommandButton.Group) -> Array[Hench]:
	var members: Array[Hench] = []
	for hench in party:
		if not is_instance_valid(hench) or not hench.is_alive():
			continue
		var melee := hench.stats.attack_range <= GameConfig.MELEE_RANGE_MAX
		if group == CommandButton.Group.ALL or (group == CommandButton.Group.MELEE) == melee:
			members.append(hench)
	return members

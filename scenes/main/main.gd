extends Node2D
## 메인 장면: 필드에 주인공과 헨치 3마리를 세우고, 야생 헨치를 풀어 자동 사냥을 돌린다.
## 화면에서 몹을 누르면 대상으로 지정한다(TargetPicker).
## 처치하면 코어가 떨어져 주인공에게 빨려 들어가 가방에 들어간다. 사냥 기록으로 하루 처치 수를 잰다(프로토타입 4).
## 가방 창에서 코어를 파티에 넣거나 믹스·분해·잠금한다(프로토타입 5, 실제 처리는 Workshop).
## 켤 때 저장을 불러오고(가방 · 골드 · 파티 · 사냥 방식), 바뀐 것은 묶어서 저장한다(SaveSchedule, 기획서 9장).
## 끌 때와 앱이 뒤로 갈 때(휴대폰 홈 버튼 · PC 창에서 다른 곳을 누름)는 기다리지 않고 바로 저장한다.
## 성장: 처치하면 몹 레벨만큼 경험치 · 골드(Growth). 주인공 레벨이 오르면 주인공과 코어 없는 헨치가 세진다.
## 파티 코어도 같은 경험치를 받고(상한 = 주인공 레벨), 파티 밖 코어는 사냥에서 떨어지는 경험치 조각을 가방 정보창에서 먹인다.
## 파티 코어가 오르면 그 헨치 능력치도 바로 바뀐다.
## 섬의 왕 버튼으로 연습 보스전을 연다(프로토타입 6): 같은 필드에서 야생을 치우고 보스를 세운다. 지휘 버튼으로 무리를 움직인다.
## 주인공 직업(기획서 3장, 직업 1차): 레벨이 오르면 배울 수 있게 된 직업 스킬을 알리고(직업 창에서 배운다), 직업 · 장착이 바뀌면 주인공 능력치 ·
## 스킬 칸 4~6 · 궁극기 칸 · 파티 헨치(패시브: 전우애 · 진찰)를 다시 맞춘다. 저장된다.
## 섬 · 지역(기획서 7장, 로드맵 8): 지도 창에서 고른 섬 · 지역으로 옮기면 필드를 다시 짓고(바닥 색 · 장식물) 그 지역 종을 푼다.
## 주인공이 쓰러지면 그 섬의 바로 앞 지역으로 후퇴한다(입문이면 그 자리). 섬의 왕 버튼은 지금 섬의 왕과 싸운다.
## 장비(기획서 3장): 직업 창 캐릭터 탭에서 끼고 빼면 주인공 능력치(9종 · 치명)와 파티 헨치(파티 헨치 체력 옵션)를 다시 맞춘다. 저장된다.

## 지금까지 처치한 야생 헨치 수.
var kills := 0
## 파티 자리마다 헨치(GameConfig.PARTY_SIZE칸, 빈 자리 = null). 자리에 넣은 코어의 헨치만 나온다(사용자 결정 2026-10-03: 기본 헨치 없음).
var party: Array[Hench] = []
var bag := Bag.new()
var wallet := Wallet.new()
var workshop := Workshop.new(bag, wallet)
var hunt_log := HuntLog.new()
## 주인공 레벨 · 경험치(Workshop이 코어 레벨업 상한으로도 쓴다)
var progress: PlayerProgress = workshop.progress
## 주인공 직업 · 직업 스킬(레벨 · 장착)
var job := JobState.new()
## 지금 섬 · 지역과 열린 섬
var world := WorldState.new()
## 주인공 장비(가진 것 · 낀 칸)
var gear := GearBag.new()
var _job_level_seen := 1  # 레벨업 때 새로 배울 수 있게 된 스킬을 알리려고 지난 레벨을 기억한다
## 보스전 중인 섬의 왕(보스전 밖이면 null).
var boss: Boss
## 세이브 저장소. 비워 두면 기기 파일(GameConfig.SAVE_PATH). 실행 검사는 장면을 띄우기 전에 따로 쓰는 파일을 넣는다.
var save_store: SaveStore

var _save_schedule := SaveSchedule.new(GameConfig.SAVE_INTERVAL_SECONDS, GameConfig.SAVE_SOON_SECONDS)

## 드랍 판정용 난수(씨앗이 같으면 같은 순서로 떨어진다). 튀어 나가는 방향 같은 연출은 _fx_rng.
var _loot_rng := RandomNumberGenerator.new()
var _fx_rng := RandomNumberGenerator.new()
## 개발용 장비(시작 가방 · 디버그 화면 "장비 받기")를 만드는 난수
var _gear_rng := RandomNumberGenerator.new()

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
	_gear_rng.seed = GameConfig.FIELD_SEED + 4
	_load_game()
	job.sync(progress.level)
	_job_level_seen = progress.level
	_player.set_level(progress.level)
	_hud.bind_player(_player)
	_hud.bind_progress(progress)
	progress.leveled_up.connect(_on_level_up)
	workshop.core_leveled.connect(_on_core_leveled)
	_picker.setup(_player, _hud)
	_hud.bind_hunt(bag, hunt_log)
	_hud.bind_collection(wallet, workshop, party_names)
	_hud.party_requested.connect(assign_party)
	_hud.party_leave_requested.connect(leave_party)
	_hud.set_kills(kills)
	_loot_rng.seed = GameConfig.FIELD_SEED + 2
	_fx_rng.randomize()
	_spawn_party()
	_apply_job()
	job.changed.connect(_on_job_changed)
	_hud.bind_party(party)
	_hud.bind_job(job, progress)
	_hud.bind_gear(gear)
	gear.changed.connect(_on_gear_changed)
	_hud.gear_requested.connect(give_dev_gear)
	_hud.skill_requested.connect(_on_skill_requested)
	bag.changed.connect(_save_schedule.mark_dirty)
	wallet.changed.connect(_save_schedule.mark_dirty)
	workshop.acted.connect(_save_schedule.mark_dirty.bind(true))
	_spawner.killed.connect(_on_kill)
	_field.rebuild(world.island, world.region)
	_spawner.setup(_field, _player, world.island, world.region)
	world.moved.connect(_on_world_moved)
	_hud.bind_world(world, progress, _player)
	_hud.travel_requested.connect(travel)
	_hud.show_region_banner(_region_title())
	_hud.boss_requested.connect(_on_boss_button)
	_hud.command_dragged.connect(_on_command_dragged)
	_hud.command_tapped.connect(_on_command_tapped)


## 파티 자리마다: 그 자리에 넣어 둔 코어가 있으면 그 코어의 헨치, 없으면 빈 자리(null).
func _spawn_party() -> void:
	for i in GameConfig.PARTY_SIZE:
		var item := _party_core(i)
		party.append(_spawn_party_member(i, item, _player.position + GameConfig.FOLLOW_SLOTS[i]) if item != null else null)


## 파티에 있는 헨치들(빈 자리 빼고, 자리 차례).
func members() -> Array[Hench]:
	var list: Array[Hench] = []
	for hench in party:
		if is_instance_valid(hench):
			list.append(hench)
	return list


func _party_core(slot: int) -> CoreItem:
	for item in bag.cores:
		if item.party_slot == slot:
			return item
	return null


## 그 코어의 헨치를 세운다: 코어의 레벨·나이·성별·변이와 능력치(UnitStats.from_core)로 싸운다. 직업 패시브(진찰 · 전우애)도 받는다.
func _spawn_party_member(slot: int, item: CoreItem, at: Vector2) -> Hench:
	var hench := Hench.create(item.species(), Unit.Team.PARTY)
	hench.stats = _member_stats(item)
	hench.level = item.level
	hench.age = item.age
	hench.gender = item.gender
	hench.variant = item.variant
	_apply_job_to_hench(hench, job.mods(progress.level))
	hench.field = _field
	hench.leader = _player
	hench.slot = GameConfig.FOLLOW_SLOTS[slot]
	_field.objects.add_child(hench)
	hench.place_at(at)
	return hench


## 파티 자리마다 지금 헨치 이름(가방 창의 파티 편성 고르기에 보인다). 빈 자리는 "빈 자리".
func party_names() -> PackedStringArray:
	var names := PackedStringArray()
	for hench in party:
		names.append(hench.species.name if is_instance_valid(hench) else UiText.PARTY_SLOT_EMPTY)
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
	_replace_party_member(slot, item)
	bag.changed.emit()
	_save_schedule.mark_dirty(true)


## 코어를 파티에서 뺀다. 그 자리는 빈다(사용자 결정 2026-10-03: 기본 헨치로 바뀌지 않는다).
func leave_party(item: CoreItem) -> void:
	var slot := item.party_slot
	if slot < 0:
		return
	item.party_slot = -1
	_replace_party_member(slot, null)
	bag.changed.emit()
	_save_schedule.mark_dirty(true)


## 그 자리의 헨치를 바꾼다(item = null이면 비운다). 새 헨치는 옛 헨치 자리(없으면 주인공 곁)에 선다.
func _replace_party_member(slot: int, item: CoreItem) -> void:
	var old := party[slot]
	var at: Vector2 = _player.position + GameConfig.FOLLOW_SLOTS[slot]
	if is_instance_valid(old):
		at = old.position
		old.remove_from_group(Unit.group_name(Unit.Team.PARTY))
		old.queue_free()
	party[slot] = _spawn_party_member(slot, item, at) if item != null else null


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
	var dropped := GameSave.restore(data, bag, wallet, GameConfig.PARTY_SIZE, workshop.mastery, workshop.codex, progress, job, world, gear)
	if dropped > 0:
		push_warning("저장의 %s %d개를 읽지 못해 버림(도감에 없는 종)" % [UiText.TERM_CORE, dropped])
	if GameConfig.DEV_STARTER_BAG and int(data.get("version", 0)) < 9:
		_fill_starter_gear(_starter_data())  # 장비가 생기기 전 저장(판 8까지): 개발 확인용 시작 장비만 넣는다
	_player.control.mode = GameSave.control_mode(data)


## 지금 상태를 바로 저장한다. 보통은 묶어서(_process) 부르고, 끌 때·앱이 뒤로 갈 때는 바로 부른다.
func save_game() -> bool:
	var data := GameSave.capture(bag, wallet, _player.control.mode, int(Time.get_unix_time_from_system()), workshop.mastery, workshop.codex, progress, job, world, gear)
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
	var root := _starter_data()
	for row: Variant in root.get("cores", []):
		if row is Dictionary:
			var item := CoreItem.from_dict(row)
			workshop.codex.register(item.species_id)
			bag.add(item)
	wallet.add_gold(int(root.get("gold", 0)))
	_fill_starter_gear(root)


func _starter_data() -> Dictionary:
	var root: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/dev_starter.json"))
	if not root is Dictionary:
		push_error("시작 가방 데이터를 읽지 못함")
		return {}
	return root


## 개발 확인용 시작 장비(dev_starter.json의 gear): 부위 · 등급 · 품질 · 레벨 · 낄까. 무기는 지금 직업 것, 값은 씨앗 고정 굴림.
func _fill_starter_gear(root: Dictionary) -> void:
	for row: Variant in root.get("gear", []):
		if row is Dictionary:
			var item := gear.add(GearRules.roll(_gear_rng, str(row.get("kind", "helmet")), job.job_id, int(row.get("level", 1)), int(row.get("grade", 0)), int(row.get("quality", 1))))
			if bool(row.get("equip", false)):
				gear.equip(item, job.job_id, maxi(item.level, progress.level))


func _physics_process(delta: float) -> void:
	hunt_log.add_time(delta, _player.control.is_manual())


func _on_kill(hench: Hench) -> void:
	kills += 1
	_hud.set_kills(kills)
	hunt_log.add_kill(_player.control.is_manual())
	wallet.add_gold(Growth.gold_per_kill(hench.level))
	var gained := Growth.exp_per_kill(hench.level)
	progress.gain(gained)  # 주인공 먼저(헨치 상한이 주인공 레벨이므로)
	for i in party.size():
		var core := _party_core(i)
		if core != null:
			workshop.gain_kill_exp(core, gained)
	if Drops.roll_exp_shard(_loot_rng):
		wallet.add_exp_shards(1)
		_field.show_number(_player.position + Vector2(0, -_player.overlay_height() - 52.0), UiText.EXP_SHARD_PICKUP % 1, Palette.EXP_SHARD)
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


## 주인공 레벨이 오름: 주인공이 세지고 체력이 다 찬다. 머리 위에 "레벨 업!".
func _on_level_up(level: int) -> void:
	_player.set_level(level, true)
	_field.show_number(_player.position + Vector2(0, -_player.overlay_height() - 40.0), UiText.LEVEL_UP % level, Palette.LEVEL_UP_TEXT)
	var learnable := job.newly_learnable(_job_level_seen, level)  # 이번에 배울 수 있게 된 직업 스킬(직업 창에서 배운다)
	_job_level_seen = level
	for i in learnable.size():
		var skill := JobDb.get_skill(learnable[i])
		_field.show_number(_player.position + Vector2(0, -_player.overlay_height() - 64.0 - 18.0 * i), UiText.JOB_LEARNABLE % skill.name, Palette.JOB_SKILL_CAST)
	if level in GameConfig.JOB_PASSIVE_SLOT_LEVELS:
		_apply_job()  # 패시브 칸이 열렸다
	_save_schedule.mark_dirty(true)


## 파티 코어의 레벨이 오름(처치 경험치 · 경험치 조각): 그 자리 헨치의 능력치를 바로 바꾸고 머리 위에 "레벨 업!".
func _on_core_leveled(item: CoreItem) -> void:
	if item.party_slot >= 0 and item.party_slot < party.size():
		var hench := party[item.party_slot]
		_set_member_stats(hench, _member_stats(item), item.level)
		if is_instance_valid(hench):
			_field.show_number(hench.position + Vector2(0, -hench.overlay_height() - 30.0), UiText.LEVEL_UP % item.level, Palette.LEVEL_UP_TEXT)


## 파티 헨치의 능력치: 코어 능력치. 직업 패시브(진찰) · 장비 옵션(파티 헨치 최대 체력)으로 최대 체력 +.
func _member_stats(item: CoreItem) -> UnitStats:
	var stats := UnitStats.from_core(item)
	stats.max_hp *= 1.0 + float(job.mods(progress.level).get("party_hp", 0.0)) + float(gear.bonus().get("party_hp", 0.0))
	return stats


## 직업 패시브 중 헨치에게 가는 것: 전우애 = 탱커 헨치가 받는 피해 −.
static func _apply_job_to_hench(hench: Hench, mods: Dictionary) -> void:
	var guard := float(mods.get("tank_damage_taken", 0.0)) if hench.species.role == "tank" else 0.0
	hench.damage_taken_scale = 1.0 - guard


## 직업 · 장착 · 스킬 레벨에 맞춰 주인공 능력치, 직업 스킬 칸, 파티 헨치(패시브)를 다시 맞춘다.
func _apply_job() -> void:
	var mods := job.mods(progress.level)
	gear.fit_job(job.job_id)  # 다른 직업의 무기는 빠진다(바뀌었으면 _on_gear_changed가 다시 맞춘다)
	_player.gear_bonus = gear.bonus()
	_player.set_job(job.job_id, mods)
	var list: Array[JobSkill] = []
	for id in job.actives:
		list.append(JobSkill.create(JobDb.get_skill(id), job.skill_level(id), mods) if id != "" else null)
	list.append(JobSkill.create(JobDb.get_skill(job.ultimate), job.skill_level(job.ultimate), mods) if job.ultimate != "" else null)
	_player.caster.set_skills(list)
	for i in party.size():
		var item := _party_core(i)
		if is_instance_valid(party[i]) and item != null:
			_set_member_stats(party[i], _member_stats(item), item.level)
			_apply_job_to_hench(party[i], mods)


## 장비를 끼거나 뺐다: 주인공 능력치(9종 · 치명)와 파티 헨치(파티 헨치 체력 옵션)를 다시 맞추고 곧 저장한다.
func _on_gear_changed() -> void:
	_player.set_gear(gear.bonus())
	for i in party.size():
		var item := _party_core(i)
		if is_instance_valid(party[i]) and item != null:
			_set_member_stats(party[i], _member_stats(item), item.level)
	_save_schedule.mark_dirty(true)


## 개발용: 지금 직업 · 레벨 근처의 무작위 장비 하나를 넣는다(디버그 화면 "장비 받기"). 장비를 얻는 곳(뽑기 · 던전 · 미션)은 그 단계에서.
func give_dev_gear() -> GearItem:
	return gear.add(GearRules.roll_random(_gear_rng, job.job_id, progress.level))


func _on_job_changed() -> void:
	_apply_job()
	_save_schedule.mark_dirty(true)


## 스킬 칸을 누름: 0~2 = 파티 헨치 스킬, 3~5 = 직업 액티브, 6 = 궁극기.
func _on_skill_requested(slot: int) -> void:
	if slot < party.size():
		if is_instance_valid(party[slot]):
			party[slot].request_skill()
	else:
		_player.request_job_skill(slot - party.size())


## 헨치 능력치를 바꾼다(체력 비율은 지킨다).
func _set_member_stats(hench: Hench, stats: UnitStats, level: int) -> void:
	if not is_instance_valid(hench):
		return
	var ratio := hench.hp / hench.stats.max_hp if hench.stats.max_hp > 0.0 else 1.0
	hench.stats = stats
	hench.level = level
	if hench.is_alive():
		hench.hp = stats.max_hp * ratio


## 주인공이 쓰러지면 잠시 뒤 파티 전체가 다시 일어난다(기획서 7장: 패배해도 페널티 없이 이전 지역으로 후퇴).
## 입문 밖이면 그 섬의 바로 앞 지역으로 옮긴 뒤 그 시작 지점에서, 입문이면 그 자리 시작 지점에서. 보스전 중이면 보스전은 패배로 끝난다(지역은 그대로).
func _on_player_died(_unit: Unit) -> void:
	var in_boss := boss != null
	if in_boss:
		end_boss(UiText.BOSS_LOSE)
	await get_tree().create_timer(GameConfig.PLAYER_REVIVE_SECONDS, false, true).timeout
	if not in_boss and world.retreat():
		_hud.show_region_banner(_region_title(), UiText.WORLD_RETREAT)
	_regroup_at_spawn()


## 주인공과 파티를 지금 필드의 시작 지점에 세운다(쓰러졌으면 일으킨다).
func _regroup_at_spawn() -> void:
	var spawn := _field.spawn_position()
	if _player.is_alive():
		_player.place_at(spawn)
	else:
		_player.revive_at(spawn)
	for hench in members():
		if hench.is_alive():
			hench.place_at(spawn + hench.slot)
		else:
			hench.revive_at(spawn + hench.slot)


# ─── 섬 · 지역 (기획서 7장, 로드맵 8) ───────────────────

## 지도 창에서 고른 섬 · 지역으로 간다. 갈 수 없거나(닫힘 · 레벨 모자람 · 지금 있는 곳) 보스전 중이면 false.
func travel(island_id: String, region_id: String) -> bool:
	if boss != null or not world.can_enter(island_id, region_id, progress.level):
		return false
	world.move_to(island_id, region_id)
	_hud.show_region_banner(_region_title())
	return true


## 섬 · 지역을 옮김(이동 · 후퇴 · 불러오기): 바닥에 남은 코어는 바로 가방에 넣고, 필드를 다시 지은 뒤 그 지역 종을 푼다.
func _on_world_moved() -> void:
	for node in _field.objects.get_children():
		if node is CoreDrop:
			var drop := node as CoreDrop
			_field.objects.remove_child(drop)
			drop.queue_free()
			_on_core_collected(drop.item)
	_field.clear_dangers()
	_field.rebuild(world.island, world.region)
	_player.set_target(null)
	_regroup_at_spawn()
	_spawner.relocate(world.island, world.region)
	_save_schedule.mark_dirty(true)


## "용섬 · 특수 (Lv 15~40)"
func _region_title() -> String:
	var levels := IslandDb.level_range(world.island, world.region)
	return UiText.WORLD_TITLE % [IslandDb.get_island(world.island).name, IslandDb.get_region(world.region).name, levels.x, levels.y]


# ─── 보스전 (프로토타입 6, 연습용) ──────────────────────

## 섬의 왕 버튼: 보스전 밖이면 도전할지, 안이면 그만둘지 묻는다.
func _on_boss_button() -> void:
	if boss == null:
		_hud.confirm_box.ask(UiText.BOSS_ASK % _king().name, start_boss)
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
	boss = Boss.create_boss(_king())
	boss.field = _field
	boss.home = _boss_spawn_point()
	boss.position = boss.home
	boss.died.connect(_on_boss_died)
	_field.objects.add_child(boss)
	boss.reset_physics_interpolation()
	boss.engage(_player)
	_player.set_target(boss)
	for hench in members():
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
	for hench in members():
		hench.command_regroup()
	_hud.set_boss_mode(false)
	_spawner.resume()
	_hud.confirm_box.tell(message)


## 지금 섬의 왕(없으면 연습 보스 GameConfig.BOSS_SPECIES).
func _king() -> HenchSpecies:
	var king := IslandDb.king(world.island)
	return king if king != null else HenchDb.get_species(GameConfig.BOSS_SPECIES)


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
	var squad := _command_members(group)
	var on_wild := _picker.wild_at(screen_point)
	var point := get_viewport().get_canvas_transform().affine_inverse() * screen_point
	for i in squad.size():
		if on_wild != null:
			squad[i].command_attack(on_wild)
		else:
			squad[i].command_move(point + Vector2(GameConfig.COMMAND_SPREAD * (i - (squad.size() - 1) * 0.5), 0.0))
	_field.show_burst(point, GameConfig.COMMAND_MARK_RADIUS, Palette.COMMAND_LINE)


## 끌지 않고 뗌: "모여"(버티기를 풀고 주인공을 따라간다).
func _on_command_tapped(group: CommandButton.Group) -> void:
	for hench in _command_members(group):
		hench.command_regroup()


## 그 무리의 살아 있는 헨치. 근접조 = 사거리가 GameConfig.MELEE_RANGE_MAX 이하(탱커 · 근접딜러), 원거리조 = 나머지.
func _command_members(group: CommandButton.Group) -> Array[Hench]:
	var group_members: Array[Hench] = []
	for hench in members():
		if not hench.is_alive():
			continue
		var melee := hench.stats.attack_range <= GameConfig.MELEE_RANGE_MAX
		if group == CommandButton.Group.ALL or (group == CommandButton.Group.MELEE) == melee:
			group_members.append(hench)
	return group_members

extends Node2D
## 메인 장면: 필드에 주인공과 헨치 3마리를 세우고, 야생 헨치를 풀어 자동 사냥을 돌린다.
## 화면에서 몹을 누르면 대상으로 지정한다(TargetPicker).
## 처치하면 코어가 떨어져 주인공에게 빨려 들어가 가방에 들어간다. 사냥 기록으로 하루 처치 수를 잰다(프로토타입 4).

## 지금까지 처치한 야생 헨치 수.
var kills := 0
var party: Array[Hench] = []
var bag := Bag.new()
var hunt_log := HuntLog.new()

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
	_hud.control_mode_selected.connect(func(mode: AutoControl.Mode) -> void: _player.control.mode = mode)
	_hud.bind_player(_player)
	_picker.setup(_player, _hud)
	_hud.bind_hunt(bag, hunt_log)
	_hud.set_kills(kills)
	_loot_rng.seed = GameConfig.FIELD_SEED + 2
	_fx_rng.randomize()
	_spawn_party()
	_spawner.killed.connect(_on_kill)
	_spawner.setup(_field, _player)


func _spawn_party() -> void:
	for i in GameConfig.PARTY_HENCHES.size():
		var hench := Hench.create(HenchDb.get_species(GameConfig.PARTY_HENCHES[i]), Unit.Team.PARTY)
		hench.field = _field
		hench.leader = _player
		hench.slot = GameConfig.FOLLOW_SLOTS[i]
		_field.objects.add_child(hench)
		hench.place_at(_player.position + hench.slot)
		party.append(hench)


func _physics_process(delta: float) -> void:
	hunt_log.add_time(delta, _player.control.is_manual())


func _on_kill(hench: Hench) -> void:
	kills += 1
	_hud.set_kills(kills)
	hunt_log.add_kill(_player.control.is_manual())
	var item := Drops.roll_core(_loot_rng, hench.species.id, hench.age)
	if item != null:
		drop_core(hench.position, item)


## 코어를 그 자리(몹 발밑)에 떨어뜨린다. 튀어 올랐다 땅에 떨어지고, 잠깐 뒤 주인공에게 빨려 들어가 가방에 들어간다.
func drop_core(at: Vector2, item: CoreItem) -> void:
	var scatter := Vector2.from_angle(_fx_rng.randf() * TAU) * GameConfig.CORE_POP_SCATTER
	scatter.y *= GameConfig.TILE_SIZE.y / GameConfig.TILE_SIZE.x  # 땅 위에서 고르게 흩어지도록 세로는 타일 비율만큼
	var drop := CoreDrop.new()
	drop.setup(at, scatter, item, HenchDb.get_species(item.species_id).color, _player)
	drop.collected.connect(_on_core_collected)
	_field.objects.add_child(drop)


func _on_core_collected(item: CoreItem) -> void:
	bag.add(item)
	hunt_log.add_core(item)
	var label := HenchDb.get_species(item.species_id).name
	if item.shining:
		label = UiText.SHINING + " " + label
	_field.show_number(_player.position + Vector2(0, -_player.overlay_height() - 26.0), UiText.PICKUP % label, Palette.CORE_SHINE if item.shining else Palette.TEXT)


## 주인공이 쓰러지면 잠시 뒤 파티 전체가 시작 지점에서 다시 일어난다(기획서: 패배해도 페널티 없이 후퇴).
func _on_player_died(_unit: Unit) -> void:
	await get_tree().create_timer(GameConfig.PLAYER_REVIVE_SECONDS, false, true).timeout
	var spawn := _field.spawn_position()
	_player.revive_at(spawn)
	for hench in party:
		hench.revive_at(spawn + hench.slot)

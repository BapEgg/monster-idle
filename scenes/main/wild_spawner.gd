class_name WildSpawner
extends Node
## 야생 헨치를 필드에 풀어 놓고, 쓰러지면 잠시 뒤 주인공에게서 떨어진 다른 곳에 새로 내보낸다.
## 보스전 동안은 멈춘다(pause) — 다시 풀면(resume) 모자란 만큼 새로 내보낸다.

signal killed(hench: Hench)

## 멈춤(보스전 중): 새로 내보내지 않는다.
var paused := false

var _field: Field
var _player: Player
var _rng := RandomNumberGenerator.new()


func setup(field: Field, player: Player) -> void:
	_field = field
	_player = player
	_rng.seed = GameConfig.FIELD_SEED + 1
	for i in GameConfig.WILD_COUNT:
		_spawn_one()


func _spawn_one() -> void:
	var ids := GameConfig.WILD_SPECIES
	var species := HenchDb.get_species(ids[_rng.randi() % ids.size()])
	var cell := _field.random_free_cell(_rng, _player.position, GameConfig.WILD_SPAWN_MIN_CELLS)
	var hench := Hench.create(species, Unit.Team.WILD)
	hench.age = Drops.roll_age(_rng)
	hench.gender = Drops.roll_gender(_rng)
	hench.level = Drops.wild_level(species, hench.age)
	hench.variant = Drops.roll_variant(_rng, GameConfig.MANUAL_VARIANT_BONUS if _player.control.is_manual() else 0.0)  # 수동 중이면 변이체 우대(기획서 7장)
	hench.field = _field
	hench.home = Iso.cell_center(cell)
	hench.position = hench.home
	hench.died.connect(_on_died)
	_field.objects.add_child(hench)
	hench.reset_physics_interpolation()


func pause() -> void:
	paused = true


## 다시 풀고, 필드에 모자란 만큼(GameConfig.WILD_COUNT까지) 새로 내보낸다.
func resume() -> void:
	paused = false
	var alive := get_tree().get_nodes_in_group(Unit.group_name(Unit.Team.WILD)).size()
	for i in maxi(GameConfig.WILD_COUNT - alive, 0):
		_spawn_one()


func _on_died(unit: Unit) -> void:
	killed.emit(unit)
	await get_tree().create_timer(GameConfig.WILD_RESPAWN_SECONDS, false, true).timeout
	if not paused:
		_spawn_one()

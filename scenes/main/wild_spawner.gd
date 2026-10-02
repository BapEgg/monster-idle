class_name WildSpawner
extends Node
## 야생 헨치를 필드에 풀어 놓고, 쓰러지면 잠시 뒤 주인공에게서 떨어진 다른 곳에 새로 내보낸다.

signal killed(hench: Hench)

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
	hench.field = _field
	hench.home = Iso.cell_center(cell)
	hench.position = hench.home
	hench.died.connect(_on_died)
	_field.objects.add_child(hench)
	hench.reset_physics_interpolation()


func _on_died(unit: Unit) -> void:
	killed.emit(unit)
	await get_tree().create_timer(GameConfig.WILD_RESPAWN_SECONDS, false, true).timeout
	_spawn_one()

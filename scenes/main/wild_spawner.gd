class_name WildSpawner
extends Node
## 야생 헨치를 필드에 풀어 놓고, 쓰러지면 잠시 뒤 주인공에게서 떨어진 다른 곳에 새로 내보낸다.
## 나오는 종 · 레벨은 지금 섬 · 지역을 따른다(IslandDb.spawn_table · wild_level, 기획서 서식지). 지역을 옮기면(relocate) 다시 푼다.
## 보스전 동안은 멈춘다(pause) — 다시 풀면(resume) 모자란 만큼 새로 내보낸다.

signal killed(hench: Hench)

## 멈춤(보스전 중): 새로 내보내지 않는다.
var paused := false

var _field: Field
var _player: Player
var _rng := RandomNumberGenerator.new()
var _table := []  # 출현표 [[종 id, 비중], …]
var _levels := Vector2i(1, 1)  # 지역 레벨대
var _epoch := 0  # 지역을 옮길 때마다 늘린다(옮기기 전에 쓰러진 몹이 새 지역에 다시 나오지 않게)


func setup(field: Field, player: Player, island_id: String, region_id: String) -> void:
	_field = field
	_player = player
	_rng.seed = GameConfig.FIELD_SEED + 1
	relocate(island_id, region_id)


## 그 섬 · 지역의 출현표로 바꾸고, 필드의 야생을 치운 뒤 새로 푼다.
func relocate(island_id: String, region_id: String) -> void:
	_epoch += 1
	_table = IslandDb.spawn_table(island_id, region_id)
	_levels = IslandDb.level_range(island_id, region_id)
	clear()
	if not paused:
		for i in GameConfig.WILD_COUNT:
			_spawn_one()


## 필드의 야생을 모두 치운다(쓰러진 것 포함).
func clear() -> void:
	for node in get_tree().get_nodes_in_group(Unit.group_name(Unit.Team.WILD)):
		node.remove_from_group(Unit.group_name(Unit.Team.WILD))
		node.queue_free()


func _spawn_one() -> void:
	var species := HenchDb.get_species(IslandDb.pick_species(_table, _rng.randf()))
	if species == null:
		return
	var cell := _field.random_free_cell(_rng, _player.position, GameConfig.WILD_SPAWN_MIN_CELLS)
	var hench := Hench.create(species, Unit.Team.WILD)
	hench.age = Drops.roll_age(_rng)
	hench.gender = Drops.roll_gender(_rng)
	hench.level = IslandDb.wild_level(species, hench.age, _levels)
	hench.stats = UnitStats.for_hench(species.role, true, hench.level)  # 레벨만큼 세다
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
	var epoch := _epoch
	await get_tree().create_timer(GameConfig.WILD_RESPAWN_SECONDS, false, true).timeout
	if not paused and epoch == _epoch:
		_spawn_one()

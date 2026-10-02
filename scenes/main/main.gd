extends Node2D
## 메인 장면(프로토타입 2): 필드에 주인공과 헨치 3마리를 세우고, 야생 헨치를 풀어 자동 사냥을 돌린다.

## 지금까지 처치한 야생 헨치 수.
var kills := 0
var party: Array[Hench] = []

@onready var _field: Field = $Field
@onready var _player: Player = $Field/Objects/Player
@onready var _hud: Hud = $HUD
@onready var _spawner: WildSpawner = $WildSpawner


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
	_hud.set_kills(kills)
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


func _on_kill(_hench: Hench) -> void:
	kills += 1
	_hud.set_kills(kills)


## 주인공이 쓰러지면 잠시 뒤 파티 전체가 시작 지점에서 다시 일어난다(기획서: 패배해도 페널티 없이 후퇴).
func _on_player_died(_unit: Unit) -> void:
	await get_tree().create_timer(GameConfig.PLAYER_REVIVE_SECONDS, false, true).timeout
	var spawn := _field.spawn_position()
	_player.revive_at(spawn)
	for hench in party:
		hench.revive_at(spawn + hench.slot)

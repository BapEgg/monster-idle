class_name TargetPicker
extends Node
## 화면에서 몹을 누르면 주인공의 대상으로 지정하고, 같은 몹을 빨리 두 번 누르면(더블 탭) 바로 다가가 공격한다.
## 휴대폰 터치 기준이다. PC에서는 마우스 클릭이 터치로 바뀌어 들어온다(emulate_touch_from_mouse).
## 메인 장면의 맨 마지막 자식으로 둔다. Godot는 입력을 장면 트리의 아래쪽 노드부터 받으므로(_input),
## 조이스틱보다 먼저 받아서, 몹을 누른 손가락은 조이스틱을 띄우지 않게 막을 수 있다(set_input_as_handled).
## 오른쪽 아래 버튼(공격·오토·스킬 칸) 위를 누른 것은 버튼 몫이라 건드리지 않는다.

var _player: Player
var _hud: Hud
var _last_tap_unit: Unit
var _last_tap_ms := -100000


func setup(player: Player, hud: Hud) -> void:
	_player = player
	_hud = hud


func _input(event: InputEvent) -> void:
	if _player == null:
		return
	var touch := event as InputEventScreenTouch
	if touch != null and touch.pressed:
		_on_tap(touch.position)
		return
	# 터치에 딸려 오는(또는 터치로 바뀌기 전의) 마우스 클릭: 같은 누름이 두 번 세지지 않게 막기만 한다.
	var click := event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		if not _hud.is_over_controls(click.position) and wild_at(click.position) != null:
			get_viewport().set_input_as_handled()


func _on_tap(at: Vector2) -> void:
	if _hud.is_over_controls(at):
		return
	var picked := wild_at(at)
	if picked == null:
		return
	var now := Time.get_ticks_msec()
	var same := is_instance_valid(_last_tap_unit) and _last_tap_unit == picked
	if Targeting.is_double_tap(_last_tap_ms, now, same):
		_player.attack_target(picked)
	else:
		_player.set_target(picked)
	_last_tap_unit = picked
	_last_tap_ms = now
	get_viewport().set_input_as_handled()


## 화면 좌표 그 자리에 있는 야생 헨치(몸 가운데에서 GameConfig.TAP_PICK_RADIUS 안). 없으면 null.
func wild_at(screen_point: Vector2) -> Unit:
	var to_world := get_viewport().get_canvas_transform().affine_inverse()
	var wilds: Array[Unit] = []
	var points := PackedVector2Array()
	for node in get_tree().get_nodes_in_group(Unit.group_name(Unit.Team.WILD)):
		var wild := node as Unit
		if wild.is_alive():
			wilds.append(wild)
			points.append(wild.global_position + wild.body_center())
	var index := Targeting.index_at(points, to_world * screen_point, GameConfig.TAP_PICK_RADIUS)
	return wilds[index] if index >= 0 else null

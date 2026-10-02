class_name Player
extends Unit
## 주인공. 사냥 방식(AutoControl.Mode, 공격 버튼 위의 오토 버튼)에 따라 움직인다.
## - 풀오토: 자동 사냥. 키보드(WASD·방향키)나 가상 조이스틱을 만지는 동안은 수동이고,
##   손을 떼면 GameConfig.MANUAL_RETURN_SECONDS 뒤(기본 0 = 바로) 다시 자동 사냥으로 돌아온다.
## - 세미오토(그리고 풀오토에서 만지는 동안): 이동은 직접, 공격은 사거리 안에 들어온 야생 헨치를 자동으로 한다.
## - 수동: 이동도 공격도 직접 한다.
## 대상: 화면에서 몹을 눌러 지정하거나(set_target), 자동 사냥·공격 버튼이 고른다. 발밑 고리와 화면 위 대상 창으로 보인다.
## 공격 버튼(attack 액션: 화면 공격 버튼·Space): 대상(없으면 가까운 적)에게 다가가 쓰러질 때까지 싸운다.
##   한 번 누르면 그 대상과 끝까지 싸우고, 누르고 있으면 다음 적으로 이어 간다. 조이스틱으로 움직이면 다가가기를 멈춘다.
## 원점 = 발밑(y정렬 기준). 그림은 도형(그림자 + 몸 + 머리)으로 대체한다.

# 임시 도형 치수(px). 그림이 들어오면 사라진다.
const SHADOW_RADIUS := Vector2(18, 8)
const BODY_CENTER := Vector2(0, -19)
const BODY_RADIUS := 14.0
const HEAD_CENTER := Vector2(0, -44)
const HEAD_RADIUS := 18.0
const EYE_GAP := 6.5
const EYE_RADIUS := 2.6
const OUTLINE_WIDTH := 2.0
const DOWNED_ALPHA := 0.4
## 걸을 때 통통 튀는 높이(px)와 빠르기.
const BOB_HEIGHT := 3.0
const BOB_SPEED := 16.0

## 사냥 방식과 자동/수동 판단.
var control := AutoControl.new(GameConfig.MANUAL_RETURN_SECONDS, GameConfig.START_CONTROL_MODE)
## 조이스틱에 손을 대고 있나(HUD 조이스틱 신호로 main이 알려 준다). 기울이지 않고 대기만 해도 수동이 된다.
var touching := false
## 지금 대상(발밑 고리 · 화면 위 대상 창). 지정만 하고 아직 싸우지 않을 수도 있다.
var target: Unit
## 지금 싸우는 야생 헨치. 파티 헨치들이 이 대상을 돕는다.
var hunt_target: Unit

var _chasing := false  # 공격 버튼으로 대상에게 다가가 싸우는 중

var _walk_time := 0.0

@onready var _camera: Camera2D = $Camera2D


func _ready() -> void:
	stats = UnitStats.for_player()
	_camera.zoom = Vector2.ONE * GameConfig.CAMERA_ZOOM
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = GameConfig.CAMERA_SMOOTHING_SPEED
	super()


func _think(delta: float) -> void:
	var input := read_move_input()
	control.update(delta, touching or input != Vector2.ZERO)
	_drop_lost_target(control.is_manual())
	if not control.is_manual():
		_hunt()
		return
	var attack_held := Input.is_action_pressed("attack")
	if attack_held:
		_engage()
	if input != Vector2.ZERO:
		move_by_input(input)
		_chasing = false
	elif _chasing and _has_target():
		walk_to(target.position, stats.attack_range * 0.9)
	if control.auto_attacks():
		_attack_nearby()
	elif _chasing or attack_held:
		_attack_target()


## 대상을 바꾼다(null = 없음). 화면에서 몹을 눌렀을 때도 부른다.
## 자동 사냥 중이면 그 몹부터 사냥하고, 직접 조작 중이면 공격 버튼을 눌러야 싸운다.
func set_target(unit: Unit) -> void:
	if not is_instance_valid(target):
		target = null
	if unit == target:
		return
	if target != null:
		target.targeted = false
	target = unit
	if unit != null:
		unit.targeted = true
	_chasing = false


func is_manually_controlled() -> bool:
	return control.is_manual()


## 직접 조작 중에는 밀려나지 않는다(내가 누른 대로만 움직이게).
func _uses_personal_space() -> bool:
	return not control.is_manual()


## 이동 입력. 키보드와 가상 조이스틱이 같은 move_* 액션을 누르므로 여기서 한 번에 읽힌다.
## 길이 0~1, 화면 방향(위 = y 음수).
func read_move_input() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down", GameConfig.MOVE_DEADZONE)


func _has_target() -> bool:
	return is_instance_valid(target) and target.is_alive()


## 대상이 쓰러졌거나 사라졌으면 놓는다. 직접 조작 중이면 너무 멀어진 대상도 놓는다.
func _drop_lost_target(check_distance: bool) -> void:
	if _has_target() and not (check_distance and Iso.ground_distance(position, target.position) > GameConfig.TARGET_KEEP_RANGE):
		return
	if not is_instance_valid(target):
		target = null
	if not is_instance_valid(hunt_target) or hunt_target == target:
		hunt_target = null
	set_target(null)
	_chasing = false


## 그 거리(땅 위 px) 안에서 가장 가까운 야생 헨치. 없으면 null.
func _nearest_wild_within(max_distance: float) -> Unit:
	var wilds: Array[Unit] = []
	var points := PackedVector2Array()
	for node in get_tree().get_nodes_in_group(group_name(Team.WILD)):
		var wild := node as Unit
		if wild.is_alive():
			wilds.append(wild)
			points.append(wild.position)
	var index := Targeting.nearest_within(points, position, max_distance)
	return wilds[index] if index >= 0 else null


## 자동: 대상이 없으면 가장 가까운 야생 헨치를 대상으로 삼고, 다가가 공격한다(화면에서 지정한 몹이 있으면 그 몹부터).
func _hunt() -> void:
	if not _has_target():
		set_target(nearest_alive(Team.WILD))
	if not _has_target():
		return
	hunt_target = target
	if in_reach(target, stats.attack_range):
		face(target.position)
		try_attack(target)
	else:
		walk_to(target.position, stats.attack_range * 0.9)


## 공격 버튼: 대상에게 다가가 싸운다. 대상이 없으면 GameConfig.ATTACK_ASSIST_RANGE 안의 가장 가까운 적을 고른다.
func _engage() -> void:
	if not _has_target():
		set_target(_nearest_wild_within(GameConfig.ATTACK_ASSIST_RANGE))
	if _has_target():
		_chasing = true
		hunt_target = target


## 이동만 직접일 때: 사거리 안의 적을 알아서 공격한다(대상이 사거리 안이면 대상부터).
func _attack_nearby() -> void:
	var foe := target if _has_target() and in_reach(target, stats.attack_range) else _nearest_wild_within(stats.attack_range)
	if foe == null:
		return
	if foe != target:
		set_target(foe)
	hunt_target = foe
	try_attack(foe)


## 공격도 직접일 때: 대상이 사거리 안이면 공격한다.
func _attack_target() -> void:
	if _has_target() and in_reach(target, stats.attack_range):
		hunt_target = target
		try_attack(target)


## 그 자리로 순간이동한다. 카메라도 미끄러지지 않고 바로 따라온다.
func place_at(point: Vector2) -> void:
	super(point)
	_camera.reset_smoothing()


## 카메라가 보여 줄 수 있는 범위를 정한다.
func set_camera_limits(rect: Rect2) -> void:
	_camera.limit_left = floori(rect.position.x)
	_camera.limit_top = floori(rect.position.y)
	_camera.limit_right = ceili(rect.end.x)
	_camera.limit_bottom = ceili(rect.end.y)


func _on_died() -> void:
	hunt_target = null
	set_target(null)
	modulate.a = DOWNED_ALPHA


func _process(delta: float) -> void:
	if get_real_velocity().length() > 1.0:
		_walk_time += delta
	else:
		_walk_time = 0.0
	super(delta)


func body_center() -> Vector2:
	return BODY_CENTER


func overlay_height() -> float:
	return -HEAD_CENTER.y + HEAD_RADIUS + 6.0


func shows_hp_bar() -> bool:
	return true


func _draw() -> void:
	draw_colored_polygon(Shapes.ellipse(Vector2.ZERO, SHADOW_RADIUS), Palette.SHADOW)
	var lift := Vector2(0, -absf(sin(_walk_time * BOB_SPEED)) * BOB_HEIGHT) + _body_offset()

	var body := BODY_CENTER + lift
	draw_circle(body, BODY_RADIUS, Palette.HIT_FLASH if _is_flashing() else Palette.PLAYER_BODY, true, -1.0, true)
	draw_arc(body, BODY_RADIUS, 0.0, TAU, 32, Palette.OUTLINE, OUTLINE_WIDTH, true)

	# 머리: 위쪽(화면 위)을 보고 있으면 뒤통수(머리카락)만 보인다.
	var head := HEAD_CENTER + lift
	var facing_away := facing.y < -0.5
	draw_circle(head, HEAD_RADIUS, Palette.PLAYER_HAIR if facing_away else Palette.PLAYER_SKIN, true, -1.0, true)
	if not facing_away:
		draw_colored_polygon(Shapes.arc(head, HEAD_RADIUS, PI, TAU), Palette.PLAYER_HAIR)  # 앞머리
		var look := Vector2(facing.x * 5.0, 4.0)  # 눈은 바라보는 쪽으로 살짝 쏠린다
		draw_circle(head + look + Vector2(-EYE_GAP, 0), EYE_RADIUS, Palette.OUTLINE, true, -1.0, true)
		draw_circle(head + look + Vector2(EYE_GAP, 0), EYE_RADIUS, Palette.OUTLINE, true, -1.0, true)
	draw_arc(head, HEAD_RADIUS, 0.0, TAU, 32, Palette.OUTLINE, OUTLINE_WIDTH, true)

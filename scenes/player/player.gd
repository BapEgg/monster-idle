class_name Player
extends Unit
## 주인공. 사냥 방식(AutoControl.Mode, 화면 오른쪽 아래 버튼)에 따라 움직인다.
## - 풀오토: 자동 사냥. 키보드(WASD·방향키)나 가상 조이스틱을 만지는 동안은 수동이고,
##   손을 떼면 GameConfig.MANUAL_RETURN_SECONDS 뒤(기본 0 = 바로) 다시 자동 사냥으로 돌아온다.
## - 세미오토(그리고 풀오토에서 만지는 동안): 이동은 직접, 공격은 사거리 안에 들어온 야생 헨치를 자동으로 한다.
## - 수동: 이동은 직접, 공격은 공격 버튼(attack 액션: 화면 공격 버튼·Space)을 누르는 동안 사거리 안의 야생 헨치에게 한다.
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
## 지금 노리는 야생 헨치. 파티 헨치들이 이 대상을 돕는다.
var hunt_target: Unit

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
	if not control.is_manual():
		_hunt()
		return
	move_by_input(input)
	if control.auto_attacks():
		_attack_nearby()
	elif Input.is_action_pressed("attack"):
		_attack_on_button()


func is_manually_controlled() -> bool:
	return control.is_manual()


## 직접 조작 중에는 밀려나지 않는다(내가 누른 대로만 움직이게).
func _uses_personal_space() -> bool:
	return not control.is_manual()


## 이동 입력. 키보드와 가상 조이스틱이 같은 move_* 액션을 누르므로 여기서 한 번에 읽힌다.
## 길이 0~1, 화면 방향(위 = y 음수).
func read_move_input() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down", GameConfig.MOVE_DEADZONE)


## 자동: 노리는 대상이 없거나 쓰러졌으면 가장 가까운 야생 헨치를 새로 노리고, 다가가 공격한다.
func _hunt() -> void:
	if not is_instance_valid(hunt_target) or not hunt_target.is_alive():
		hunt_target = nearest_alive(Team.WILD)
	if hunt_target == null:
		return
	if in_reach(hunt_target, stats.attack_range):
		face(hunt_target.position)
		try_attack(hunt_target)
	else:
		walk_to(hunt_target.position, stats.attack_range * 0.9)


## 이동만 직접일 때: 사거리 안에 야생 헨치가 있으면 걸으면서 공격한다.
func _attack_nearby() -> void:
	var near := nearest_alive(Team.WILD)
	if near != null and in_reach(near, stats.attack_range):
		hunt_target = near
		try_attack(near)
	else:
		hunt_target = null


## 공격도 직접일 때(공격 버튼을 누르는 동안): 사거리 안의 가장 가까운 야생 헨치를 공격한다.
## 그 적을 노리는 대상으로 남겨 두어 헨치들이 돕는다(쓰러지면 풀린다).
func _attack_on_button() -> void:
	var near := nearest_alive(Team.WILD)
	if near != null and in_reach(near, stats.attack_range):
		hunt_target = near
		try_attack(near)


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

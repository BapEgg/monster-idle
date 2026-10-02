class_name Player
extends CharacterBody2D
## 주인공. 키보드(WASD·방향키)나 가상 조이스틱(HUD)으로 움직인다.
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
## 걸을 때 통통 튀는 높이(px)와 빠르기.
const BOB_HEIGHT := 3.0
const BOB_SPEED := 16.0

## 바라보는 화면 방향(길이 1). 머리·눈 그림에 쓴다.
var facing := Vector2.DOWN

var _walk_time := 0.0

@onready var _camera: Camera2D = $Camera2D


func _ready() -> void:
	_camera.zoom = Vector2.ONE * GameConfig.CAMERA_ZOOM
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = GameConfig.CAMERA_SMOOTHING_SPEED


func _physics_process(_delta: float) -> void:
	var input := read_move_input()
	velocity = Iso.move_velocity(input, GameConfig.PLAYER_SPEED, GameConfig.MOVE_VERTICAL_RATIO)
	move_and_slide()
	if input.length() > 0.1:
		facing = input.normalized()


func _process(delta: float) -> void:
	if get_real_velocity().length() > 1.0:
		_walk_time += delta
	else:
		_walk_time = 0.0
	queue_redraw()


## 이동 입력. 키보드와 가상 조이스틱이 같은 move_* 액션을 누르므로 여기서 한 번에 읽힌다.
## 길이 0~1, 화면 방향(위 = y 음수).
func read_move_input() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down", GameConfig.MOVE_DEADZONE)


## 그 자리로 순간이동한다. 카메라도 미끄러지지 않고 바로 따라온다.
func place_at(point: Vector2) -> void:
	position = point
	reset_physics_interpolation()
	_camera.reset_smoothing()


## 카메라가 보여 줄 수 있는 범위를 정한다.
func set_camera_limits(rect: Rect2) -> void:
	_camera.limit_left = floori(rect.position.x)
	_camera.limit_top = floori(rect.position.y)
	_camera.limit_right = ceili(rect.end.x)
	_camera.limit_bottom = ceili(rect.end.y)


func _draw() -> void:
	draw_colored_polygon(Shapes.ellipse(Vector2.ZERO, SHADOW_RADIUS), Palette.SHADOW)
	var lift := Vector2(0, -absf(sin(_walk_time * BOB_SPEED)) * BOB_HEIGHT)

	var body := BODY_CENTER + lift
	draw_circle(body, BODY_RADIUS, Palette.PLAYER_BODY, true, -1.0, true)
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

extends SceneTree
## 메인 장면을 실제로 띄워 주인공이 키보드·조이스틱(터치·마우스)으로 움직이는지 확인한다.
## 실행: <Godot 콘솔> --path <프로젝트> --script res://tests/smoke_main.gd [-- --shot=<png 경로>]
## 창이 잠깐 떴다 닫힌다. --shot 을 주면 조이스틱을 누른 순간의 화면을 PNG로 저장한다.

## 한 번에 걷는 물리 프레임 수(60프레임 = 1초).
const WALK_FRAMES := 30

var _failures := PackedStringArray()
var _joystick_down := false


func _initialize() -> void:
	# 검사 중에 실제 마우스·키보드가 끼어들지 않게 한다(창이 떠 있는 동안 사용자가 컴퓨터를 쓸 수 있다).
	# 마우스는 창을 통과하고(왼쪽 위 1px만 남김), 창은 키보드 포커스를 받지 않는다.
	DisplayServer.window_set_mouse_passthrough(PackedVector2Array([Vector2.ZERO, Vector2(1, 0), Vector2(0, 1)]))
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	_run.call_deferred(main)


func _run(main: Node) -> void:
	var player: Player = main.get_node("Field/Objects/Player")
	var joystick: VirtualJoystick = main.get_node("HUD/Joystick")
	joystick.pressed.connect(func() -> void: _joystick_down = true)
	joystick.released.connect(func(_v: Vector2) -> void: _joystick_down = false)
	await _physics_frames(10)
	var seconds := float(WALK_FRAMES) / Engine.physics_ticks_per_second
	var full_speed := GameConfig.PLAYER_SPEED * seconds
	var vertical_speed := full_speed * GameConfig.MOVE_VERTICAL_RATIO

	# 1) 키보드: 오른쪽 키 → 화면 오른쪽으로 제 속력
	var start := player.position
	Input.action_press("move_right")
	await _physics_frames(WALK_FRAMES)
	Input.action_release("move_right")
	var moved := player.position - start
	_expect(moved.x > full_speed * 0.8 and absf(moved.y) < 1.0, "오른쪽 키 → 오른쪽 %.0fpx쯤 (실제 %s)" % [full_speed, moved])

	# 2) 터치 조이스틱: 화면 왼쪽을 누르고 위로 끝까지 끌기 → 위로, 세로 비율만큼의 속력
	await _physics_frames(5)
	start = player.position
	_touch(true, Vector2(300, 560))
	_drag(Vector2(300, 260))
	await _physics_frames(WALK_FRAMES)
	moved = player.position - start
	_expect(_joystick_down, "왼쪽 화면 터치 → 조이스틱 눌림")
	_expect(moved.y < -vertical_speed * 0.8 and absf(moved.x) < 1.0, "조이스틱 위 → 위로 %.0fpx쯤 (실제 %s)" % [vertical_speed, moved])
	_expect(player.facing.y < -0.5, "위로 걸으면 뒤돌아 선다")

	var shot := _shot_path()
	if shot != "":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(shot)
		print("스크린샷: ", shot)

	_touch(false, Vector2(300, 260))
	await _physics_frames(3)
	_expect(not _joystick_down and player.read_move_input() == Vector2.ZERO, "손 떼면 멈춤")

	# 3) 마우스(PC 확인용): 왼쪽 버튼으로 누르고 왼쪽으로 끌기 → 왼쪽으로 이동
	start = player.position
	_mouse_button(true, Vector2(400, 500))
	_mouse_move(Vector2(150, 500))
	await _physics_frames(WALK_FRAMES)
	_mouse_button(false, Vector2(150, 500))
	moved = player.position - start
	_expect(moved.x < -full_speed * 0.8 and absf(moved.y) < 1.0, "마우스로 왼쪽 끌기 → 왼쪽으로 이동 (실제 %s)" % moved)
	await _physics_frames(3)
	_expect(player.read_move_input() == Vector2.ZERO, "마우스 떼면 멈춤")

	# 4) 오른쪽 화면은 조이스틱 영역이 아니다
	_touch(true, Vector2(1000, 400))
	_drag(Vector2(1000, 150))
	await _physics_frames(3)
	_expect(not _joystick_down and player.read_move_input() == Vector2.ZERO, "오른쪽 화면 터치 → 조이스틱 안 뜸")
	_touch(false, Vector2(1000, 150))

	for failure in _failures:
		printerr("실패: ", failure)
	print("스모크: 실패 %d개" % _failures.size())
	quit(1 if _failures.size() > 0 else 0)


func _expect(condition: bool, label: String) -> void:
	print(("통과: " if condition else "실패: ") + label)
	if not condition:
		_failures.append(label)


func _physics_frames(count: int) -> void:
	for i in count:
		await physics_frame


func _touch(pressed: bool, at: Vector2) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.pressed = pressed
	event.position = at
	Input.parse_input_event(event)


func _drag(to: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = 0
	event.position = to
	Input.parse_input_event(event)


func _mouse_button(pressed: bool, at: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	event.position = at
	event.global_position = at
	Input.parse_input_event(event)


func _mouse_move(to: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	event.position = to
	event.global_position = to
	Input.parse_input_event(event)


func _shot_path() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot="):
			return arg.trim_prefix("--shot=")
	return ""

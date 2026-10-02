extends SceneTree
## 메인 장면을 실제로 띄워 키보드·조이스틱(터치·마우스) 이동, 손대면 수동, 사냥 방식 버튼, 자동 사냥이 되는지 확인한다.
## 실행: <Godot 콘솔> --path <프로젝트> --script res://tests/smoke_main.gd [-- --shot=<png 경로>]
## 창이 20초쯤 떴다 닫힌다(자동 사냥은 시간을 4배로 돌린다). --shot 을 주면 싸우는 장면을 PNG로 저장한다.

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
	# 이동 검사(1~4) 동안은 야생 헨치를 치워 둔다. 손을 떼면 바로 자동 사냥이 시작돼
	# 주인공이 사냥감 쪽으로 움직이면 "누른 방향으로만 움직였나"를 잴 수 없기 때문이다. 6)에서 다시 풀어 놓는다.
	for node in get_nodes_in_group(&"wild"):
		node.remove_from_group(&"wild")
		node.queue_free()
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
	_expect(player.control.is_manual(), "조이스틱을 누르는 동안 = 수동")
	_expect(moved.y < -vertical_speed * 0.8 and absf(moved.x) < 1.0, "조이스틱 위 → 위로 %.0fpx쯤 (실제 %s)" % [vertical_speed, moved])
	_expect(player.facing.y < -0.5, "위로 걸으면 뒤돌아 선다")
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

	# 5) 손대면 수동: 만지는 동안 수동, 손을 떼면 MANUAL_RETURN_SECONDS 뒤(기본 0 = 바로) 자동
	await _physics_frames(5)
	_expect(not player.control.is_manual(), "아무것도 안 만지면 = 자동")
	Input.action_press("move_left")
	await _physics_frames(2)
	_expect(player.control.is_manual(), "키를 누르는 동안 = 수동")
	Input.action_release("move_left")
	await _physics_frames(ceili(GameConfig.MANUAL_RETURN_SECONDS * Engine.physics_ticks_per_second) + 2)
	var wait_text := "바로" if GameConfig.MANUAL_RETURN_SECONDS <= 0.0 else "%.0f초 뒤" % GameConfig.MANUAL_RETURN_SECONDS
	_expect(not player.control.is_manual(), "손 떼면 %s 자동" % wait_text)

	# 6) 사냥 방식 버튼: 세미오토 = 가까운 적은 알아서 공격, 수동 = 공격 버튼을 눌러야 공격
	#    내 헨치가 끼어들면 누가 때렸는지 가릴 수 없으므로 잠시 멈춰 둔다.
	var hud: Hud = main.get_node("HUD")
	_set_party_paused(main, true)
	_click(hud.mode_button(AutoControl.Mode.SEMI_AUTO))
	await _physics_frames(2)
	_expect(player.control.mode == AutoControl.Mode.SEMI_AUTO, "세미오토 버튼 → 세미오토")
	_expect(player.control.is_manual() and not hud.attack_button.visible, "세미오토: 안 만져도 이동은 직접, 공격 버튼 없음")
	start = player.position
	var wild := _spawn_wild(main, "sotmabaem", Vector2(40, 0), Vector2.RIGHT)
	await _physics_frames(10)
	_expect(wild.hp < wild.stats.max_hp, "세미오토: 사거리 안의 적은 알아서 공격")
	_expect(player.position.distance_to(start) < 1.0, "세미오토: 스스로 걸어가지 않음")
	_remove(wild)
	_click(hud.mode_button(AutoControl.Mode.MANUAL))
	await _physics_frames(2)
	_expect(player.control.mode == AutoControl.Mode.MANUAL and hud.attack_button.visible, "수동 버튼 → 수동, 공격 버튼이 보임")
	wild = _spawn_wild(main, "sotmabaem", Vector2(40, 0), Vector2.RIGHT)
	await _physics_frames(70)
	_expect(wild.hp == wild.stats.max_hp, "수동: 공격 버튼을 안 누르면 공격하지 않음")
	_touch(true, hud.attack_button.global_position)
	await _physics_frames(2)
	_expect(wild.hp < wild.stats.max_hp, "수동: 공격 버튼을 누르면 공격")
	_touch(false, hud.attack_button.global_position)
	_remove(wild)
	_click(hud.mode_button(AutoControl.Mode.FULL_AUTO))
	await _physics_frames(2)
	_expect(player.control.mode == AutoControl.Mode.FULL_AUTO and not hud.attack_button.visible, "풀오토 버튼 → 풀오토, 공격 버튼 숨김")
	_set_party_paused(main, false)

	# 7) 자동 사냥: 야생 헨치를 다시 풀고, 시간을 4배로 빨리 돌려 게임 시간 40초 동안 지켜본다
	(main.get_node("WildSpawner") as WildSpawner).setup(main.get_node("Field"), player)
	Engine.time_scale = 4.0
	var shot := _shot_path()
	var frames := int(40.0 * Engine.physics_ticks_per_second / Engine.time_scale)
	for i in frames:
		await physics_frame
		# 싸우는 장면 한 장: 주인공이 대상을 때리는 중이고 헨치도 싸움에 붙었을 때
		if shot != "" and i * 3 > frames and _is_brawling(player):
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(shot)
			print("스크린샷: ", shot)
			shot = ""
	Engine.time_scale = 1.0
	var kills: int = main.get("kills")
	_expect(kills >= 3, "자동 사냥 40초 → 3마리 이상 처치 (실제 %d)" % kills)
	for hench: Hench in main.get("party"):
		var near := Iso.ground_distance(hench.position, player.position) <= GameConfig.PARTY_LEASH
		_expect(near or not hench.is_alive(), "%s: 주인공 곁에 있음" % hench.display_name)

	for failure in _failures:
		printerr("실패: ", failure)
	print("스모크: 실패 %d개" % _failures.size())
	quit(1 if _failures.size() > 0 else 0)


func _is_brawling(player: Player) -> bool:
	if not is_instance_valid(player.hunt_target) or not player.in_reach(player.hunt_target, player.stats.attack_range):
		return false
	for node in get_nodes_in_group(&"wild"):
		if (node as Hench).is_fighting():
			return true
	return false


## 검사용 야생 헨치를 주인공 곁(offset, 화면 px)에 세운다. look = 바라보는 방향.
## 돌아다니지 않게 해 둔다(바라보는 방향이 바뀌지 않게).
func _spawn_wild(main: Node, id: String, offset: Vector2, look: Vector2) -> Hench:
	var player: Player = main.get_node("Field/Objects/Player")
	var wild := Hench.create(HenchDb.get_species(id), Unit.Team.WILD)
	wild.field = main.get_node("Field")
	wild.home = player.position + offset
	wild.position = wild.home
	wild.facing = look
	main.get_node("Field/Objects").add_child(wild)
	wild.reset_physics_interpolation()
	wild.hold_still = true
	return wild


func _remove(unit: Unit) -> void:
	unit.remove_from_group(Unit.group_name(unit.team))
	unit.queue_free()


func _set_party_paused(main: Node, stop: bool) -> void:
	for hench: Hench in main.get("party"):
		hench.process_mode = Node.PROCESS_MODE_DISABLED if stop else Node.PROCESS_MODE_INHERIT


## 마우스로 버튼 한가운데를 눌렀다 뗀다.
func _click(control: Control) -> void:
	var at := control.get_global_rect().get_center()
	_mouse_button(true, at)
	_mouse_button(false, at)


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

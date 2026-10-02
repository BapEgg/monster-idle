extends SceneTree
## 메인 장면을 실제로 띄워 키보드·조이스틱(터치·마우스) 이동, 손대면 수동, 오토 버튼·공격 버튼,
## 몹을 눌러 대상 지정, 선공 감지·기습, 자동 사냥이 되는지 확인한다.
## 실행: <Godot 콘솔> --path <프로젝트> --script res://tests/smoke_main.gd [-- --shot=<png 경로>]
## 창이 30초쯤 떴다 닫힌다(자동 사냥은 시간을 4배로 돌린다).
## --shot 을 주면 싸우는 장면을 그 경로에, 대상을 지정한 장면을 "<이름>_target.png",
## 감지 전구가 차오르는 장면을 "<이름>_detect.png", 가방 창을 "<이름>_bag.png"로 저장한다.

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

	# 6) 오토 버튼(공격 버튼 위): 누를 때마다 풀오토 → 세미오토 → 수동. 공격 버튼은 늘 보인다.
	#    내 헨치가 끼어들면 누가 때렸는지 가릴 수 없으므로 잠시 멈춰 둔다.
	var hud: Hud = main.get_node("HUD")
	_set_party_paused(main, true)
	_expect(player.control.mode == AutoControl.Mode.FULL_AUTO and hud.attack_button.visible, "풀오토에서도 공격 버튼이 보임")
	await _tap(hud.auto_button.global_position)
	_expect(player.control.mode == AutoControl.Mode.SEMI_AUTO and hud.auto_button.mode == AutoControl.Mode.SEMI_AUTO, "오토 버튼 → 세미오토")
	_expect(player.control.is_manual(), "세미오토: 안 만져도 이동은 직접")
	start = player.position
	var wild := _spawn_wild(main, "sotmabaem", Vector2(40, 0), Vector2.RIGHT)
	await _physics_frames(10)
	_expect(wild.hp < wild.stats.max_hp and player.target == wild, "세미오토: 사거리 안의 적은 알아서 공격하고 대상이 됨")
	_expect(player.position.distance_to(start) < 1.0, "세미오토: 스스로 걸어가지 않음")
	_remove(wild)
	await _tap(hud.auto_button.global_position)
	_expect(player.control.mode == AutoControl.Mode.MANUAL and hud.attack_button.visible, "오토 버튼 → 수동")
	# 수동: 공격 버튼은 사거리 밖의 적에게도 다가가 공격한다(사용자 피드백: 다가가기 전에는 아무 일도 없었음)
	wild = _spawn_wild(main, "sotmabaem", Vector2(220, 0), Vector2.RIGHT)
	await _physics_frames(70)
	_expect(wild.hp == wild.stats.max_hp and player.target == null, "수동: 공격 버튼을 안 누르면 아무것도 안 함")
	start = player.position
	await _tap(hud.attack_button.global_position)
	_expect(player.target == wild, "수동: 공격 버튼 → 가까운 적이 대상이 됨")
	await _seconds(2.0)
	_expect(wild.hp < wild.stats.max_hp, "수동: 공격 버튼을 한 번 누르면 다가가 공격 (%.0fpx 걸어감)" % player.position.distance_to(start))
	_remove(wild)
	await _physics_frames(2)
	_expect(player.target == null, "대상이 사라지면 대상 창도 비움")
	# 몹을 눌러 대상 지정: 화면 왼쪽(조이스틱 영역)의 몹을 눌러도 조이스틱 대신 대상 지정
	wild = _spawn_wild(main, "gochuryong", Vector2(-260, -40), Vector2.LEFT)
	var other := _spawn_wild(main, "sotmabaem", Vector2(200, 40), Vector2.RIGHT)
	await _physics_frames(2)
	var at := _screen_of(wild)
	await _tap(at)
	await process_frame  # 대상 창은 화면 프레임(_process)에서 바뀐다
	_expect(at.x < get_root().get_visible_rect().size.x * 0.5 and player.target == wild and not _joystick_down, "화면 왼쪽의 몹을 누르면 조이스틱 대신 대상 지정")
	_expect(hud.target_frame.visible and hud.target_frame.unit == wild, "화면 위 대상 창에 그 몹이 보임")
	_expect(wild.targeted and wild.shows_hp_bar(), "대상은 발밑 고리, 다치지 않아도 머리 위 체력 바")
	await _save_shot("target")
	at = _screen_of(other)
	_mouse_button(true, at)
	_mouse_button(false, at)
	await _physics_frames(2)
	_expect(player.target == other and not wild.targeted, "마우스로 다른 몹을 클릭 → 대상이 바뀜")
	_remove(wild)
	# 더블 탭: 한 번 누르면 지정만, 같은 몹을 빨리 두 번 누르면 공격 버튼 없이 다가가 공격
	await _seconds(GameConfig.DOUBLE_TAP_SECONDS + 0.1)
	start = player.position
	await _tap(_screen_of(other))
	await _seconds(GameConfig.DOUBLE_TAP_SECONDS + 0.1)
	_expect(player.target == other and other.hp == other.stats.max_hp and player.position.distance_to(start) < 1.0, "몹을 한 번 누르면 지정만(공격 안 함)")
	await _tap(_screen_of(other))
	await _tap(_screen_of(other))
	await _seconds(2.0)
	_expect(other.hp < other.stats.max_hp, "같은 몹을 두 번 누르면 바로 다가가 공격")
	_remove(other)
	await _switch_mode(hud, player, AutoControl.Mode.FULL_AUTO)
	_expect(player.control.mode == AutoControl.Mode.FULL_AUTO, "오토 버튼 → 다시 풀오토")

	# 7) 선공 감지 · 기습(프로토타입 3). 주인공은 수동으로 가만히 세워 두고, 내 헨치는 멈춰 둔다.
	await _switch_mode(hud, player, AutoControl.Mode.MANUAL)
	# 정면: 고추룡(선공)이 주인공 쪽(왼쪽)을 보고 있으면 금방 알아채고 덤빈다
	wild = _spawn_wild(main, "gochuryong", Vector2(200, 0), Vector2.LEFT)
	await _seconds(GameConfig.DETECT_FRONT_SECONDS * 0.5)
	_expect(wild.name_color() == Palette.NAME_AGGRESSIVE, "선공 = 빨간 이름표")
	_expect(wild.mark() == Unit.Mark.DETECTING and wild.detect_ratio() > 0.2, "정면: 전구가 차오름 (%.2f)" % wild.detect_ratio())
	await _seconds(GameConfig.DETECT_FRONT_SECONDS * 0.5 + 0.1)
	_expect(not wild.is_unaware() and wild.mark() == Unit.Mark.ALERT, "정면: %.1f초 만에 알아채고 덤빔(\"!\")" % GameConfig.DETECT_FRONT_SECONDS)
	# 추격 포기: 자기 자리에서 너무 멀어지면 포기하고 돌아간다
	wild.home = wild.position + Vector2(GameConfig.WILD_LEASH + 100.0, 0)
	await _physics_frames(3)
	_expect(wild.mark() == Unit.Mark.GIVE_UP and not wild.is_fighting(), "너무 멀리 쫓아가면 포기(파란 표시)")
	_remove(wild)
	# 등 뒤: 반대쪽을 보고 있으면 오래 있어도 못 알아챈다
	wild = _spawn_wild(main, "gochuryong", Vector2(200, 0), Vector2.RIGHT)
	await _seconds(GameConfig.DETECT_SIDE_SECONDS + 0.5)
	_expect(wild.is_unaware() and wild.mark() == Unit.Mark.NONE, "등 뒤: %.1f초가 지나도 못 알아챔" % (GameConfig.DETECT_SIDE_SECONDS + 0.5))
	_remove(wild)
	# 주변시: 옆(화면 위쪽)을 보고 있으면 늦게 알아챈다
	wild = _spawn_wild(main, "gochuryong", Vector2(200, 0), Vector2.UP)
	await _seconds(GameConfig.DETECT_FRONT_SECONDS + 0.2)
	_expect(wild.is_unaware() and wild.mark() == Unit.Mark.DETECTING, "주변시: 정면보다 늦게 차오름 (%.2f)" % wild.detect_ratio())
	await _save_shot("detect")
	await _seconds(GameConfig.DETECT_SIDE_SECONDS - GameConfig.DETECT_FRONT_SECONDS)
	_expect(not wild.is_unaware(), "주변시: %.1f초쯤 지나면 알아챔" % GameConfig.DETECT_SIDE_SECONDS)
	_remove(wild)
	# 기습: 수동 중에, 아직 알아채지 못한 적에게 넣은 첫 타는 배율만큼 세다. 맞은 비선공은 "!" 하고 반격한다.
	var hit := player.stats.attack
	wild = _spawn_wild(main, "sotmabaem", Vector2(40, 0), Vector2.RIGHT)
	await _physics_frames(2)
	Input.action_press("attack")
	await _physics_frames(2)
	Input.action_release("attack")
	var lost := wild.stats.max_hp - wild.hp
	_expect(is_equal_approx(lost, hit * GameConfig.AMBUSH_SCALE), "수동: 알아채기 전 첫 타 = 기습 %.1f배 (%.0f → %.0f)" % [GameConfig.AMBUSH_SCALE, hit, lost])
	_expect(wild.mark() == Unit.Mark.ALERT and not wild.is_unaware(), "비선공: 맞으면 \"!\" 하고 반격")
	Input.action_press("attack")
	await _seconds(player.stats.attack_interval + 0.1)
	Input.action_release("attack")
	lost = wild.stats.max_hp - wild.hp - lost
	_expect(is_equal_approx(lost, hit), "두 번째 타부터는 보통 (%.0f)" % lost)
	_remove(wild)
	# 자동 사냥(풀오토)은 기습 보너스가 없다(손해가 아니라 보너스가 없을 뿐)
	await _switch_mode(hud, player, AutoControl.Mode.FULL_AUTO)
	await _seconds(player.stats.attack_interval)
	wild = _spawn_wild(main, "sotmabaem", Vector2(40, 0), Vector2.RIGHT)
	for i in 120:
		await physics_frame
		if wild.hp < wild.stats.max_hp:
			break
	lost = wild.stats.max_hp - wild.hp
	_expect(is_equal_approx(lost, hit), "풀오토: 알아채기 전이어도 첫 타는 보통 (%.0f)" % lost)
	_remove(wild)
	_set_party_paused(main, false)

	# 8) 코어 드랍 · 가방(프로토타입 4): 떨어진 코어는 튀어 올랐다 땅에 머물고, 주인공에게 빨려 들어가 가방에 들어간다
	var bag: Bag = main.get("bag")
	var before := bag.count()
	var core := CoreItem.new()
	core.species_id = "gochuryong"
	core.suffix_id = "mighty"
	core.age = CoreItem.Age.OLD
	core.shining = true
	main.call("drop_core", player.position + Vector2(160, 0), core)
	var drop := _find_drop(main)
	await _seconds(GameConfig.CORE_POP_SECONDS * 0.5)
	_expect(drop != null and drop.height() > GameConfig.CORE_POP_HEIGHT * 0.5, "코어가 몹 자리에서 튀어 오름")
	await _seconds(GameConfig.CORE_POP_SECONDS * 0.5 + GameConfig.CORE_REST_SECONDS * 0.5)
	_expect(is_instance_valid(drop) and drop.height() == 0.0 and bag.count() == before, "땅에 떨어져 잠깐 머묾(아직 가방 밖)")
	await _seconds(GameConfig.CORE_REST_SECONDS + 1.0)
	_expect(not is_instance_valid(drop) and bag.count() == before + 1, "주인공에게 빨려 들어가 가방에 들어감")
	_expect(bag.cores.back().to_dict() == core.to_dict(), "가방의 코어 = 떨어진 코어(종·접미사·나이·빛남)")
	# 가방 창: 가방 버튼 → 열림(코어 수만큼 칸), 창 위를 눌러도 주인공이 움직이지 않음, 닫기 → 닫힘
	await _tap(hud.bag_button.global_position)
	await process_frame
	_expect(hud.bag_panel.visible and hud.bag_panel.card_count() == bag.count(), "가방 버튼 → 가방 창, 코어 %d칸" % bag.count())
	# 목록(스크롤) 위를 끌면 목록이 굴러가서, 그다음 누름은 굴러가기를 멈추는 데 쓰인다(휴대폰과 같음). 그래서 위쪽 글자 칸에서 끈다.
	var on_panel := hud.bag_panel.get_global_rect().position + Vector2(40, 70)
	start = player.position
	_touch(true, on_panel)
	_drag(on_panel + Vector2(-80, 0))
	await _physics_frames(10)
	_touch(false, on_panel + Vector2(-80, 0))
	_expect(not _joystick_down and player.position.distance_to(start) < 1.0, "가방 창 위를 끌어도 조이스틱이 뜨지 않음")
	await _save_shot("bag")
	await _seconds(0.2)  # 사진 저장으로 멈췄던 프레임이 따라잡은 뒤에 누른다(누름과 뗌이 한꺼번에 들어가지 않게)
	var close := hud.bag_panel.find_child("Close", true, false) as Button
	await _tap(close.get_global_rect().get_center())
	await process_frame
	_expect(not hud.bag_panel.visible and hud.joystick.visible, "닫기 → 가방 창 닫힘, 조이스틱 다시 보임")

	# 9) 자동 사냥: 야생 헨치를 다시 풀고, 시간을 4배로 빨리 돌려 게임 시간 40초 동안 지켜본다
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
	var hunt_log: HuntLog = main.get("hunt_log")
	_expect(hunt_log.kills() == kills and hunt_log.kills_per_hour(false) > 0.0, "사냥 기록: 처치 %d · 자동 시간당 %.0f마리" % [hunt_log.kills(), hunt_log.kills_per_hour(false)])
	await _seconds(GameConfig.CORE_POP_SECONDS + GameConfig.CORE_REST_SECONDS + 1.0)
	_expect(bag.count() - before - 1 == hunt_log.cores - 1 and hunt_log.cores >= 1, "자동 사냥 중 떨어진 코어도 가방에 (%d개)" % (hunt_log.cores - 1))
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


## 화면 그 자리를 손가락으로 톡 누른다.
func _tap(at: Vector2) -> void:
	_touch(true, at)
	await _physics_frames(2)
	_touch(false, at)
	await _physics_frames(2)


## 오토 버튼을 눌러 원하는 사냥 방식으로 바꾼다(누를 때마다 다음 방식).
func _switch_mode(hud: Hud, player: Player, mode: AutoControl.Mode) -> void:
	for i in AutoControl.Mode.size():
		if player.control.mode == mode:
			return
		await _tap(hud.auto_button.global_position)


## 필드에 있는 떨어진 코어(가장 최근 것). 없으면 null.
func _find_drop(main: Node) -> CoreDrop:
	var found: CoreDrop = null
	for child in main.get_node("Field/Objects").get_children():
		if child is CoreDrop:
			found = child
	return found


## 유닛 몸 가운데의 화면 좌표(누를 자리).
func _screen_of(unit: Unit) -> Vector2:
	return unit.get_viewport().get_canvas_transform() * (unit.global_position + unit.body_center())


func _expect(condition: bool, label: String) -> void:
	print(("통과: " if condition else "실패: ") + label)
	if not condition:
		_failures.append(label)


func _physics_frames(count: int) -> void:
	for i in count:
		await physics_frame


func _seconds(seconds: float) -> void:
	await _physics_frames(ceili(seconds * Engine.physics_ticks_per_second))


## --shot 경로 이름 뒤에 _<suffix>를 붙여 지금 화면을 저장한다(--shot 이 없으면 넘어간다).
func _save_shot(suffix: String) -> void:
	var path := _shot_path()
	if path == "":
		return
	path = path.get_basename() + "_" + suffix + "." + path.get_extension()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
	print("스크린샷: ", path)


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

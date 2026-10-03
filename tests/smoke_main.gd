extends SceneTree
## 메인 장면을 실제로 띄워 키보드·조이스틱(터치·마우스) 이동, 손대면 수동, 오토 버튼·공격 버튼,
## 몹을 눌러 대상 지정, 선공 감지·기습, 자동 사냥, 가방·믹스, 보스전(장판·지휘), 저장하고 다시 켜기가 되는지 확인한다.
## 실행: <Godot 콘솔> --path <프로젝트> --script res://tests/smoke_main.gd [-- --shot=<png 경로>]
## 창이 30초쯤 떴다 닫힌다(자동 사냥은 시간을 4배로 돌린다).
## --shot 을 주면 싸우는 장면을 그 경로에, 대상을 지정한 장면을 "<이름>_target.png",
## 감지 전구가 차오르는 장면을 "<이름>_detect.png", 가방 창을 "<이름>_bag.png", 믹스창을 "<이름>_mix.png",
## 믹스 결과 카드를 "<이름>_mix_result.png", 변이 코어 정보창을 "<이름>_variant.png",
## 스킬(기절 별 · 보호막 · 스킬 칸 대기 시간)을 "<이름>_skills.png", 디버그 화면을 "<이름>_debug.png",
## 보스전 장판을 "<이름>_boss.png", 지휘(원거리조 버티기)를 "<이름>_boss_command.png"로 저장한다.

## 한 번에 걷는 물리 프레임 수(60프레임 = 1초).
const WALK_FRAMES := 30
const MAIN_SCENE := "res://scenes/main/main.tscn"
## 실행 검사 전용 저장 파일(사용자의 진짜 저장 user://save.json을 건드리지 않는다). 시작할 때 지워 처음 켠 상태로 시작한다.
const SMOKE_SAVE_PATH := "user://smoke_save.json"

var _failures := PackedStringArray()
var _joystick_down := false


func _initialize() -> void:
	# 검사 중에 실제 마우스·키보드가 끼어들지 않게 한다(창이 떠 있는 동안 사용자가 컴퓨터를 쓸 수 있다).
	# 마우스는 창을 통과하고(왼쪽 위 1px만 남김), 창은 키보드 포커스를 받지 않는다.
	DisplayServer.window_set_mouse_passthrough(PackedVector2Array([Vector2.ZERO, Vector2(1, 0), Vector2(0, 1)]))
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
	var store := LocalSaveStore.new(SMOKE_SAVE_PATH)
	store.erase()
	var main: Node = load(MAIN_SCENE).instantiate()
	main.set("save_store", store)
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

	# 7-2) 스킬(헨치 고유 액티브): 스킬 칸 1~3 = 파티 헨치 스킬, 4~6 = 빈 칸(주인공 직업 스킬 자리).
	#      수동·세미오토에서는 칸을 눌러야 쓰고, 풀오토는 알아서 쓴다.
	var squad: Array = main.get("party")
	var slots_ok := true
	for i in 3:
		slots_ok = slots_ok and hud.skill_slot(i).skill != null and hud.skill_slot(i).skill == (squad[i] as Hench).skill
	_expect(slots_ok and hud.skill_slot(3).skill == null and hud.skill_slot(5).skill == null, "스킬 칸 1~3 = 파티 헨치 스킬, 4~6 = 빈 칸")
	await _switch_mode(hud, player, AutoControl.Mode.MANUAL)
	var tank := squad[0] as Hench
	var shooter := squad[1] as Hench
	wild = _spawn_wild(main, "sotmabaem", Vector2(60, 10), Vector2.RIGHT)
	await _seconds(1.5)
	_expect(tank.skill_casts == 0 and shooter.skill_casts == 0 and tank.skill.is_ready(), "수동: 스킬을 알아서 쓰지 않음")
	await _tap(hud.skill_slot(0).global_position)
	await _physics_frames(3)
	_expect(tank.skill_casts == 1 and tank.shield > 0.0, "%s 칸을 누름 → %s(도발 + 보호막 %d)" % [tank.species.name, tank.skill.title, roundi(tank.shield)])
	_expect(wild.fight_target() == tank, "도발: 곁의 야생이 탱커를 노림")
	await _tap(hud.skill_slot(1).global_position)
	await _physics_frames(3)
	_expect(shooter.skill_casts == 1 and not shooter.skill.is_ready() and hud.skill_slot(1).skill.left > 0.0, "%s 칸을 누름 → %s, 칸에 대기 시간" % [shooter.species.name, shooter.skill.title])
	_remove(wild)
	# 기절: 돌구아나(꼬리 내려찍기 = 기절) 코어를 1번 자리에 넣고, 멀리 있는 몹에게 눌러 쓰면 다가가서 쓴다
	var stunner := _find_core(main.get("bag"), "dolguana", CoreItem.Gender.MALE)
	main.call("assign_party", stunner, 0)
	await _physics_frames(2)
	var dol := (main.get("party") as Array)[0] as Hench
	wild = _spawn_wild(main, "haemapo", Vector2(-160, 60), Vector2.LEFT)
	await _physics_frames(2)
	await _tap(hud.skill_slot(0).global_position)
	for i in 180:
		await physics_frame
		if dol.skill_casts > 0:
			break
	_expect(dol.skill_casts == 1 and wild.is_stunned() and wild.mark() == Unit.Mark.STUNNED, "멀리 있는 몹 → 다가가서 %s, 맞은 몹은 기절(별)" % dol.skill.title)
	await _physics_frames(10)
	await _save_shot("skills")
	await _seconds(0.2)
	_remove(wild)
	main.call("leave_party", stunner)
	await _switch_mode(hud, player, AutoControl.Mode.FULL_AUTO)

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
	# 가방 칸 → 오른쪽 정보창, 잠금, 파티 편성, 분해, 믹스(프로토타입 5). 시작 가방(data/dev_starter.json)의 코어로 한다.
	var info := hud.bag_panel.info()
	var gochu := _find_core(bag, "gochuryong", CoreItem.Gender.FEMALE)
	await _tap(hud.bag_panel.card_for(gochu).get_global_rect().get_center())
	_expect(info.item == gochu and hud.bag_panel.card_for(gochu).selected, "가방 칸을 누르면 오른쪽 정보창에 그 코어")
	await _tap(_center_of(info, "Lock"))
	var locked_once := gochu.locked
	await _tap(_center_of(info, "Lock"))
	_expect(locked_once and not gochu.locked, "잠금 → 잠김, 다시 누르면 풀림")
	await _tap(_center_of(info, "Party"))
	await process_frame
	var first_slot := (info.find_child("PartySlots", true, false) as HBoxContainer).get_child(0) as Button
	await _tap(first_slot.get_global_rect().get_center())
	await _physics_frames(2)
	var party: Array = main.get("party")
	_expect(gochu.party_slot == 0 and (party[0] as Hench).species.id == "gochuryong", "파티 편성 → 1번 자리 헨치가 고추룡으로 바뀜")
	var core_stats := UnitStats.from_core(gochu)
	var fighter := party[0] as Hench
	_expect(is_equal_approx(fighter.stats.max_hp, core_stats.max_hp) and is_equal_approx(fighter.stats.attack, core_stats.attack) and fighter.level == gochu.level, "파티 헨치가 코어 능력치로 싸운다(체력 %d · 공격 %d · LV %d)" % [roundi(fighter.stats.max_hp), roundi(fighter.stats.attack), fighter.level])
	var other_stat := "lucky" if gochu.suffix_id != "lucky" else "swift"
	_expect(info.stat_value_label(gochu.suffix_id).get_theme_color("font_color") == Palette.STAT_ACCENT and info.stat_value_label(other_stat).get_theme_color("font_color") == Palette.TEXT, "정보창 능력치 표: 접미사로 강한 능력치만 강조색")
	await _tap(_center_of(info, "Party"))
	await _physics_frames(2)
	party = main.get("party")
	_expect(not gochu.in_party() and (party[0] as Hench).species.id == GameConfig.PARTY_HENCHES[0], "파티에서 빼기 → 처음 헨치로 돌아감")
	var wallet: Wallet = main.get("wallet")
	var owl := _find_core(bag, "mangwonbueong", CoreItem.Gender.FEMALE)
	await _tap(hud.bag_panel.card_for(owl).get_global_rect().get_center())
	var count_before := bag.count()
	var shards_before := wallet.shards
	await _tap(_center_of(info, "Dismantle"))
	_expect(hud.confirm_box.visible, "분해 → 확인 창")
	await _tap(_center_of(hud.confirm_box, "Yes"))
	_expect(not bag.has(owl) and bag.count() == count_before - 1 and wallet.shards == shards_before + Mix.dismantle_shards(owl), "분해 → 가방에서 빠지고 코어 조각 +%d" % Mix.dismantle_shards(owl))
	await _tap(hud.bag_panel.card_for(gochu).get_global_rect().get_center())
	await _tap(_center_of(info, "MixButton"))
	var mixer := hud.mix_panel
	var mix_info := mixer.info()
	_expect(mixer.visible and mixer.main_core == gochu and mixer.get_global_rect().size == root.get_visible_rect().size, "믹스 → 믹스창(화면 전체), 주 칸 = 고른 코어")
	_expect(mix_info.item == gochu and not (mix_info.find_child("Buttons", true, false) as Control).visible, "오른쪽 정보창 = 가방 정보창 재사용(주 코어 상세, 버튼은 숨김)")
	_expect(not (mixer.find_child("Title", true, false) as Label).text.contains("→"), "위쪽 공식 문구 없음")
	# 재료 목록: 주 코어 자신 · 같은 성별 · 잠금 · 변이는 흐리게 + 까닭
	var kkang := _find_core(bag, "kkangtonggeobuk", CoreItem.Gender.MALE)
	var jinju := _find_core(bag, "jinjuryong", CoreItem.Gender.FEMALE)
	var mutant0 := _find_core(bag, "haemapo", CoreItem.Gender.MALE)
	_expect(mixer.material_card(gochu).block_reason == UiText.MIX_MATERIAL_REASONS[Mix.Problem.SAME_CORE] and mixer.material_card(jinju).block_reason != "" and mixer.material_card(mutant0).block_reason == UiText.VARIANT and mixer.material_card(kkang).block_reason == "", "재료 목록: 고를 수 없는 코어는 흐리게 + 까닭(주 코어 · 잠금/같은 성별 · 변이)")
	await _tap(mixer.material_card(jinju).get_global_rect().get_center())
	_expect(mix_info.item == jinju and mixer.sub_core == null, "흐린 재료를 누르면 상세만 보이고 칸에는 안 들어감")
	await _tap(mixer.material_card(kkang).get_global_rect().get_center())
	_expect(mixer.sub_core == kkang and mix_info.item == kkang and mixer.result_name_text() == "돌구아나", "재료를 누름 → 보조 칸 + 오른쪽에 그 코어 상세, 결과 칸 = 돌구아나(공개)")
	_expect(mixer.chance_text() == UiText.MIX_CHANCE % (UiText.PERCENT % 85), "성공 확률 숫자 하나: 85%(하급→중급 기본, 숙련 1단계)")
	var swapped_name := "기관코끼리" if Mix.reveal_of("gigwankokkiri") == Mix.Reveal.OPEN else UiText.MIX_SECRET
	_expect(mixer.swap_result_text() == UiText.MIX_SWAP_RESULT % swapped_name, "⇄ 옆: %s" % mixer.swap_result_text())
	_expect(mixer.material_side() >= 92.0 and mixer.material_card(kkang).selected, "재료 칸 %d px, 고른 칸 표시" % mixer.material_side())
	var workshop: Workshop = main.get("workshop")
	_expect((mixer.find_child("WarningBig", true, false) as Control).visible and not (mixer.find_child("WarningSmall", true, false) as Control).visible, "처음에는 실패 경고가 크게")
	await _tap(_center_of(mixer, "Chance"))
	_expect(mixer.is_showing_chance_tip() and mixer.chance_tip_text() == UiText.MIX_CHANCE_TIP % [85, 0, 0], "성공 확률을 누름 → 내역 말풍선(기본 + 숙련 + 마크)")
	await _tap(_center_of(mixer, "ResultSlot"))
	var preview := mix_info.preview_values()
	_expect(mix_info.previewing and preview.size() == UiText.MIX_PREVIEW_CAPTIONS.size() and preview[0] == UiText.MIX_PREVIEW_LEVEL % 18, "결과 칸을 누름 → 정보창에 미리보기(%s)" % " · ".join(preview))
	await _save_shot("mix")
	await _seconds(0.2)
	# 숙련 ⓘ → 숙련 창(단계별 성공 확률 보너스 표 + 지금 경험치)
	await _tap(_center_of(mixer, "MasteryButton"))
	_expect(mixer.is_showing_mastery() and mixer.mastery_row_texts(1) == PackedStringArray([UiText.MIX_MASTERY_STEP % 1, UiText.MIX_MASTERY_BONUS % 0, "30"]) and mixer.mastery_row_texts(9)[1] == UiText.MIX_MASTERY_BONUS % 16, "숙련 ⓘ → 숙련 창(1단계 +0% … 9단계 +16%)")
	await _save_shot("mix_mastery")
	await _seconds(0.2)
	await _tap(_center_of(mixer, "MasteryClose"))
	# 레시피 → 재료가 있는 공식을 누르면 칸이 채워진다
	await _tap(_center_of(mixer, "RecipeButton"))
	var recipe_button: Button = null
	for row: Button in mixer.find_child("RecipeList", true, false).get_children():
		if row.text.begins_with("고추룡 + 깡통거북"):
			recipe_button = row
	_expect(mixer.is_showing_recipes() and mixer.recipe_rows() > 0 and recipe_button != null and not recipe_button.disabled, "레시피 창: 공식 %d개, 고추룡 + 깡통거북은 재료 있음" % mixer.recipe_rows())
	await _save_shot("mix_recipes")
	await _seconds(0.2)
	await _tap(recipe_button.get_global_rect().get_center())
	_expect(not mixer.is_showing_recipes() and mixer.main_core.species_id == "gochuryong" and mixer.sub_core.species_id == "kkangtonggeobuk", "공식을 누름 → 주 고추룡 · 보조 깡통거북이 채워짐")
	mixer.main_core = gochu  # 아래 검사가 쓰는 그 코어로 맞춘다
	mixer.sub_core = kkang
	mixer.refresh()
	# 종족 필터: 용족만
	var tribe_filter := mixer.find_child("TribeFilter", true, false) as OptionButton
	tribe_filter.select(1 + HenchSpecies.TRIBES.find("dragon"))
	tribe_filter.item_selected.emit(tribe_filter.selected)
	var only_dragon := true
	for card: CoreCard in mixer.find_child("Materials", true, false).get_children():
		only_dragon = only_dragon and card.item.species().tribe == "dragon"
	_expect(only_dragon and mixer.material_card(kkang) == null, "종족 필터(용족) → 용족 코어만")
	tribe_filter.select(0)
	tribe_filter.item_selected.emit(0)
	# ⇄: 주 깡통거북 + 보조 고추룡 → 기관코끼리(초안 공식, 시작 가방에 없는 종이라 성공하면 NEW)
	await _tap(_center_of(mixer, "Swap"))
	_expect(mixer.main_core == kkang and mixer.result_name_text() == "기관코끼리 " + UiText.MIX_DRAFT, "⇄ → 다른 공식: 기관코끼리(초안 공식)")
	count_before = bag.count()
	var gold_before := wallet.gold
	await _tap(_center_of(mixer, "Go"))
	_expect(not hud.confirm_box.visible, "보통 재료는 확인 창 없이 바로 연성")
	var flying := (mixer.find_child("FxLayer", true, false) as Control).get_child_count()
	_expect(flying == (2 if mixer.last_born != null else 0), "성공이면 두 재료가 결과 플라스크로 모이는 연출(%d개)" % flying)
	await _seconds(GameConfig.MIX_FX_GATHER_SECONDS + GameConfig.MIX_FX_POP_SECONDS + 0.2)
	var born := mixer.last_born
	_expect(mixer.is_showing_result() and not bag.has(gochu) and not bag.has(kkang) and bag.count() == count_before - (1 if born != null else 2), "연성 → 재료 둘이 사라지고 결과 카드(%s)" % ("성공" if born != null else "실패"))
	_expect(wallet.gold == gold_before - Mix.gold_cost("gigwankokkiri") and workshop.mastery.exp_points > 0, "골드가 비용만큼 나가고 숙련 경험치가 오름")
	var card_texts := mixer.result_card_texts()
	_expect(workshop.last_mix_exp > 0 and card_texts[4].contains("+%d" % workshop.last_mix_exp), "결과 카드: 얻은 숙련 경험치 (%s)" % card_texts[4].replace("\n", " / "))
	if born != null:
		_expect(born.species_id == "gigwankokkiri" and mixer.find_child("NewBadge", true, false).visible and born.inherit_stat == "mighty", "성공: NEW · 도감 등록, 계승 스탯 = 보조(고추룡) 접미사의 공격")
		_expect(card_texts[1].contains(UiText.ROLE_NAMES[born.species().role]) and card_texts[3].begins_with(UiText.MIX_CHOSEN % "") and born.passive_owner_id() == born.species_id, "성공 카드: 종족·역할·등급(%s), 패시브는 먼저 자기 것(체크)" % card_texts[1])
		await _tap(mixer.passive_choice(1).get_global_rect().get_center())
		_expect(born.passive_owner_id() == "kkangtonggeobuk" and mixer.result_card_texts()[3].contains(HenchDb.get_species("kkangtonggeobuk").passive), "성공 카드에서 유산을 고름 → 주 코어(깡통거북)의 패시브")
		await _save_shot("mix_result")
		await _seconds(0.2)
		# 실패 카드도 같은 모양인지 본다(연출 확인용으로 실패 카드를 한 번 띄운다)
		mixer.last_born = null
		mixer.call("_show_result_card")
		await _physics_frames(3)
		card_texts = mixer.result_card_texts()
		var lost_row := mixer.find_child("CardLost", true, false) as HBoxContainer
		_expect(lost_row.visible and lost_row.get_child_count() == 2 and card_texts[2] == UiText.MIX_FAIL_LOST % [kkang.title(), gochu.title()] and not (mixer.find_child("ToParty", true, false) as Button).visible, "실패 카드: 잃은 재료 두 칸 · 얻은 숙련 경험치, 계속 믹스만")
		await _seconds(GameConfig.MIX_FX_SHAKE_SECONDS + 0.1)
		await _save_shot("mix_fail")
		await _seconds(0.2)
		mixer.last_born = born
		mixer.call("_show_result_card")
		await _seconds(GameConfig.MIX_FX_POP_SECONDS + 0.1)
		await _tap(_center_of(mixer, "ShowInfo"))
		_expect(not mixer.visible and info.item == born and (info.find_child("Bonus", true, false) as Label).visible, "정보 보기 → 가방 창에서 태어난 코어(계승 줄)")
	else:
		var lost_cards := mixer.find_child("CardLost", true, false) as HBoxContainer
		_expect(lost_cards.visible and lost_cards.get_child_count() == 2 and card_texts[2] == UiText.MIX_FAIL_LOST % [kkang.title(), gochu.title()], "실패 카드: 잃은 재료 두 칸 · 얻은 숙련 경험치")
		await _save_shot("mix_fail")
		await _seconds(0.2)
		await _tap(_center_of(mixer, "Again"))
		_expect(mixer.visible and not mixer.is_showing_result(), "실패 → 계속 믹스 → 믹스창으로")
		await _tap(_center_of(mixer, "Close"))
	# 실패 경고: 믹스를 3번 한 뒤로는 버튼 아래 작은 글씨
	var mixes_before := workshop.mastery.mixes
	workshop.mastery.mixes = GameConfig.MIX_WARNING_BIG_TIMES
	mixer.refresh()
	_expect(not (mixer.find_child("WarningBig", true, false) as Control).visible and (mixer.find_child("WarningSmall", true, false) as Control).visible, "믹스 %d번 뒤로는 실패 경고가 작게" % GameConfig.MIX_WARNING_BIG_TIMES)
	workshop.mastery.mixes = mixes_before
	# 빛나는 코어(솥마뱀)를 재료로 쓰면 한 번 더 묻는다: 주 솥마뱀 + 보조 곰보곰 = 돌구아나
	var shiny := _find_core(bag, "sotmabaem", CoreItem.Gender.FEMALE)
	await _tap(hud.bag_panel.card_for(shiny).get_global_rect().get_center())
	await _tap(_center_of(info, "MixButton"))
	await _tap(mixer.material_card(_find_core(bag, "gombogom", CoreItem.Gender.MALE)).get_global_rect().get_center())
	count_before = bag.count()
	await _tap(_center_of(mixer, "Go"))
	_expect(hud.confirm_box.visible, "빛나는 코어가 들어 있으면 확인 창")
	await _tap(_center_of(hud.confirm_box, "No"))
	_expect(not hud.confirm_box.visible and mixer.visible and bag.count() == count_before and bag.has(shiny), "아니요 → 아무것도 바뀌지 않음")
	await _tap(_center_of(mixer, "Close"))
	_expect(not mixer.visible and hud.bag_panel.visible, "닫기 → 가방 창으로 돌아옴")
	# 직접 한 일(믹스)은 잠깐 뒤 저장된다(묶어서 저장 · 앞당김)
	await _seconds(GameConfig.SAVE_SOON_SECONDS + 0.5)
	var saved := LocalSaveStore.new(SMOKE_SAVE_PATH).load_data()
	_expect(saved.get("cores", []).size() == bag.count() and int(saved.get("gold", -1)) == wallet.gold, "믹스하고 %.0f초 뒤 저장됨 (코어 %d개 · 골드 %d)" % [GameConfig.SAVE_SOON_SECONDS, bag.count(), wallet.gold])
	# 변이(돌연변이) 코어: 정보창에 변이 보정 줄, 믹스 버튼은 못 누름
	var mutant := _find_core(bag, "haemapo", CoreItem.Gender.MALE)
	await _tap(hud.bag_panel.card_for(mutant).get_global_rect().get_center())
	var bonus := info.find_child("Bonus", true, false) as Label
	var mix_button := info.find_child("MixButton", true, false) as Button
	_expect(mutant.variant and bonus.visible and bonus.text.begins_with(UiText.VARIANT) and mix_button.disabled, "변이 코어: 변이 보정 줄이 보이고 믹스 버튼은 꺼짐")
	await _save_shot("variant")
	await _seconds(0.2)
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
	# 디버그 화면: 사냥 기록 · 시간당 처치 · 파티 전투 값(가방 창 위에 있던 것을 옮김)
	await _tap(hud.debug_button.global_position)
	var first_hench := (main.get("party") as Array)[0] as Hench
	_expect(hud.debug_panel.visible and hud.debug_panel.party_text().contains(first_hench.display_name), "디버그 버튼 → 디버그 화면(사냥 기록 · 파티 전투 값)")
	var boost_button := hud.debug_panel.find_child("DropBoost", true, false) as Button
	var real_core := Balance.core_chance()
	await _tap(boost_button.get_global_rect().get_center())
	_expect(Balance.dev_boost == GameConfig.DEV_DROP_BOOST and is_equal_approx(Balance.core_chance(), minf(real_core * GameConfig.DEV_DROP_BOOST, 1.0)), "드랍 확인 버튼 → 코어 확률 ×%d (%.3f%% → %.2f%%)" % [roundi(GameConfig.DEV_DROP_BOOST), real_core * 100.0, Balance.core_chance() * 100.0])
	await _save_shot("debug")
	await _seconds(0.2)
	await _tap((hud.debug_panel.find_child("Close", true, false) as Button).get_global_rect().get_center())
	_expect(not hud.debug_panel.visible, "디버그 화면 닫기")

	# 9) 자동 사냥: 야생 헨치를 다시 풀고, 시간을 4배로 빨리 돌려 게임 시간 40초 동안 지켜본다
	var hunt_log: HuntLog = main.get("hunt_log")
	var bag_before_hunt := bag.count()
	var cores_before_hunt := hunt_log.cores
	(main.get_node("WildSpawner") as WildSpawner).setup(main.get_node("Field"), player)
	Balance.dev_boost = 600.0  # 실행 검사 전용: 실제 확률로는 40초 안에 코어가 거의 안 떨어지므로 크게
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
	Balance.dev_boost = 1.0
	var kills: int = main.get("kills")
	_expect(kills >= 3, "자동 사냥 40초 → 3마리 이상 처치 (실제 %d)" % kills)
	_expect(hunt_log.kills() == kills and hunt_log.kills_per_hour(false) > 0.0, "사냥 기록: 처치 %d · 자동 시간당 %.0f마리" % [hunt_log.kills(), hunt_log.kills_per_hour(false)])
	await _seconds(GameConfig.CORE_POP_SECONDS + GameConfig.CORE_REST_SECONDS + 1.0)
	var picked := hunt_log.cores - cores_before_hunt
	_expect(picked >= 1 and bag.count() - bag_before_hunt == picked, "자동 사냥 중 떨어진 코어도 가방에 (%d개)" % picked)
	var casts := 0
	for hench: Hench in main.get("party"):
		var near := Iso.ground_distance(hench.position, player.position) <= GameConfig.PARTY_LEASH
		_expect(near or not hench.is_alive(), "%s: 주인공 곁에 있음" % hench.display_name)
		casts += hench.skill_casts
	_expect(casts >= 2, "풀오토: 헨치가 스킬을 알아서 씀 (%d번)" % casts)

	# 9-2) 보스전(프로토타입 6, 연습): 섬의 왕 버튼 → 확인 → 야생을 치우고 섬의 왕. 장판 피하기 · 지휘 버튼 · 구간 · 해방.
	await _switch_mode(hud, player, AutoControl.Mode.MANUAL)
	player.hp = player.stats.max_hp
	await _tap(hud.boss_button.global_position)
	_expect(hud.confirm_box.visible, "섬의 왕 버튼 → 도전할지 묻는 창")
	await _tap(_center_of(hud.confirm_box, "Yes"))
	await _physics_frames(3)
	var boss: Boss = main.get("boss")
	var wilds_now := get_nodes_in_group(&"wild")
	_expect(boss != null and wilds_now.size() == 1 and wilds_now[0] == boss, "예 → 야생을 치우고 섬의 왕 %s만 남음" % (boss.display_name if boss != null else "?"))
	_expect(player.target == boss and hud.target_frame.unit == boss and boss.hp_bar_marks().size() == 2, "대상 창 = 섬의 왕, 체력 바에 구간 눈금 2개")
	_expect(hud.command_button(0).visible and hud.command_button(2).visible and hud.boss_button.text == UiText.BOSS_GIVE_UP, "보스전 중: 지휘 버튼 보임, 섬의 왕 버튼 → 포기")
	# 정해 둔 장판을 하나씩 시험하는 동안은 보스가 스스로 움직이거나 장판을 깔지 않게 멈춰 둔다(깔린 장판은 따로 돈다).
	boss.process_mode = Node.PROCESS_MODE_DISABLED
	var lightning: Dictionary = GameConfig.BOSS_PATTERNS["lightning"]
	var lightning_windup: float = lightning["windup"]
	await _seconds(1.0)
	boss.start_pattern("lightning")
	await _seconds(lightning_windup + 0.2)
	var henches_alive := 0
	var henches_hit := 0
	for hench: Hench in main.get("party"):
		if hench.is_alive():
			henches_alive += 1
			henches_hit += 1 if boss.last_hits.has(hench) else 0
	_expect(boss.last_hits.has(player), "낙뢰: 가만히 선 주인공(수동)은 맞음 (체력 %d/%d)" % [roundi(player.hp), roundi(player.stats.max_hp)])
	_expect(henches_alive > 0 and henches_hit < henches_alive, "낙뢰: 헨치는 알아서 피함 (%d마리 중 %d마리 맞음)" % [henches_alive, henches_hit])
	player.hp = player.stats.max_hp
	boss.start_pattern("lightning")
	var dodge := _safe_direction(main, player, GameConfig.PLAYER_SPEED * 0.6)
	var stood_at := player.position
	Input.action_press(dodge)
	await _seconds(0.6)
	Input.action_release(dodge)
	await _seconds(lightning_windup - 0.4)
	_expect(player.position.distance_to(stood_at) > 50.0 and not boss.last_hits.has(player), "낙뢰: 수동으로 비켜서면 안 맞음 (체력 %d/%d)" % [roundi(player.hp), roundi(player.stats.max_hp)])
	# 지휘: 원거리조 버튼을 필드로 끌어다 놓으면 그 자리로 가서 버팀, 근접조를 섬의 왕 위에 놓으면 섬의 왕을 침, 전원을 짧게 누르면 모여
	var ranged: Array[Hench] = []
	var melee: Array[Hench] = []
	for hench: Hench in main.get("party"):
		if hench.is_alive():
			if hench.stats.attack_range > GameConfig.MELEE_RANGE_MAX:
				ranged.append(hench)
			else:
				melee.append(hench)
	var field: Field = main.get_node("Field")
	var hold_at := player.position
	for offset: Vector2 in [Vector2(-180, 60), Vector2(180, 60), Vector2(-180, -60), Vector2(180, -60)]:
		if field.is_walkable(player.position + offset) and boss.position.distance_to(player.position + offset) > 150.0:
			hold_at = player.position + offset
			break
	await _drag_button(hud.command_button(2), main.get_viewport().get_canvas_transform() * hold_at)
	await _seconds(1.5)
	var held := ranged.size() > 0
	for hench in ranged:
		held = held and hench.is_holding() and Iso.ground_distance(hench.position, hold_at) < 60.0
	var others_free := true
	for hench in melee:
		others_free = others_free and not hench.is_holding()
	_expect(held and others_free, "원거리조를 끌어다 놓음 → %d마리가 그 자리에서 버팀(근접조는 그대로)" % ranged.size())
	await _save_shot("boss_command")
	await _drag_button(hud.command_button(1), _screen_of(boss))
	var focused := melee.size() > 0
	for hench in melee:
		focused = focused and hench.get("_focus") == boss
	_expect(focused, "근접조를 섬의 왕 위에 놓음 → 섬의 왕을 침")
	await _tap(hud.command_button(0).global_position)
	var regrouped := true
	for hench: Hench in main.get("party"):
		regrouped = regrouped and not hench.is_holding() and hench.get("_focus") == null
	_expect(regrouped, "전원을 짧게 누름 → 모여(버티기 풀림)")
	# 용오름(보스 둘레 고리, 곁은 안전) + 낙뢰가 한꺼번에 깔린 장면
	player.hp = player.stats.max_hp
	boss.start_pattern("whirl")
	boss.start_pattern("lightning")
	await _seconds(lightning_windup * 0.6)
	await _save_shot("boss")
	await _seconds(float(GameConfig.BOSS_PATTERNS["whirl"]["windup"]))
	# 보스가 스스로: 체력이 구간 아래로 내려가면 "분노!", 정해진 차례로 장판을 깐다
	boss.process_mode = Node.PROCESS_MODE_INHERIT
	boss.hp = boss.stats.max_hp * 0.6
	await _physics_frames(3)
	_expect(boss.phase == 1, "체력 60% → 2구간(분노)")
	var cast_alone := false
	for i in 9 * Engine.physics_ticks_per_second:
		await physics_frame
		if boss.is_casting():
			cast_alone = true
			break
	_expect(cast_alone, "보스가 차례가 되면 스스로 장판을 깖")
	while boss.is_casting():
		await physics_frame
	# 풀오토: 주인공도 장판을 알아서 피함(조금 늦게)
	await _switch_mode(hud, player, AutoControl.Mode.FULL_AUTO)
	player.hp = player.stats.max_hp
	boss.start_pattern("lightning")
	await _seconds(lightning_windup + 0.2)
	_expect(not boss.last_hits.has(player), "풀오토: 주인공도 장판을 알아서 피함")
	# 해방: 체력을 1로 깎아 두면 파티가 마저 친다 → 알림 · 야생이 돌아오고 지휘 버튼이 사라짐
	boss.hp = 1.0
	for i in 8 * Engine.physics_ticks_per_second:
		await physics_frame
		if main.get("boss") == null:
			break
	_expect(main.get("boss") == null and hud.confirm_box.visible, "섬의 왕을 쓰러뜨리면 해방 알림")
	await _tap(_center_of(hud.confirm_box, "Yes"))
	await _physics_frames(3)
	var zones_left := 0
	for node in field.ground_effects.get_children():
		zones_left += 1 if node is BossZone and not node.is_queued_for_deletion() else 0
	var wild_count := get_nodes_in_group(&"wild").size()
	_expect(wild_count == GameConfig.WILD_COUNT and not hud.command_button(0).visible and hud.boss_button.text == UiText.BOSS_BUTTON and zones_left == 0, "보스전 끝 → 야생 %d마리 다시, 지휘 버튼 숨김, 장판 없음" % wild_count)
	# 포기: 다시 도전했다가 섬의 왕 버튼(포기) → 예
	await _tap(hud.boss_button.global_position)
	await _tap(_center_of(hud.confirm_box, "Yes"))
	await _physics_frames(3)
	_expect(main.get("boss") != null, "다시 도전")
	await _tap(hud.boss_button.global_position)
	await _tap(_center_of(hud.confirm_box, "Yes"))
	await _physics_frames(3)
	_expect(main.get("boss") == null and hud.confirm_box.visible, "포기 → 보스전 끝 알림")
	await _tap(_center_of(hud.confirm_box, "Yes"))
	await _physics_frames(3)
	_expect(get_nodes_in_group(&"wild").size() == GameConfig.WILD_COUNT, "포기한 뒤 야생이 다시 나옴")

	# 10) 저장 → 다시 켜기: 가방(코어 하나하나) · 골드 · 코어 조각 · 파티 · 사냥 방식이 그대로
	var keep := _find_core(bag, "jinjuryong", CoreItem.Gender.FEMALE)
	main.call("assign_party", keep, 2)
	player.control.mode = AutoControl.Mode.SEMI_AUTO
	wallet.add_gold(1)  # 아직 저장 안 된 변화
	var expected := []
	for item in bag.cores:
		expected.append(item.to_dict())
	var gold_saved := wallet.gold
	var shards_saved := wallet.shards
	main.propagate_notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)  # 창 닫기(X)를 눌렀을 때 오는 알림
	var on_close := LocalSaveStore.new(SMOKE_SAVE_PATH).load_data()
	_expect(int(on_close.get("gold", -1)) == gold_saved and on_close.get("cores", []).size() == expected.size(), "창을 닫으면(X) 기다리지 않고 바로 저장")
	main.queue_free()
	await process_frame
	var again: Node = load(MAIN_SCENE).instantiate()
	again.set("save_store", LocalSaveStore.new(SMOKE_SAVE_PATH))
	root.add_child(again)
	await _physics_frames(5)
	var bag_again: Bag = again.get("bag")
	var restored := []
	for item in bag_again.cores:
		restored.append(item.to_dict())
	_expect(restored == expected, "다시 켜면 가방이 그대로 (코어 %d개, 시작 가방을 다시 넣지 않음)" % restored.size())
	var wallet_again: Wallet = again.get("wallet")
	_expect(wallet_again.gold == gold_saved and wallet_again.shards == shards_saved, "골드 %d · 코어 조각 %d 그대로" % [gold_saved, shards_saved])
	var party_again: Array = again.get("party")
	var healer := party_again[2] as Hench
	_expect(healer.species.id == "jinjuryong" and is_equal_approx(healer.stats.max_hp, UnitStats.from_core(keep).max_hp), "파티 3번 자리 = 진주룡 코어(능력치까지) 그대로")
	var player_again: Player = again.get_node("Field/Objects/Player")
	var hud_again: Hud = again.get_node("HUD")
	_expect(player_again.control.mode == AutoControl.Mode.SEMI_AUTO and hud_again.auto_button.mode == AutoControl.Mode.SEMI_AUTO, "사냥 방식(세미오토)을 기억함")
	LocalSaveStore.new(SMOKE_SAVE_PATH).erase()

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


## 화면 그 자리를 손가락으로 톡 누른다. 누른 뒤 화면 프레임을 두 번 기다려, 창의 배치(컨테이너 정렬)가 바뀐 것을 반영한다.
func _tap(at: Vector2) -> void:
	_touch(true, at)
	await _physics_frames(2)
	_touch(false, at)
	await _physics_frames(2)
	await process_frame
	await process_frame


## 오토 버튼을 눌러 원하는 사냥 방식으로 바꾼다(누를 때마다 다음 방식).
## 지휘 버튼을 눌러 그 자리(화면 좌표)까지 끌고 가서 뗀다.
func _drag_button(button: TouchScreenButton, to: Vector2) -> void:
	var from := button.global_position
	_touch(true, from)
	await _physics_frames(2)
	for i in range(1, 6):
		_drag(from.lerp(to, i / 5.0))
		await _physics_frames(1)
	_touch(false, to)
	await _physics_frames(3)


## 주인공이 그 거리(화면 가로 px, 세로는 MOVE_VERTICAL_RATIO만큼)를 걸어가면 걸을 수 있고 어느 장판에도 들지 않는 방향의 이동 액션.
func _safe_direction(main: Node, player: Player, distance: float) -> String:
	var field: Field = main.get_node("Field")
	var actions := ["move_left", "move_right", "move_up", "move_down"]
	var steps := [Vector2(-distance, 0), Vector2(distance, 0), Vector2(0, -distance * GameConfig.MOVE_VERTICAL_RATIO), Vector2(0, distance * GameConfig.MOVE_VERTICAL_RATIO)]
	for i in actions.size():
		var end := player.position + (steps[i] as Vector2)
		var safe := field.is_walkable(end)
		for node in field.ground_effects.get_children():
			if node is BossZone and (node as BossZone).is_pending() and (node as BossZone).shape.contains(end):
				safe = false
		if safe:
			return actions[i]
	return "move_left"


func _switch_mode(hud: Hud, player: Player, mode: AutoControl.Mode) -> void:
	for i in AutoControl.Mode.size():
		if player.control.mode == mode:
			return
		await _tap(hud.auto_button.global_position)


## 가방에서 그 종·성별의 첫 코어. 없으면 null.
func _find_core(bag: Bag, species_id: String, gender: CoreItem.Gender) -> CoreItem:
	for item in bag.cores:
		if item.species_id == species_id and item.gender == gender:
			return item
	return null


## 창 안에서 그 이름의 버튼(또는 칸) 한가운데의 화면 좌표.
func _center_of(root_node: Node, node_name: String) -> Vector2:
	return (root_node.find_child(node_name, true, false) as Control).get_global_rect().get_center()


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

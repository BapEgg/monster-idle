extends "res://tests/suite.gd"
## 저장 테스트: core/save_schedule.gd(묶어서 저장), core/game_save.gd(저장 내용 만들기·되살리기),
## core/local_save_store.gd(기기 파일, 망가짐 대비).

const TEST_PATH := "user://test_save.json"


func _core(id: String, gender: CoreItem.Gender, suffix := "mighty") -> CoreItem:
	var item := CoreItem.new()
	item.species_id = id
	item.gender = gender
	item.suffix_id = suffix
	return item


## 기획서 9장: 처치마다 저장하지 않고 묶어서 저장한다.
func test_schedule_batches_changes() -> void:
	var schedule := SaveSchedule.new(30.0, 2.0)
	expect_true(not schedule.tick(100.0), "바뀐 것이 없으면 저장하지 않는다")
	var saves := 0
	for second in 90:  # 90초 동안 1초마다 처치(골드가 바뀜)
		schedule.mark_dirty()
		saves += 1 if schedule.tick(1.0) else 0
	expect_true(saves == 3, "1초마다 바뀌어도 30초에 한 번씩만 저장 (90초 → %d번)" % saves)
	schedule = SaveSchedule.new(30.0, 2.0)
	schedule.mark_dirty()
	expect_true(not schedule.tick(1.0), "보통 변화는 바로 저장하지 않는다")
	schedule.mark_dirty(true)
	expect_true(not schedule.tick(1.5) and schedule.tick(0.6), "직접 한 일(믹스 등)은 2초 뒤에 저장")
	expect_true(not schedule.dirty and not schedule.tick(100.0), "저장하면 표시가 지워진다")
	schedule.mark_dirty(true)
	schedule.mark_dirty(true)
	schedule.tick(1.0)
	schedule.mark_dirty(true)
	expect_true(schedule.tick(1.0), "연달아 해도 처음 일 기준 2초에 한 번으로 묶인다")
	schedule.mark_dirty()
	schedule.clear()
	expect_true(not schedule.tick(100.0), "끌 때 바로 저장했으면(clear) 다시 저장하지 않는다")


func test_capture_and_restore_round_trip() -> void:
	var bag := Bag.new()
	var wallet := Wallet.new()
	wallet.gold = 1234
	wallet.add_core_shards("gochuryong", 7)
	wallet.add_core_shards("mireu", 2)
	var party_core := _core("gochuryong", CoreItem.Gender.FEMALE, "swift")
	party_core.level = 12
	party_core.exp_points = 33  # 헨치 경험치도 저장된다
	party_core.age = CoreItem.Age.OLD
	party_core.party_slot = 1
	var born := _core("dolguana", CoreItem.Gender.MALE, "lucky")
	born.inherit_stat = "precise"
	born.inherit_value = 6
	born.passive_species_id = "sotmabaem"
	born.locked = true
	var shiny := _core("haemapo", CoreItem.Gender.MALE, "tough")
	shiny.shining = true
	shiny.variant = true
	for item in [party_core, born, shiny]:
		bag.add(item)
	var mastery := MixMastery.new()
	mastery.gain(true)
	mastery.gain(true)
	mastery.gain(true)
	var codex := Codex.new()
	codex.register("mireu")
	wallet.add_exp_shards(7)
	var progress := PlayerProgress.new()
	progress.gain(Growth.exp_to_next(1) + Growth.exp_to_next(2) + 5)
	var world := WorldState.new()
	world.opened.append("plant")
	world.move_to("dragon", "special")
	var data := GameSave.capture(bag, wallet, AutoControl.Mode.SEMI_AUTO, 1_800_000_000, mastery, codex, progress, null, world)
	# 파일에 쓰고 읽은 것처럼 JSON을 거친다(숫자가 실수로 바뀐다)
	var parsed: Dictionary = JSON.parse_string(JSON.stringify(data))
	var bag2 := Bag.new()
	var wallet2 := Wallet.new()
	var mastery2 := MixMastery.new()
	var codex2 := Codex.new()
	var progress2 := PlayerProgress.new()
	var world2 := WorldState.new()
	var dropped := GameSave.restore(parsed, bag2, wallet2, GameConfig.PARTY_HENCHES.size(), mastery2, codex2, progress2, null, world2)
	expect_true(world2.island == "dragon" and world2.region == "special" and world2.is_island_open("plant"), "섬 · 지역 · 열린 섬을 기억한다")
	expect_true(progress2.level == 3 and progress2.exp_points == 5, "주인공 레벨 · 경험치를 기억한다 (Lv %d, %d)" % [progress2.level, progress2.exp_points])
	expect_true(wallet2.exp_shards == 7, "경험치 조각을 기억한다")
	expect_true(dropped == 0 and bag2.count() == 3, "코어 3개가 그대로 돌아온다")
	for i in bag.count():
		expect_true(bag2.cores[i].to_dict() == bag.cores[i].to_dict(), "%s: 종·접미사·나이·성별·레벨·빛남·변이·잠금·파티·유산·주 코어 성별이 같다" % bag.cores[i].species_id)
	expect_true(wallet2.gold == 1234 and wallet2.core_shards == {"gochuryong": 7, "mireu": 2}, "골드 · 종마다 코어 조각이 같다")
	expect_true(GameSave.control_mode(parsed) == AutoControl.Mode.SEMI_AUTO, "사냥 방식을 기억한다")
	expect_true(mastery2.level == mastery.level and mastery2.exp_points == mastery.exp_points and mastery2.mixes == 3, "믹스 숙련도 · 믹스한 횟수를 기억한다 (%d단계, %d번)" % [mastery2.level, mastery2.mixes])
	expect_true(codex2.has("mireu") and codex2.has("gochuryong") and codex2.has("dolguana") and codex2.has("haemapo"), "도감: 저장된 것 + 가방에 있는 종")
	expect_true(int(parsed["version"]) == GameSave.VERSION and int(parsed["saved_at"]) == 1_800_000_000, "판·저장한 때")


func test_restore_cleans_bad_rows() -> void:
	var data := {
		"cores": [
			{"species": "gochuryong", "party_slot": 0},
			{"species": "sotmabaem", "party_slot": 0},  # 같은 자리 → 빠짐
			{"species": "haemapo", "party_slot": 9},  # 없는 자리 → 빠짐
			{"species": "no_such_hench"},  # 도감에 없는 종 → 버림
			"망가진 줄",
		],
		"gold": -50,
		"core_shards": {"gochuryong": 3, "no_such_hench": 5, "haemapo": -2},
		"shards": 9,  # 5판까지의 종 없는 조각 → 어느 종인지 몰라 버린다
		"control_mode": 99,
	}
	var bag := Bag.new()
	var wallet := Wallet.new()
	var dropped := GameSave.restore(data, bag, wallet, 3, MixMastery.new(), Codex.new())
	expect_true(dropped == 2 and bag.count() == 3, "도감에 없는 종과 망가진 줄은 버린다 (버림 %d)" % dropped)
	expect_true(bag.cores[0].party_slot == 0 and bag.cores[1].party_slot == -1 and bag.cores[2].party_slot == -1, "파티 자리는 겹치거나 없는 자리면 비운다")
	expect_true(wallet.gold == 0, "골드가 음수면 0")
	expect_true(wallet.core_shards == {"gochuryong": 3}, "코어 조각: 도감에 없는 종 · 0 이하 · 옛 판의 종 없는 조각은 버린다")
	expect_true(GameSave.control_mode(data) == GameConfig.START_CONTROL_MODE and GameSave.control_mode({}) == GameConfig.START_CONTROL_MODE, "이상한 사냥 방식은 처음 방식으로")


func test_local_store() -> void:
	var store := LocalSaveStore.new(TEST_PATH)
	store.erase()
	expect_true(store.load_data().is_empty() and store.last_error == "", "저장이 없으면 빈 내용(처음 시작)")
	expect_true(store.save_data({"gold": 1}) and store.save_data({"gold": 2}), "저장 성공")
	expect_true(int(store.load_data().get("gold", 0)) == 2, "마지막 저장을 읽는다")
	expect_true(FileAccess.file_exists(TEST_PATH + LocalSaveStore.BACKUP_SUFFIX) and not FileAccess.file_exists(TEST_PATH + LocalSaveStore.TEMP_SUFFIX), "바로 전 저장은 .bak으로 남고, 임시 파일은 없다")
	var broken := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	broken.store_string("{ 쓰다가 꺼짐")
	broken.close()
	expect_true(int(store.load_data().get("gold", 0)) == 1 and store.last_error != "", "저장 파일이 망가지면 바로 전 저장(.bak)을 읽고 문제를 알린다")
	store.erase()
	expect_true(store.load_data().is_empty() and not FileAccess.file_exists(TEST_PATH + LocalSaveStore.BACKUP_SUFFIX), "지우면 처음부터")

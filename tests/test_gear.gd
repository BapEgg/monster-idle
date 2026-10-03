extends "res://tests/suite.gd"
## 장비 테스트(기획서 3장 장비 확정: 7칸 · 등급 · 품질 · 직업 전용 무기, 수치는 임시): data/gear.json, GearDb, GearRules, GearItem, GearBag.


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func test_gear_data() -> void:
	expect_true(GearRules.SLOTS.size() == 7, "장비 7칸(무기 · 투구 · 갑옷 · 장갑 · 신발 · 장신구 2)")
	expect_true(GearDb.kinds() == PackedStringArray(["weapon", "helmet", "armor", "gloves", "boots", "accessory"]), "부위 6종")
	expect_true(GearRules.slots_for("accessory") == PackedStringArray(["accessory_1", "accessory_2"]) and GearRules.slots_for("weapon") == PackedStringArray(["weapon"]), "장신구는 두 칸, 나머지는 한 칸")
	for kind in GearDb.kinds():
		expect_true(UiText.GEAR_SLOT_NAMES.has(kind) and GameConfig.GEAR_MAIN_BASE.has(kind), "%s: 이름 · 기본값이 있다" % kind)
		expect_true(GearDb.main_stat(kind, "warrior") in SuffixDb.ids(), "%s: 주 능력치는 9종 중 하나" % kind)
	for job_id in JobDb.ids():
		expect_true(not GearDb.names("weapon", job_id).is_empty() and GearDb.main_stat("weapon", job_id) in SuffixDb.ids(), "%s: 무기 이름 · 주 능력치" % job_id)
	expect_true(GearDb.main_stat("weapon", "healer") == "abundant" and GearDb.main_stat("weapon", "rogue") == "mighty", "힐러 무기 = 마나, 도적 무기 = 공격")
	var sizes := [UiText.GEAR_GRADES.size(), GameConfig.GEAR_GRADE_SCALE.size(), GameConfig.GEAR_OPTION_COUNT.size(), GameConfig.GEAR_GRADE_WEIGHTS.size(), Palette.GEAR_GRADE_COLORS.size()]
	expect_true(sizes.count(5) == sizes.size(), "등급 5개(일반 · 마법 · 희귀 · 전설 · 세트)마다 이름 · 배율 · 옵션 수 · 비중 · 색")
	expect_true(UiText.GEAR_QUALITIES.size() == 4 and GameConfig.GEAR_QUALITY_SCALE.size() == 4 and GameConfig.GEAR_QUALITY_WEIGHTS.size() == 4, "품질 4개(하급 · 중급 · 상급 · 최상급)")
	for stat: String in GameConfig.GEAR_OPTIONS:
		expect_true(stat in SuffixDb.ids() or GearRules.is_percent(stat), "옵션 %s: 능력치 9종 또는 퍼센트" % stat)
		expect_true(GearRules.stat_name(stat) != stat, "옵션 %s: 이름이 있다(%s)" % [stat, GearRules.stat_name(stat)])


func test_main_value() -> void:
	expect_true(GearRules.main_value("weapon", 1, 0, 1) == roundi(GameConfig.GEAR_MAIN_BASE["weapon"]), "Lv 1 일반 중급 무기 = 기본값")
	expect_true(GearRules.main_value("weapon", 30, 0, 1) > GearRules.main_value("weapon", 1, 0, 1), "레벨이 높으면 세다")
	var by_grade := []
	for grade in 4:
		by_grade.append(GearRules.main_value("armor", 20, grade, 1))
	expect_true(by_grade[0] < by_grade[1] and by_grade[1] < by_grade[2] and by_grade[2] < by_grade[3], "등급이 오르면 주 능력치도 오름 %s" % [by_grade])
	expect_true(GearRules.main_value("armor", 20, 2, 0) < GearRules.main_value("armor", 20, 2, 3), "품질 하급 < 최상급")
	expect_true(GearRules.main_value("armor", 20, 3, 1) < GearRules.main_value("armor", 20, 0, 1) * 1.5, "등급 차이가 압도적이지 않음(전설도 일반의 1.5배 미만)")


func test_roll() -> void:
	var a := GearRules.roll(_rng(5), "weapon", "rogue", 10, 2, 2)
	var b := GearRules.roll(_rng(5), "weapon", "rogue", 10, 2, 2)
	expect_true(a.to_dict() == b.to_dict(), "같은 씨앗이면 같은 장비")
	expect_true(a.job_id == "rogue" and a.main_stat == "mighty" and a.base_name in GearDb.names("weapon", "rogue"), "도적 무기: 직업 · 주 능력치 · 이름")
	expect_true(a.options.size() == GameConfig.GEAR_OPTION_COUNT[2], "희귀 = 옵션 %d개" % GameConfig.GEAR_OPTION_COUNT[2])
	var seen := {}
	for option in a.options:
		expect_true(option["stat"] != a.main_stat and not seen.has(option["stat"]), "옵션은 주 능력치와 겹치지 않고 서로 다르다")
		seen[option["stat"]] = true
	expect_true(GearRules.roll(_rng(1), "helmet", "rogue", 10, 0, 1).options.is_empty() and GearRules.roll(_rng(1), "helmet", "rogue", 10, 0, 1).job_id == "", "일반 = 옵션 없음, 무기가 아니면 직업 없음")
	for i in 40:
		var item := GearRules.roll(_rng(100 + i), "boots", "warrior", 20, 3, 1)
		for option in item.options:
			expect_true(option["stat"] != "party_hp", "파티 헨치 체력 옵션은 장신구에만")
	var any_party := false
	for i in 60:
		for option in GearRules.roll(_rng(200 + i), "accessory", "warrior", 20, 3, 1).options:
			any_party = any_party or option["stat"] == "party_hp"
	expect_true(any_party, "장신구에는 파티 헨치 체력 옵션이 붙을 수 있다(헨치 간접 강화)")
	expect_near(float(GearRules.option_value("crit_chance", 1, 0.0)), GameConfig.GEAR_OPTION_PERCENT["crit_chance"][0], "치명 확률 옵션 최소")
	expect_near(float(GearRules.option_value("crit_chance", 1, 1.0)), GameConfig.GEAR_OPTION_PERCENT["crit_chance"][1], "치명 확률 옵션 최대")
	expect_true(int(GearRules.option_value("mighty", 1, 0.0)) >= 1, "능력치 옵션은 1 이상")
	var random := GearRules.roll_random(_rng(9), "archer", 20)
	expect_true(random.kind in GearDb.kinds() and absi(random.level - 20) <= 3, "개발용 무작위 장비: 부위 · 레벨 폭")


func test_pick_weighted() -> void:
	expect_true(GearRules.pick_weighted([1.0, 1.0], 0.0) == 0 and GearRules.pick_weighted([1.0, 1.0], 0.49) == 0 and GearRules.pick_weighted([1.0, 1.0], 0.51) == 1, "비중 고르기")
	expect_true(GearRules.pick_weighted([1.0, 0.0, 1.0], 0.99) == 2 and GearRules.pick_weighted([1.0, 1.0], 1.0) == 1, "끝과 0 비중")


func test_problem_and_bonus() -> void:
	var bow := GearRules.roll(_rng(3), "weapon", "archer", 10, 1, 1)
	expect_true(GearRules.problem(bow, "archer", 10) == GearRules.Problem.OK, "궁수 Lv 10이 Lv 10 활을 낌")
	expect_true(GearRules.problem(bow, "rogue", 30) == GearRules.Problem.WRONG_JOB, "다른 직업 무기는 못 낌")
	expect_true(GearRules.problem(bow, "archer", 9) == GearRules.Problem.LEVEL, "장비 레벨이 높으면 못 낌")
	var bonus := bow.bonus()
	expect_true(bonus[bow.main_stat] >= bow.main_value and bonus.size() == 1 + bow.options.size(), "주 능력치 + 옵션")
	var total := GearRules.total([bow, bow] as Array[GearItem])
	expect_true(total[bow.main_stat] == bonus[bow.main_stat] * 2, "합계")
	var change := GearRules.diff({"mighty": 10, "crit_chance": 0.02}, {"mighty": 4, "tough": 3})
	expect_true(change == {"mighty": 6, "tough": -3, "crit_chance": 0.02}, "비교: 늘어난 것 · 줄어든 것(%s)" % [change])
	expect_true(GearRules.value_text("mighty", 12) == "+12" and GearRules.value_text("tough", -3) == "−3" and GearRules.value_text("crit_chance", 0.025) == "+2.5%" and GearRules.value_text("crit_damage", 0.1) == "+10%", "값 글자")


func test_sorted() -> void:
	var list: Array[GearItem] = []
	for row: Array in [[1, "boots", 0, 5], [2, "weapon", 3, 2], [3, "helmet", 1, 9], [4, "weapon", 1, 9]]:
		var item := GearRules.roll(_rng(row[0]), row[1], "warrior", row[3], row[2], 1)
		item.uid = row[0]
		list.append(item)
	var uids := func(items: Array[GearItem]) -> Array:
		return items.map(func(item: GearItem) -> int: return item.uid)
	expect_true(uids.call(GearRules.sorted(list, GearRules.Sort.GRADE))[0] == 2, "등급순: 전설이 먼저")
	expect_true(uids.call(GearRules.sorted(list, GearRules.Sort.LEVEL)).slice(0, 2) == [4, 3], "레벨순: Lv 9 둘(등급 같으면 최근) → …")
	expect_true(uids.call(GearRules.sorted(list, GearRules.Sort.KIND)) == [2, 4, 3, 1], "부위순: 무기(등급순) → 투구 → 신발")
	expect_true(uids.call(GearRules.sorted(list, GearRules.Sort.NEWEST)) == [4, 3, 2, 1], "최근순")


func test_gear_bag() -> void:
	var bag := GearBag.new()
	var ring_a := bag.add(GearRules.roll(_rng(1), "accessory", "", 1, 0, 1))
	var ring_b := bag.add(GearRules.roll(_rng(2), "accessory", "", 1, 0, 1))
	var ring_c := bag.add(GearRules.roll(_rng(3), "accessory", "", 1, 0, 1))
	var sword := bag.add(GearRules.roll(_rng(4), "weapon", "warrior", 1, 2, 1))
	var high := bag.add(GearRules.roll(_rng(5), "helmet", "", 30, 0, 1))
	expect_true(ring_a.uid == 1 and high.uid == 5 and bag.inventory().size() == 5, "넣으면 번호가 붙고 아이템 칸에 보임")
	expect_true(bag.equip(ring_a, "warrior", 10) and bag.equip(ring_b, "warrior", 10), "장신구 둘")
	expect_true(bag.slot_of(ring_a) == "accessory_1" and bag.slot_of(ring_b) == "accessory_2", "장신구는 빈 칸부터")
	bag.equip(ring_c, "warrior", 10)
	expect_true(bag.slot_of(ring_c) == "accessory_1" and bag.slot_of(ring_a) == "" and ring_a in bag.inventory(), "두 칸이 다 차면 첫 칸을 바꾸고, 뺀 것은 아이템 칸으로")
	expect_true(bag.equip(ring_a, "warrior", 10, "accessory_2") and bag.slot_of(ring_b) == "", "칸을 골라 끼울 수 있다")
	expect_true(not bag.equip(high, "warrior", 10) and bag.slot_of(high) == "", "레벨이 모자라면 못 낌")
	expect_true(bag.equip(sword, "warrior", 10) and bag.in_slot("weapon") == sword, "무기")
	var worn := bag.bonus()
	expect_true(int(worn.get("mighty", 0)) >= sword.main_value, "낀 장비 합계에 무기 공격")
	bag.fit_job("rogue")
	expect_true(bag.in_slot("weapon") == null and sword in bag.inventory(), "직업이 바뀌면 다른 직업 무기는 빠진다")
	bag.toggle_lock(sword)
	var copy := GearBag.new()
	copy.load_dict(JSON.parse_string(JSON.stringify(bag.to_dict())))
	expect_true(copy.items.size() == 5 and copy.equipped == bag.equipped and copy.next_uid == 6 and copy.find(sword.uid).locked, "저장 → 되살리기(JSON을 거쳐도) 그대로")
	expect_true(copy.find(ring_c.uid).to_dict() == ring_c.to_dict(), "장비 하나하나 그대로(옵션 포함)")
	var broken := GearBag.new()
	broken.load_dict({"items": [{"uid": 3, "kind": "helmet"}, {"uid": 3, "kind": "boots"}, {"uid": 4, "kind": "cape"}], "equipped": {"weapon": 3}, "next_uid": 1})
	expect_true(broken.items.size() == 1 and broken.equipped.is_empty() and broken.next_uid == 4, "번호가 겹치거나 모르는 부위 · 맞지 않는 칸은 버림")


func test_upgrade_arrow() -> void:
	var low := GearRules.roll(_rng(1), "helmet", "", 10, 0, 0)
	var top := GearRules.roll(_rng(2), "helmet", "", 10, 3, 3)
	expect_true(GearRules.is_upgrade(low, [] as Array[GearItem], 1), "빈 칸이면 무엇이든 더 좋음")
	expect_true(GearRules.is_upgrade(top, [low] as Array[GearItem], 1) and not GearRules.is_upgrade(low, [top] as Array[GearItem], 1), "점수가 높으면 더 좋음")

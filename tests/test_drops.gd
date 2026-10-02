extends "res://tests/suite.gd"
## core/drops.gd, core/suffix_db.gd, core/core_item.gd, core/bag.gd 테스트: 코어 드랍·접미사·나이·가방.

const ROLLS := 20000


func test_suffixes_match_plan() -> void:
	# 기획서 4장 접미사 9종(가칭)
	var names := PackedStringArray()
	for id in SuffixDb.ids():
		names.append(SuffixDb.display_name(id))
	expect_true(names == PackedStringArray(["신속", "강력", "정밀", "날렵", "단단", "강인", "충만", "굳건", "행운"]), "접미사 9종 이름·순서 (%s)" % ", ".join(names))


func test_drop_rate_matches_config() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var drops := 0
	var shining := 0
	var suffixes := {}
	for i in ROLLS:
		var item := Drops.roll_core(rng, "gochuryong", CoreItem.Age.YOUNG)
		if item == null:
			continue
		drops += 1
		shining += 1 if item.shining else 0
		suffixes[item.suffix_id] = true
		if drops == 1:
			expect_true(item.species_id == "gochuryong" and item.age == CoreItem.Age.YOUNG, "코어는 쓰러뜨린 헨치의 종·나이를 받는다")
	expect_near(float(drops) / ROLLS, GameConfig.CORE_DROP_CHANCE, "드랍 비율 ≈ 설정값", 0.015)
	expect_near(float(shining) / drops, GameConfig.SHINING_CORE_CHANCE, "빛나는 코어 비율 ≈ 설정값", 0.02)
	expect_true(suffixes.size() == SuffixDb.ids().size(), "접미사 9종이 모두 나온다")


func test_same_seed_same_drops() -> void:
	var a := RandomNumberGenerator.new()
	var b := RandomNumberGenerator.new()
	a.seed = 42
	b.seed = 42
	var same := true
	for i in 200:
		var x := Drops.roll_core(a, "haemapo", CoreItem.Age.ADULT)
		var y := Drops.roll_core(b, "haemapo", CoreItem.Age.ADULT)
		same = same and ((x == null) == (y == null)) and (x == null or x.to_dict() == y.to_dict())
	expect_true(same, "같은 씨앗이면 같은 결과(순수 함수)")


func test_age_weights() -> void:
	expect_true(Drops.weighted_index([0.25, 0.5, 0.25], 0.1) == 0, "0.1 → 어린")
	expect_true(Drops.weighted_index([0.25, 0.5, 0.25], 0.3) == 1, "0.3 → 성체")
	expect_true(Drops.weighted_index([0.25, 0.5, 0.25], 0.99) == 2, "0.99 → 늙은")
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var counts := [0, 0, 0]
	for i in ROLLS:
		counts[Drops.roll_age(rng)] += 1
	var total := 0.0
	for weight: float in GameConfig.AGE_WEIGHTS:
		total += weight
	for age in counts.size():
		expect_near(float(counts[age]) / ROLLS, GameConfig.AGE_WEIGHTS[age] / total, "%s 비율 ≈ 설정값" % UiText.AGE_NAMES[age], 0.015)


func test_core_item_round_trip() -> void:
	var item := CoreItem.new()
	item.species_id = "jinjuryong"
	item.suffix_id = "lucky"
	item.age = CoreItem.Age.OLD
	item.shining = true
	var back := CoreItem.from_dict(JSON.parse_string(JSON.stringify(item.to_dict())))
	expect_true(back.to_dict() == item.to_dict(), "저장용 사전 → JSON → 다시 코어로 바꿔도 같다")


func test_bag_has_no_limit() -> void:
	var bag := Bag.new()
	for i in 500:
		bag.add(CoreItem.new())
	expect_true(bag.count() == 500, "지금은 칸 수 제한이 없다(사용자 결정)")

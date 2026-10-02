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
		var item := Drops.roll_core(rng, _wild("gochuryong", CoreItem.Age.YOUNG, false))
		if item == null:
			continue
		drops += 1
		shining += 1 if item.shining else 0
		suffixes[item.suffix_id] = true
		if drops == 1:
			expect_true(item.species_id == "gochuryong" and item.age == CoreItem.Age.YOUNG and item.level == 7 and item.gender == CoreItem.Gender.MALE, "코어는 쓰러뜨린 헨치의 종·나이·성별·레벨을 받는다")
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
		var x := Drops.roll_core(a, _wild("haemapo", CoreItem.Age.ADULT, false))
		var y := Drops.roll_core(b, _wild("haemapo", CoreItem.Age.ADULT, false))
		same = same and ((x == null) == (y == null)) and (x == null or x.to_dict() == y.to_dict())
	expect_true(same, "같은 씨앗이면 같은 결과(순수 함수)")


## 기획서 4장: 변이체는 처치하면 코어가 반드시 떨어진다.
func test_variant_always_drops() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var all_dropped := true
	for i in 300:
		var item := Drops.roll_core(rng, _wild("haemapo", CoreItem.Age.OLD, true))
		all_dropped = all_dropped and item != null and item.variant
	expect_true(all_dropped, "변이체는 300번 모두 코어가 떨어지고 변이 표시가 남는다")


func test_gender_and_variant_rates() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var females := 0
	var variants := 0
	for i in ROLLS:
		females += 1 if Drops.roll_gender(rng) == CoreItem.Gender.FEMALE else 0
		variants += 1 if Drops.roll_variant(rng) else 0
	expect_near(float(females) / ROLLS, GameConfig.FEMALE_CHANCE, "암컷 비율 ≈ 설정값", 0.015)
	expect_near(float(variants) / ROLLS, GameConfig.VARIANT_CHANCE, "변이 비율 ≈ 설정값", 0.01)


## 기획서 4장: 어린 = 지역 평균 -2, 늙은 = +2 (지역 평균 대신 종 레벨대 가운데)
func test_wild_level() -> void:
	var gochu := HenchDb.get_species("gochuryong")  # 레벨대 3~12 → 가운데 7
	expect_true(Drops.wild_level(gochu, CoreItem.Age.ADULT) == 7, "성체 = 레벨대 가운데(7)")
	expect_true(Drops.wild_level(gochu, CoreItem.Age.YOUNG) == 5, "어린 = 가운데 - 2")
	expect_true(Drops.wild_level(gochu, CoreItem.Age.OLD) == 9, "늙은 = 가운데 + 2")
	expect_true(Drops.wild_level(HenchDb.get_species("sotmabaem"), CoreItem.Age.YOUNG) >= 1, "레벨은 1 아래로 내려가지 않는다")


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
	item.gender = CoreItem.Gender.MALE
	item.level = 12
	item.shining = true
	item.variant = true
	item.locked = true
	item.party_slot = 2
	item.passive_species_id = "sotmabaem"
	var back := CoreItem.from_dict(JSON.parse_string(JSON.stringify(item.to_dict())))
	expect_true(back.to_dict() == item.to_dict(), "저장용 사전 → JSON → 다시 코어로 바꿔도 같다")


func test_bag_has_no_limit() -> void:
	var bag := Bag.new()
	for i in 500:
		bag.add(CoreItem.new())
	expect_true(bag.count() == 500, "지금은 칸 수 제한이 없다(사용자 결정)")


## 테스트용 야생 헨치 본(수컷, 레벨 = 성체 기준 7)
func _wild(id: String, age: CoreItem.Age, variant: bool) -> CoreItem:
	var item := CoreItem.new()
	item.species_id = id
	item.age = age
	item.gender = CoreItem.Gender.MALE
	item.level = 7
	item.variant = variant
	return item

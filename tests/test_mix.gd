extends "res://tests/suite.gd"
## core/mix.gd, core/core_stats.gd, core/wallet.gd 테스트: 믹스(암수 방향·공개 단계·확률·실패 소멸 규칙), 능력치, 지갑.


func _core(id: String, gender: CoreItem.Gender, suffix := "mighty") -> CoreItem:
	var item := CoreItem.new()
	item.species_id = id
	item.gender = gender
	item.suffix_id = suffix
	return item


## 기획서 5장: 돌구아나 = 고추룡 + 깡통거북. 공식 [A, B]는 A = 암컷으로 읽는다(임시).
func test_result_depends_on_which_is_female() -> void:
	var gochu_f := _core("gochuryong", CoreItem.Gender.FEMALE)
	var kkang_m := _core("kkangtonggeobuk", CoreItem.Gender.MALE)
	expect_true(Mix.result_id(gochu_f, kkang_m) == "dolguana", "고추룡(암) + 깡통거북(수) = 돌구아나")
	expect_true(Mix.result_id(kkang_m, gochu_f) == "dolguana", "주·보조 칸을 바꿔도 같다(성별이 정한다)")
	var gochu_m := _core("gochuryong", CoreItem.Gender.MALE)
	var kkang_f := _core("kkangtonggeobuk", CoreItem.Gender.FEMALE)
	expect_true(Mix.result_id(gochu_m, kkang_f) == "", "암수가 반대면 다른 종(아직 미정 → 공식 없음)")
	expect_true(Mix.result_id(gochu_f, _core("kkangtonggeobuk", CoreItem.Gender.FEMALE)) == "", "같은 성별이면 결과 없음")


## 기획서 4장 초안: 하급 + 하급 → 중급(공개), 중급 + 타 종족 → 상급(힌트), 왕은 비밀
func test_reveal_by_grade() -> void:
	expect_true(Mix.reveal_of("dolguana") == Mix.Reveal.OPEN, "중급 결과 = 공개(이름)")
	expect_true(Mix.reveal_of("banseoksangun") == Mix.Reveal.HINT, "상급 결과 = 힌트(실루엣)")
	expect_true(Mix.reveal_of("mireu") == Mix.Reveal.SECRET, "왕 = 비밀(?)")
	expect_true(Mix.reveal_of("") == Mix.Reveal.SECRET, "공식 없는 조합도 비밀(?)로 보여 구별되지 않는다")
	var beon_f := _core("beongaeiri", CoreItem.Gender.FEMALE)
	var dol_m := _core("dolguana", CoreItem.Gender.MALE)
	expect_true(Mix.result_id(beon_f, dol_m) == "banseoksangun", "번개이리(암) + 돌구아나(수) = 반석산군")


func test_chance_and_cost() -> void:
	expect_near(Mix.success_chance("dolguana"), GameConfig.MIX_SUCCESS_BY_GRADE["mid"], "중급 성공 확률 = 설정값")
	expect_near(Mix.success_chance(""), 0.0, "공식 없는 조합은 늘 실패")
	expect_true(Mix.gold_cost("dolguana") == GameConfig.MIX_GOLD_COST_BY_GRADE["mid"], "중급 비용 = 설정값")
	expect_true(Mix.gold_cost("") == GameConfig.MIX_GOLD_COST_UNKNOWN, "공식 없는 조합도 비용을 받는다")


func test_problems() -> void:
	var f := _core("gochuryong", CoreItem.Gender.FEMALE)
	var m := _core("kkangtonggeobuk", CoreItem.Gender.MALE)
	expect_true(Mix.problem(f, null, 9999) == Mix.Problem.MISSING, "재료가 하나뿐")
	expect_true(Mix.problem(f, f, 9999) == Mix.Problem.SAME_CORE, "같은 코어 두 번")
	expect_true(Mix.problem(f, _core("haemapo", CoreItem.Gender.FEMALE), 9999) == Mix.Problem.SAME_GENDER, "암수 한 쌍이 아님")
	expect_true(Mix.problem(f, m, 0) == Mix.Problem.NO_GOLD, "골드 모자람")
	m.locked = true
	expect_true(Mix.problem(f, m, 9999) == Mix.Problem.LOCKED, "잠긴 코어는 재료로 못 씀")
	m.locked = false
	m.party_slot = 0
	expect_true(Mix.problem(f, m, 9999) == Mix.Problem.IN_PARTY, "파티에 있는 코어는 재료로 못 씀")
	m.party_slot = -1
	expect_true(Mix.problem(f, m, 9999) == Mix.Problem.NONE, "암수 한 쌍, 골드 충분 → 믹스 가능")


## 사용자 결정(2026-10-02): 성공 확률이 있고, 실패하면 재료가 사라진다(재료를 없애는 건 부르는 쪽).
func test_roll_success_rate_and_born_core() -> void:
	var main := _core("gochuryong", CoreItem.Gender.FEMALE, "lucky")
	main.passive_species_id = "sotmabaem"  # 주 코어가 이미 솥마뱀 패시브를 유산으로 갖고 있다
	var sub := _core("kkangtonggeobuk", CoreItem.Gender.MALE)
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	var born_count := 0
	var sample: CoreItem = null
	for i in 5000:
		var born := Mix.roll(rng, main, sub, true)
		if born != null:
			born_count += 1
			sample = born
	expect_near(born_count / 5000.0, GameConfig.MIX_SUCCESS_BY_GRADE["mid"], "성공 비율 ≈ 설정값", 0.02)
	expect_true(sample.species_id == "dolguana" and sample.suffix_id == "lucky", "태어난 종 = 돌구아나, 접미사 = 주 코어의 것")
	expect_true(sample.age == GameConfig.MIX_BORN_AGE and sample.level == GameConfig.MIX_BORN_LEVEL, "새 몸: 나이·레벨 = 설정값")
	expect_true(sample.passive_species_id == "sotmabaem", "유산을 고르면 주 코어의 지금 패시브를 받는다")
	expect_true(Mix.roll(rng, main, sub, false) == null or Mix.roll(rng, main, sub, false).passive_species_id == "", "유산을 안 고르면 자기 패시브")
	var never := 0
	for i in 200:
		never += 1 if Mix.roll(rng, _core("gochuryong", CoreItem.Gender.MALE), _core("kkangtonggeobuk", CoreItem.Gender.FEMALE), true) != null else 0
	expect_true(never == 0, "공식 없는 조합(반대 방향)은 200번 모두 실패")


func test_dismantle_shards() -> void:
	var plain := _core("gochuryong", CoreItem.Gender.MALE)
	expect_true(Mix.dismantle_shards(plain) == GameConfig.DISMANTLE_SHARDS, "보통 코어 분해 = 기본 조각")
	plain.shining = true
	plain.variant = true
	expect_true(Mix.dismantle_shards(plain) == GameConfig.DISMANTLE_SHARDS + GameConfig.DISMANTLE_SHARDS_SHINING_BONUS + GameConfig.DISMANTLE_SHARDS_VARIANT_BONUS, "빛나는·변이 코어는 덤")


func test_stats() -> void:
	var base := _core("gochuryong", CoreItem.Gender.MALE, "lucky")  # 근접딜러, 하급
	var stats := CoreStats.compute(base)
	expect_true(stats.size() == 11, "능력치 9종 + HP·MP")
	expect_true(stats["mighty"] == GameConfig.CORE_BASE_STATS["melee"]["mighty"], "1레벨 성체 하급 = 역할 기본값")
	expect_true(stats["hp"] == stats["tough"] * GameConfig.HP_PER_TOUGH and stats["mp"] == stats["abundant"] * GameConfig.MP_PER_ABUNDANT, "HP·MP = 체력·마나 × 설정값")
	var leveled := _core("gochuryong", CoreItem.Gender.MALE, "lucky")
	leveled.level = 11
	expect_true(CoreStats.compute(leveled)["mighty"] > stats["mighty"], "레벨이 오르면 능력치가 오른다")
	var mighty := _core("gochuryong", CoreItem.Gender.MALE, "mighty")
	var shiny := _core("gochuryong", CoreItem.Gender.MALE, "mighty")
	shiny.shining = true
	expect_true(CoreStats.compute(mighty)["mighty"] > stats["mighty"], "강력 접미사 → 공격↑")
	expect_true(CoreStats.compute(shiny)["mighty"] > CoreStats.compute(mighty)["mighty"], "빛나는 코어는 접미사 보너스가 더 크다")
	var young := _core("gochuryong", CoreItem.Gender.MALE, "lucky")
	young.age = CoreItem.Age.YOUNG
	var old := _core("gochuryong", CoreItem.Gender.MALE, "lucky")
	old.age = CoreItem.Age.OLD
	var y := CoreStats.compute(young)
	var o := CoreStats.compute(old)
	expect_true(y["tough"] > o["tough"] and y["abundant"] < o["abundant"], "어린 = 몸↑ 스킬↓, 늙은 = 몸↓ 스킬↑ (기획서 4장)")
	var mid := _core("gabotjangsu", CoreItem.Gender.MALE, "lucky")  # 근접딜러, 중급
	expect_near(float(CoreStats.compute(mid)["mighty"]), stats["mighty"] * GameConfig.CORE_GRADE_BONUS["mid"], "중급 = 하급 × 등급 보정(약 +10%)", 1.0)


func test_wallet() -> void:
	var wallet := Wallet.new()
	wallet.add_gold(100)
	expect_true(not wallet.spend_gold(150) and wallet.gold == 100, "모자라면 내지 않는다")
	expect_true(wallet.spend_gold(60) and wallet.gold == 40, "있으면 낸다")
	wallet.add_shards(3)
	expect_true(wallet.shards == 3, "코어 조각")


## 사용자 결정(2026-10-02): 실패해도 재료는 사라지고 골드도 나간다.
func test_workshop_consumes_materials() -> void:
	var bag := Bag.new()
	var wallet := Wallet.new()
	wallet.add_gold(10000)
	var shop := Workshop.new(bag, wallet)
	shop.rng.seed = 99
	var successes := 0
	var fails := 0
	for i in 40:
		var f := _core("gochuryong", CoreItem.Gender.FEMALE)
		var m := _core("kkangtonggeobuk", CoreItem.Gender.MALE)
		bag.add(f)
		bag.add(m)
		var before := bag.count()
		var gold := wallet.gold
		var born := shop.mix(f, m, false)
		expect_true(not bag.has(f) and not bag.has(m), "믹스하면 성공·실패와 상관없이 재료 둘이 사라진다")
		expect_true(wallet.gold == gold - Mix.gold_cost("dolguana"), "골드가 비용만큼 나간다")
		if born != null:
			successes += 1
			expect_true(bag.count() == before - 1 and bag.has(born), "성공: 새 코어 하나가 가방에")
		else:
			fails += 1
			expect_true(bag.count() == before - 2, "실패: 재료만 사라짐")
	expect_true(successes > 0 and fails > 0, "성공도 실패도 나온다 (성공 %d · 실패 %d)" % [successes, fails])


func test_workshop_blocks_locked_and_party() -> void:
	var bag := Bag.new()
	var wallet := Wallet.new()
	wallet.add_gold(10000)
	var shop := Workshop.new(bag, wallet)
	var f := _core("gochuryong", CoreItem.Gender.FEMALE)
	var m := _core("kkangtonggeobuk", CoreItem.Gender.MALE)
	bag.add(f)
	bag.add(m)
	shop.toggle_lock(f)
	expect_true(shop.mix(f, m, false) == null and bag.count() == 2 and wallet.gold == 10000, "잠긴 코어로는 믹스가 안 되고 아무것도 바뀌지 않는다")
	expect_true(shop.dismantle(f) == 0 and bag.has(f), "잠긴 코어는 분해되지 않는다")
	shop.toggle_lock(f)
	m.party_slot = 1
	expect_true(shop.dismantle(m) == 0 and bag.has(m), "파티 코어는 분해되지 않는다")
	expect_true(shop.dismantle(f) == GameConfig.DISMANTLE_SHARDS and not bag.has(f) and wallet.shards == GameConfig.DISMANTLE_SHARDS, "분해 → 가방에서 빠지고 코어 조각")

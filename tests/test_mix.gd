extends "res://tests/suite.gd"
## core/mix.gd, core/mix_mastery.gd, core/codex.gd, core/core_stats.gd, core/unit_stats.gd(코어 → 전투), core/wallet.gd 테스트:
## 믹스(기획서 4장 믹스 세부 규칙: 주 코어 방향·계승 스탯·성별 성장·성공률·숙련도·결과 레벨·접미사·공식 없음),
## 능력치, 파티 전투 환산, 지갑.


func _core(id: String, gender: CoreItem.Gender, suffix := "mighty") -> CoreItem:
	var item := CoreItem.new()
	item.species_id = id
	item.gender = gender
	item.suffix_id = suffix
	return item


## 사용자 결정(2026-10-03): 공식 [A, B] = 주 A · 보조 B. 주·보조를 바꾸면 다른 공식이고, 성별은 종을 바꾸지 않는다.
func test_result_depends_on_main_core() -> void:
	var gochu_f := _core("gochuryong", CoreItem.Gender.FEMALE)
	var kkang_m := _core("kkangtonggeobuk", CoreItem.Gender.MALE)
	expect_true(Mix.result_id(gochu_f, kkang_m) == "dolguana", "주 고추룡 + 보조 깡통거북 = 돌구아나 (기획서 5장)")
	expect_true(Mix.result_id(kkang_m, gochu_f) == "gigwankokkiri", "주·보조를 바꾸면 다른 공식 = 기관코끼리(초안)")
	expect_true(not Mix.is_draft(gochu_f, kkang_m) and Mix.is_draft(kkang_m, gochu_f), "기획서 공식 / 초안 공식 구별")
	var gochu_m := _core("gochuryong", CoreItem.Gender.MALE)
	var kkang_f := _core("kkangtonggeobuk", CoreItem.Gender.FEMALE)
	expect_true(Mix.result_id(gochu_m, kkang_f) == "dolguana", "주 코어가 같으면 성별이 바뀌어도 같은 종")
	expect_true(Mix.result_id(_core("sotmabaem", CoreItem.Gender.FEMALE), _core("haemapo", CoreItem.Gender.MALE)) == "", "공식이 없는 조합")
	# 기획서에 처음부터 양방향이 있는 쌍: 진주룡 + 반딧등 / 반딧등 + 진주룡
	var jinju := _core("jinjuryong", CoreItem.Gender.FEMALE)
	var bandit := _core("banditdeung", CoreItem.Gender.MALE)
	expect_true(Mix.result_id(jinju, bandit) == "mungeimugi" and Mix.result_id(bandit, jinju) == "mujigaeyeou", "주 진주룡 = 뭉게이무기, 주 반딧등 = 무지개여우 (기획서)")


## 기획서 4장 초안: 하급 + 하급 → 중급(공개), 중급 + 타 종족 → 상급(힌트), 왕은 비밀
func test_reveal_by_grade() -> void:
	expect_true(Mix.reveal_of("dolguana") == Mix.Reveal.OPEN, "중급 결과 = 공개(이름)")
	expect_true(Mix.reveal_of("banseoksangun") == Mix.Reveal.HINT, "상급 결과 = 힌트(실루엣)")
	expect_true(Mix.reveal_of("mireu") == Mix.Reveal.SECRET, "왕 = 비밀(?)")
	expect_true(Mix.reveal_of("") == Mix.Reveal.SECRET, "공식 없는 조합은 ?(믹스는 못 한다)")
	var beon_f := _core("beongaeiri", CoreItem.Gender.FEMALE)
	var dol_m := _core("dolguana", CoreItem.Gender.MALE)
	expect_true(Mix.result_id(beon_f, dol_m) == "banseoksangun", "번개이리(암) + 돌구아나(수) = 반석산군")


## 기획서 4장: 기본 성공률 하급→중급 85%, 중급→상급 65%. 확률 내역 = 기본 + 숙련 + 마크.
func test_chance_and_cost() -> void:
	expect_near(Mix.success_chance("dolguana"), 0.85, "하급→중급 기본 85%")
	expect_near(Mix.success_chance("banseoksangun"), 0.65, "중급→상급 기본 65%")
	expect_near(Mix.success_chance(""), 0.0, "공식 없는 조합은 0")
	var parts := Mix.success_parts("dolguana", 5)
	expect_near(parts["mastery"], 4 * GameConfig.MIX_MASTERY_BONUS_PER_LEVEL, "숙련 5단계 = +8%")
	expect_near(parts["total"], parts["base"] + parts["mastery"] + parts["mark"], "합 = 기본 + 숙련 + 마크")
	expect_near(Mix.success_chance("dolguana", GameConfig.MIX_MASTERY_MAX_LEVEL), minf(0.85 + 8 * GameConfig.MIX_MASTERY_BONUS_PER_LEVEL, GameConfig.MIX_SUCCESS_CAP), "상한을 넘지 않는다")
	expect_true(Mix.gold_cost("dolguana") == GameConfig.MIX_GOLD_COST_BY_GRADE["mid"], "중급 비용 = 설정값")


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
	expect_true(Mix.problem(_core("sotmabaem", CoreItem.Gender.FEMALE), _core("haemapo", CoreItem.Gender.MALE), 9999) == Mix.Problem.NO_RECIPE, "공식 없는 조합은 믹스 불가(알려진 공식이 없어요)")
	expect_true(UiText.MIX_PROBLEMS.size() == Mix.Problem.size() and UiText.MIX_MATERIAL_REASONS.size() == Mix.Problem.size(), "까닭 문구가 까닭 수만큼 있다")
	# 재료 목록에서 흐리게 보일 까닭(주 코어 자신 · 같은 성별 · 잠금 · 파티 · 변이)
	var v := _core("haemapo", CoreItem.Gender.MALE)
	v.variant = true
	expect_true(Mix.material_problem(f, f) == Mix.Problem.SAME_CORE and Mix.material_problem(_core("haemapo", CoreItem.Gender.FEMALE), f) == Mix.Problem.SAME_GENDER and Mix.material_problem(v, f) == Mix.Problem.VARIANT and Mix.material_problem(m, f) == Mix.Problem.NONE, "재료 칸 까닭")


## 기획서 4장 믹스 세부 규칙: 성공 확률이 있고 실패하면 재료가 사라진다(없애는 건 Workshop).
## 태어난 코어: 레벨 = 높은 레벨의 절반(최소 = 출현 레벨), 접미사 = 주 코어 것 50% · 나머지 무작위,
## 추가 스탯 = 보조 코어 접미사 능력치의 15~20%, 나이 = 어린, 성별 50:50, 유산 패시브 선택.
func test_roll_success_rate_and_born_core() -> void:
	var main := _core("gochuryong", CoreItem.Gender.FEMALE, "lucky")
	main.level = 50
	main.passive_species_id = "sotmabaem"  # 주 코어가 이미 솥마뱀 패시브를 유산으로 갖고 있다
	var sub := _core("kkangtonggeobuk", CoreItem.Gender.MALE, "sturdy")
	sub.level = 9
	var span := Mix.inherit_range(sub)
	var sub_value := float(CoreStats.compute(sub)["sturdy"])
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	var born_count := 0
	var kept_suffix := 0
	var females := 0
	var inherit_ok := true
	var sample: CoreItem = null
	for i in 5000:
		var born := Mix.roll(rng, main, sub, true)
		if born == null:
			continue
		born_count += 1
		sample = born
		kept_suffix += 1 if born.suffix_id == "lucky" else 0
		females += 1 if born.gender == CoreItem.Gender.FEMALE else 0
		inherit_ok = inherit_ok and born.inherit_stat == "sturdy" and born.inherit_value >= span.x and born.inherit_value <= span.y
	expect_near(born_count / 5000.0, 0.85, "성공 비율 ≈ 85%", 0.02)
	expect_true(sample.species_id == "dolguana" and sample.age == CoreItem.Age.YOUNG, "태어난 종 = 돌구아나, 나이 = 어린")
	expect_true(sample.level == 25 and Mix.born_level(main, sub, "dolguana") == 25, "레벨 = 높은 레벨(50)의 절반 = 25")
	# 접미사: 주 코어 것 50% + 무작위 9종 중 하나가 우연히 같은 경우(1/9 × 50%)
	expect_near(float(kept_suffix) / born_count, GameConfig.MIX_SUFFIX_KEEP_CHANCE + (1.0 - GameConfig.MIX_SUFFIX_KEEP_CHANCE) / 9.0, "주 코어 접미사를 잇는 비율 ≈ 50% (+무작위로 같은 것)", 0.03)
	expect_near(float(females) / born_count, GameConfig.FEMALE_CHANCE, "성별 50:50", 0.03)
	expect_true(inherit_ok and span.x == maxi(roundi(sub_value * 0.15), 1) and span.y == maxi(roundi(sub_value * 0.2), 1), "추가 스탯 = 보조 코어 접미사(방어) %d의 15~20%% → %d~%d" % [sub_value, span.x, span.y])
	expect_true(sample.passive_species_id == "sotmabaem", "유산을 고르면 주 코어의 지금 패시브를 받는다")
	var own := Mix.roll(rng, main, sub, false)
	expect_true(own == null or own.passive_species_id == "", "유산을 안 고르면 자기 패시브")
	var low := _core("gochuryong", CoreItem.Gender.FEMALE)
	var low_sub := _core("kkangtonggeobuk", CoreItem.Gender.MALE)
	expect_true(Mix.born_level(low, low_sub, "dolguana") == HenchDb.get_species("dolguana").level_min, "낮은 재료면 최소 = 출현 레벨")
	var never := 0
	for i in 200:
		never += 1 if Mix.roll(rng, _core("sotmabaem", CoreItem.Gender.MALE), _core("haemapo", CoreItem.Gender.FEMALE), true) != null else 0
	expect_true(never == 0, "공식 없는 조합은 태어나지 않는다")


## 기획서 4장 믹스 세부 규칙: 숙련도 1~9단계, 성공 100% · 실패 50% 경험치, 단계마다 성공 확률 +2%.
func test_mastery() -> void:
	var mastery := MixMastery.new()
	expect_true(mastery.level == 1 and mastery.success_bonus() == 0.0, "1단계 = 보너스 없음")
	var need := mastery.exp_to_next()
	expect_true(mastery.exp_for(true) == GameConfig.MIX_MASTERY_EXP_PER_MIX and mastery.exp_for(false) == roundi(GameConfig.MIX_MASTERY_EXP_PER_MIX * GameConfig.MIX_MASTERY_FAIL_EXP_RATE), "얻는 경험치: 성공 %d · 실패 %d" % [mastery.exp_for(true), mastery.exp_for(false)])
	var fails := 0
	while mastery.level == 1:
		mastery.gain(false)
		fails += 1
	expect_true(fails == ceili(float(need) / roundi(GameConfig.MIX_MASTERY_EXP_PER_MIX * GameConfig.MIX_MASTERY_FAIL_EXP_RATE)), "실패는 경험치 절반 (%d번에 2단계)" % fails)
	expect_near(mastery.success_bonus(), GameConfig.MIX_MASTERY_BONUS_PER_LEVEL, "2단계 = +2%")
	for i in 1000:
		mastery.gain(true)
	expect_true(mastery.is_max() and mastery.level == GameConfig.MIX_MASTERY_MAX_LEVEL and mastery.progress() == 1.0 and not mastery.gain(true) and mastery.exp_for(true) == 0, "9단계에서 멈춘다(더 얻는 경험치 0)")
	var copy := MixMastery.new()
	copy.load_dict(mastery.to_dict())
	expect_true(copy.level == mastery.level and copy.mixes == mastery.mixes and mastery.mixes == fails + 1000 + 1, "저장해도 단계 · 믹스한 횟수(%d번)가 남는다" % copy.mixes)


func test_codex() -> void:
	var codex := Codex.new()
	expect_true(codex.register("dolguana") and not codex.register("dolguana") and codex.has("dolguana") and codex.count() == 1, "처음 얻은 종만 NEW")


## 기획서 4장: 성별 = 성장 성향(암컷은 체력·방어, 수컷은 공격·속도가 레벨업 때 조금 더 오름)
func test_gender_growth() -> void:
	var f1 := _core("dolguana", CoreItem.Gender.FEMALE, "lucky")
	var m1 := _core("dolguana", CoreItem.Gender.MALE, "lucky")
	var a := CoreStats.compute(f1)
	var b := CoreStats.compute(m1)
	expect_true(a["tough"] == b["tough"] and a["mighty"] == b["mighty"], "1레벨은 성별 차이 없음")
	f1.level = 30
	m1.level = 30
	a = CoreStats.compute(f1)
	b = CoreStats.compute(m1)
	expect_true(a["tough"] > b["tough"] and a["sturdy"] > b["sturdy"], "암컷: 체력·방어가 더 오름")
	expect_true(b["mighty"] > a["mighty"] and b["swift"] > a["swift"], "수컷: 공격·속도가 더 오름")
	expect_true(a["precise"] == b["precise"], "그 밖의 능력치는 같다")


## 믹스 계승 스탯은 고정치로 더해지고 저장된다.
func test_inherit_adds_flat() -> void:
	var plain := _core("dolguana", CoreItem.Gender.FEMALE, "lucky")
	var born := _core("dolguana", CoreItem.Gender.FEMALE, "lucky")
	born.inherit_stat = "precise"
	born.inherit_value = 7
	expect_true(CoreStats.compute(born)["precise"] == CoreStats.compute(plain)["precise"] + 7 and born.is_mix_born() and not plain.is_mix_born(), "계승 +7")
	var copy := CoreItem.from_dict(born.to_dict())
	expect_true(copy.inherit_stat == "precise" and copy.inherit_value == 7, "저장해도 계승이 남는다")


func test_needs_confirm() -> void:
	var item := _core("gochuryong", CoreItem.Gender.FEMALE)
	expect_true(not Mix.needs_confirm(item), "보통 재료는 바로")
	item.shining = true
	expect_true(Mix.needs_confirm(item), "빛나는 코어는 한 번 더 묻는다")
	item.shining = false
	item.level = GameConfig.MIX_CONFIRM_LEVEL
	expect_true(Mix.needs_confirm(item), "높은 레벨도 한 번 더 묻는다")


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


## 파티에 넣은 코어는 그 능력치로 싸운다(임시 환산). 역할 상식: 탱커가 가장 튼튼, 딜러 공격 > 탱커 > 힐러, 힐러만 회복.
func test_core_combat_stats() -> void:
	var tank := UnitStats.from_core(_core("sotmabaem", CoreItem.Gender.FEMALE, "lucky"))
	var melee := UnitStats.from_core(_core("gochuryong", CoreItem.Gender.FEMALE, "lucky"))
	var ranged := UnitStats.from_core(_core("haemapo", CoreItem.Gender.FEMALE, "lucky"))
	var healer := UnitStats.from_core(_core("jinjuryong", CoreItem.Gender.FEMALE, "lucky"))
	expect_true(tank.max_hp > melee.max_hp and tank.max_hp > ranged.max_hp and tank.max_hp > healer.max_hp, "탱커가 가장 튼튼")
	expect_true(melee.attack > tank.attack and ranged.attack > tank.attack and tank.attack > healer.attack, "딜러 > 탱커 > 힐러 공격")
	expect_true(healer.heal > 0.0 and tank.heal == 0.0 and melee.heal == 0.0, "힐러만 회복")
	expect_true(ranged.attack_range > GameConfig.MELEE_RANGE_MAX and melee.attack_range <= GameConfig.MELEE_RANGE_MAX, "사거리는 역할 표를 따른다")
	var core := CoreStats.compute(_core("gochuryong", CoreItem.Gender.FEMALE, "lucky"))
	expect_near(melee.max_hp, float(core["hp"]), "체력 = 코어 HP")
	expect_near(melee.attack, core["mighty"] * GameConfig.CORE_COMBAT_ATTACK_PER_MIGHTY, "공격 = 강력 × 설정값")
	var fast := _core("gochuryong", CoreItem.Gender.FEMALE, "swift")
	expect_true(UnitStats.from_core(fast).attack_interval < melee.attack_interval, "신속이 높으면 공격 간격이 짧다")
	expect_true(melee.attack_interval < GameConfig.ROLE_STATS["melee"]["attack_interval"], "간격은 역할 간격보다 짧아진다(절반까지는 안 됨)")


## 사용자 결정(2026-10-03): 변이(돌연변이)는 드롭 전용 — 믹스 재료로 못 쓰고, 믹스로 태어나지도 않는다.
## 대신 역할의 주특기 능력치 몇 개가 조금 오른다(임시 설정값).
func test_variant_rules() -> void:
	var f := _core("gochuryong", CoreItem.Gender.FEMALE)
	var m := _core("kkangtonggeobuk", CoreItem.Gender.MALE)
	m.variant = true
	expect_true(Mix.problem(f, m, 9999) == Mix.Problem.VARIANT and Mix.problem(m, f, 9999) == Mix.Problem.VARIANT, "변이는 주·보조 어느 쪽으로도 재료가 안 된다")
	expect_true(UiText.MIX_PROBLEMS.size() == Mix.Problem.size(), "믹스 못 하는 까닭 문구가 까닭 수만큼 있다")
	m.variant = false
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var any_variant := false
	for i in 300:
		var born := Mix.roll(rng, f, m, false)
		any_variant = any_variant or (born != null and born.variant)
	expect_true(not any_variant, "믹스로 태어난 코어는 변이가 아니다")
	var plain := _core("sotmabaem", CoreItem.Gender.FEMALE, "lucky")  # 탱커
	var mutant := _core("sotmabaem", CoreItem.Gender.FEMALE, "lucky")
	mutant.variant = true
	var p := CoreStats.compute(plain)
	var v := CoreStats.compute(mutant)
	var boosted: Array = GameConfig.VARIANT_STATS["tank"]
	expect_true(CoreStats.variant_stats(plain).is_empty() and CoreStats.variant_stats(mutant) == boosted, "변이 보정 능력치 = 역할(탱커)의 주특기")
	for stat: String in p:
		if stat in boosted:
			expect_near(float(v[stat]), p[stat] * (1.0 + GameConfig.VARIANT_STAT_BONUS), "변이 → %s +설정값" % stat, 1.0)
		elif stat != "hp" and stat != "mp":
			expect_true(v[stat] == p[stat], "변이여도 %s는 그대로" % stat)
	expect_true(UnitStats.from_core(mutant).max_hp > UnitStats.from_core(plain).max_hp, "파티에 넣으면 변이 보정으로 싸운다(탱커 체력↑)")


func test_wallet() -> void:
	var wallet := Wallet.new()
	wallet.add_gold(100)
	expect_true(not wallet.spend_gold(150) and wallet.gold == 100, "모자라면 내지 않는다")
	expect_true(wallet.spend_gold(60) and wallet.gold == 40, "있으면 낸다")
	wallet.add_core_shards("gochuryong", 3)
	wallet.add_core_shards("haemapo", 1)
	expect_true(wallet.core_shards_of("gochuryong") == 3 and wallet.total_core_shards() == 4, "코어 조각은 종마다 따로")
	expect_true(not wallet.spend_core_shards("haemapo", 2) and wallet.spend_core_shards("haemapo", 1) and not wallet.core_shards.has("haemapo"), "모자라면 안 쓰고, 다 쓰면 목록에서 빠진다")


## 코어 조각(종마다)을 다 모으면 그 종 코어 하나(사용자 결정 2026-10-03, 쓰는 곳은 임시).
func test_make_core_from_shards() -> void:
	var bag := Bag.new()
	var wallet := Wallet.new()
	var shop := Workshop.new(bag, wallet)
	shop.rng.seed = 3
	wallet.add_core_shards("gochuryong", GameConfig.CORE_SHARDS_PER_CORE - 1)
	expect_true(not shop.can_make_from_shards("gochuryong") and shop.make_from_shards("gochuryong") == null and bag.count() == 0, "덜 모이면 못 만든다")
	wallet.add_core_shards("gochuryong", 2)
	var made := shop.make_from_shards("gochuryong")
	var species := HenchDb.get_species("gochuryong")
	expect_true(made != null and bag.has(made) and made.species_id == "gochuryong" and made.level == species.level_min, "다 모이면 그 종 코어(Lv %d = 최소 출현 레벨)" % (made.level if made != null else 0))
	expect_true(not made.shining and not made.variant and made.suffix_id != "" and wallet.core_shards_of("gochuryong") == 1, "빛나지 않고 변이도 아님, 쓴 만큼 조각이 줄어듦")
	expect_true(shop.codex.has("gochuryong"), "만든 종은 도감에")


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
	var exp_total := successes * GameConfig.MIX_MASTERY_EXP_PER_MIX + fails * roundi(GameConfig.MIX_MASTERY_EXP_PER_MIX * GameConfig.MIX_MASTERY_FAIL_EXP_RATE)
	expect_true(shop.mastery.level > 1, "믹스할수록 숙련도가 오른다 (경험치 %d → %d단계)" % [exp_total, shop.mastery.level])
	expect_true(shop.codex.has("dolguana"), "태어난 종은 도감에 등록된다")


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
	expect_true(shop.dismantle(f) == GameConfig.DISMANTLE_SHARDS and not bag.has(f) and wallet.core_shards_of("gochuryong") == GameConfig.DISMANTLE_SHARDS, "분해 → 가방에서 빠지고 그 종의 코어 조각")


## 레시피 창: 모든 공식 목록이 공식 찾기(recipe_result)와 같다.
func test_recipe_list() -> void:
	var list := HenchDb.recipes()
	var same := not list.is_empty()
	var drafts := 0
	for row in list:
		same = same and HenchDb.recipe_result(row["main"], row["sub"]) == row["result"] and HenchDb.is_draft_recipe(row["main"], row["sub"]) == row["draft"]
		drafts += 1 if row["draft"] else 0
	expect_true(same and drafts > 0 and drafts < list.size(), "공식 %d개(초안 %d개)가 공식 찾기와 같다" % [list.size(), drafts])


## 레시피 창에서 누르면 가방에서 쓸 수 있는 한 쌍(레벨 높은 것부터, 암수 맞게)을 찾는다.
func test_find_pair() -> void:
	var low_f := _core("gochuryong", CoreItem.Gender.FEMALE)
	var high_f := _core("gochuryong", CoreItem.Gender.FEMALE)
	high_f.level = 20
	var same_m := _core("gochuryong", CoreItem.Gender.MALE)
	var locked_m := _core("kkangtonggeobuk", CoreItem.Gender.MALE)
	locked_m.locked = true
	var cores: Array[CoreItem] = [low_f, high_f, same_m, locked_m]
	expect_true(Mix.find_pair(cores, "gochuryong", "kkangtonggeobuk").is_empty(), "보조 깡통거북이 잠겨 있으면 없음")
	var free_m := _core("kkangtonggeobuk", CoreItem.Gender.MALE)
	cores.append(free_m)
	var pair := Mix.find_pair(cores, "gochuryong", "kkangtonggeobuk")
	expect_true(pair.size() == 2 and pair[0] == high_f and pair[1] == free_m, "레벨 높은 주 코어 + 잠기지 않은 보조 코어")
	var female_sub := _core("kkangtonggeobuk", CoreItem.Gender.FEMALE)
	var only_f: Array[CoreItem] = [high_f, female_sub]
	expect_true(Mix.find_pair(only_f, "gochuryong", "kkangtonggeobuk").is_empty(), "암수가 안 맞으면 없음")


## 성공 카드에서 패시브를 고른다(믹스할 때는 고르지 않는다).
func test_choose_passive_after_mix() -> void:
	var bag := Bag.new()
	var wallet := Wallet.new()
	wallet.add_gold(100000)
	var shop := Workshop.new(bag, wallet)
	shop.rng.seed = 3
	var born: CoreItem = null
	var main: CoreItem = null
	for i in 20:
		main = _core("gochuryong", CoreItem.Gender.FEMALE)
		var sub := _core("kkangtonggeobuk", CoreItem.Gender.MALE)
		bag.add(main)
		bag.add(sub)
		born = shop.mix(main, sub, false)
		if born != null:
			break
	expect_true(born != null and born.passive_owner_id() == born.species_id, "태어난 코어는 먼저 자기 패시브")
	shop.choose_passive(born, main.passive_owner_id())
	expect_true(born.passive_owner_id() == "gochuryong", "유산을 고르면 주 코어(고추룡)의 패시브")
	shop.choose_passive(born, "")
	expect_true(born.passive_owner_id() == born.species_id, "다시 자기 패시브로 바꿀 수 있다")

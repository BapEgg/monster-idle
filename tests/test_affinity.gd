extends "res://tests/suite.gd"
## 종족 상성 테스트(사용자 결정 2026-10-03, 추천 A): data/tribes.json의 beats, Affinity.


func test_one_ring() -> void:
	var ids := TribeDb.ids()
	expect_true(ids.size() == 8, "종족 8개")
	var targets := {}
	for id in ids:
		var tribe := TribeDb.get_tribe(id)
		expect_true(tribe.beats in ids and tribe.beats != id, "%s: 강한 상대가 다른 종족(%s)" % [tribe.name, tribe.beats])
		expect_true(tribe.beats_why != "", "%s: 까닭이 있다" % tribe.name)
		targets[tribe.beats] = true
	expect_true(targets.size() == 8, "모든 종족이 정확히 한 종족에게만 진다")
	expect_true(Affinity.cycle("dragon").size() == 8, "한 바퀴로 이어진다(작은 고리로 끊기지 않음)")


func test_plan_a_order() -> void:
	expect_true(Affinity.cycle("spirit") == PackedStringArray(["spirit", "demon", "dragon", "flying", "insect", "plant", "machine", "beast"]), "추천 A: 정령 → 마 → 용 → 비행 → 곤충 → 식물 → 기계 → 야수 → 정령 (%s)" % [Affinity.cycle("spirit")])
	expect_true(Affinity.beats("dragon") == "flying" and Affinity.beaten_by("dragon") == "demon", "용족: 비행족에게 강하고 마족에게 약하다")
	expect_true(Affinity.beaten_by("spirit") == "beast" and Affinity.beats("beast") == "spirit", "야수족 → 정령족(한 바퀴 끝)")
	expect_true(Affinity.beaten_by("") == "" and Affinity.beats("no_such") == "", "모르는 종족은 상성 없음")


func test_relation_and_damage() -> void:
	expect_true(Affinity.relation("spirit", "demon") == Affinity.Relation.ADVANTAGE, "정령 → 마 = 유리")
	expect_true(Affinity.relation("demon", "spirit") == Affinity.Relation.DISADVANTAGE, "마 → 정령 = 불리")
	expect_true(Affinity.relation("dragon", "plant") == Affinity.Relation.NEUTRAL, "용 ↔ 식물 = 중립")
	expect_true(Affinity.relation("dragon", "dragon") == Affinity.Relation.NEUTRAL, "같은 종족 = 중립")
	expect_true(Affinity.relation("", "dragon") == Affinity.Relation.NEUTRAL and Affinity.relation("dragon", "") == Affinity.Relation.NEUTRAL, "종족 없음(주인공) = 중립")
	expect_near(GameConfig.AFFINITY_ADVANTAGE, 0.25, "유리 +25%(임시)")
	expect_near(GameConfig.AFFINITY_DISADVANTAGE, 0.2, "불리 −20%(임시)")
	expect_near(Affinity.damage_scale("dragon", "flying"), 1.25, "용 → 비행 피해 ×1.25")
	expect_near(Affinity.damage_scale("flying", "dragon"), 0.8, "비행 → 용 피해 ×0.8")
	expect_near(Affinity.damage_scale("dragon", "beast"), 1.0, "용 → 야수 피해 그대로")
	# 각 종족마다 유리 1 · 불리 1 · 중립 6(자기 포함)
	for id in TribeDb.ids():
		var counts := [0, 0, 0]
		for other in TribeDb.ids():
			counts[Affinity.relation(id, other)] += 1
		expect_true(counts == [6, 1, 1], "%s: 유리 1 · 불리 1 · 중립 6" % TribeDb.get_tribe(id).name)

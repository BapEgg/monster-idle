extends "res://tests/suite.gd"
## core/combat.gd, core/unit_stats.gd 테스트.


func test_heal_target_picks_lowest_below_threshold() -> void:
	var ratios: Array[float] = [0.9, 0.5, 0.3, 1.0]
	expect_true(Combat.heal_target_index(ratios, 0.75) == 2, "기준보다 낮은 것 중 가장 낮은 것(0.3)")


func test_heal_target_none_when_all_healthy() -> void:
	var ratios: Array[float] = [0.8, 1.0, 0.75]
	expect_true(Combat.heal_target_index(ratios, 0.75) == -1, "모두 기준 이상이면 없음(-1)")
	var empty: Array[float] = []
	expect_true(Combat.heal_target_index(empty, 0.75) == -1, "아무도 없으면 없음(-1)")


func test_tank_threat_is_multiplied() -> void:
	expect_near(Combat.threat(10.0, false), 10.0, "일반 위협 = 피해량")
	expect_near(Combat.threat(10.0, true), 10.0 * GameConfig.TANK_THREAT_SCALE, "탱커 위협 = 피해량 × 배율")


func test_wild_stats_are_weaker() -> void:
	for role: String in HenchSpecies.ROLES:
		var party := UnitStats.for_hench(role, false)
		var wild := UnitStats.for_hench(role, true)
		expect_near(wild.max_hp, party.max_hp * GameConfig.WILD_HP_SCALE, "%s 야생 체력 배율" % role)
		expect_near(wild.attack, party.attack * GameConfig.WILD_ATTACK_SCALE, "%s 야생 공격 배율" % role)


func test_only_ranged_roles_shoot() -> void:
	expect_true(UnitStats.for_player().attack_range <= GameConfig.MELEE_RANGE_MAX, "주인공은 근접")
	expect_true(UnitStats.for_hench("tank", false).attack_range <= GameConfig.MELEE_RANGE_MAX, "탱커는 근접")
	expect_true(UnitStats.for_hench("ranged", false).attack_range > GameConfig.MELEE_RANGE_MAX, "원거리는 투사체")
	expect_true(UnitStats.for_hench("healer", false).heal > 0.0, "힐러는 회복량이 있다")


func test_personal_space_smaller_than_melee_reach() -> void:
	expect_true(GameConfig.PERSONAL_SPACE < UnitStats.for_player().attack_range, "개인 공간 < 주인공 사거리")
	expect_true(GameConfig.PERSONAL_SPACE < UnitStats.for_hench("tank", false).attack_range, "개인 공간 < 근접 사거리")

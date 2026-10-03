extends "res://tests/suite.gd"
## core/growth.gd · core/player_progress.gd · Workshop 골드 레벨업 테스트(성장 1차, 기획서 8장 레벨 곡선 · 4장 헨치 레벨 상한).


## 기획서 8장: 첫날 15 · 1주 30 · 2주 40 · 3주 50 · 4주 60
func test_curve_hits_plan() -> void:
	for point: Array in [[15, 1.0], [30, 7.0], [40, 14.0], [50, 21.0], [60, 28.0]]:
		expect_near(Growth.days_to_reach(point[0]), point[1], "Lv %d = %.0f일째" % [point[0], point[1]])
	expect_near(Growth.kills_to_reach(15), GameConfig.MEASURED_DAILY_KILLS, "Lv 15까지 쌓인 처치 수 = 하루 처치 수")


func test_curve_always_slower() -> void:
	var rising := true
	var slower := true
	var last_cost := 0.0
	for level in range(1, GameConfig.MAX_LEVEL):
		var cost := Growth.kills_to_reach(level + 1) - Growth.kills_to_reach(level)
		rising = rising and cost > 0.0
		slower = slower and Growth.exp_to_next(level) >= Growth.exp_to_next(maxi(level - 1, 1))
		last_cost = cost
	expect_true(rising and last_cost > 0.0, "레벨마다 더 잡아야 오른다(처치 수가 늘 양수)")
	expect_true(slower, "다음 레벨 경험치가 줄지 않는다")
	expect_true(Growth.exp_to_next(GameConfig.MAX_LEVEL) == 0, "최고 레벨에서는 더 오르지 않는다")
	expect_true(Growth.days_to_reach(2) * 1000.0 < 20.0, "처음 레벨은 금방 오른다 (하루 1,000마리 기준 Lv 2까지 %.0f마리)" % (Growth.days_to_reach(2) * 1000.0))


func test_add_exp() -> void:
	var need := Growth.exp_to_next(1)
	expect_true(Growth.add_exp(1, 0, need - 1) == Vector2i(1, need - 1), "모자라면 그대로")
	expect_true(Growth.add_exp(1, 0, need) == Vector2i(2, 0), "딱 맞으면 한 레벨")
	var two := need + Growth.exp_to_next(2)
	expect_true(Growth.add_exp(1, 0, two + 3) == Vector2i(3, 3), "넘치면 여러 레벨, 남은 경험치는 이어진다")
	expect_true(Growth.add_exp(GameConfig.MAX_LEVEL - 1, 0, 100000000) == Vector2i(GameConfig.MAX_LEVEL, 0), "최고 레벨에서 멈춘다")
	var progress := PlayerProgress.new()
	var levels := []
	progress.leveled_up.connect(func(level: int) -> void: levels.append(level))
	expect_true(progress.gain(two) == 2 and progress.level == 3 and levels == [3], "PlayerProgress: 두 레벨 오르고 알림은 한 번(새 레벨)")


func test_rewards_and_stats() -> void:
	expect_true(Growth.exp_per_kill(10) > Growth.exp_per_kill(1) and Growth.gold_per_kill(10) > Growth.gold_per_kill(1), "높은 레벨 몹이 경험치 · 골드를 더 준다")
	expect_near(Growth.stat_scale(1), 1.0, "Lv 1 = 기본 능력치")
	var low := UnitStats.for_player(1)
	var high := UnitStats.for_player(11)
	expect_near(high.attack / low.attack, 1.0 + GameConfig.LEVEL_STAT_GROWTH * 10.0, "주인공 Lv 11 공격 = Lv 1 × (1 + 성장 × 10)")
	expect_true(UnitStats.for_hench("tank", true, 10).max_hp > UnitStats.for_hench("tank", true, 1).max_hp, "야생도 레벨만큼 세다")


## 기획서 4장: 헨치 레벨 상한 = 플레이어 레벨. 골드로 레벨업.
func test_hench_level_up() -> void:
	var bag := Bag.new()
	var wallet := Wallet.new()
	var shop := Workshop.new(bag, wallet)
	var item := CoreItem.new()
	item.species_id = "gochuryong"
	item.level = 3
	bag.add(item)
	shop.progress.level = 4
	expect_true(shop.level_up_problem(item) == Workshop.LevelUpProblem.NO_GOLD and not shop.level_up(item), "골드가 없으면 못 올린다")
	wallet.add_gold(100000)
	var cost := shop.level_up_cost(item)
	var leveled := []
	shop.core_leveled.connect(func(c: CoreItem) -> void: leveled.append(c))
	expect_true(shop.level_up(item) and item.level == 4 and wallet.gold == 100000 - cost and leveled == [item], "골드를 내고 한 레벨(비용 %d)" % cost)
	expect_true(shop.level_up_problem(item) == Workshop.LevelUpProblem.AT_CAP and not shop.level_up(item) and item.level == 4, "주인공 레벨(4)에서 멈춘다")
	expect_true(Growth.level_up_cost(20) > Growth.level_up_cost(10), "높은 레벨일수록 비싸다")

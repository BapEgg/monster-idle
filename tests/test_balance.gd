extends "res://tests/suite.gd"
## core/balance.gd 테스트: 기획서 8장 "드랍률 = 하루 목표 ÷ 하루 처치 수"와 확률 보너스 수확 체감 공식.


## 기획서 8장 예: 하루 1,000마리면 코어 1~1.5%(하루 10~15개)
func test_drop_chance_example() -> void:
	expect_near(Balance.drop_chance(10.0, 1000.0), 0.01, "하루 10개 ÷ 1,000마리 = 1%")
	expect_near(Balance.drop_chance(15.0, 1000.0), 0.015, "하루 15개 ÷ 1,000마리 = 1.5%")
	expect_near(Balance.chances_for(1000.0)["core"], 0.0125, "목표 범위의 가운데(12.5개) → 1.25%")
	expect_true(Balance.drop_chance(5.0, 0.0) == 0.0 and Balance.drop_chance(50.0, 10.0) == 1.0, "처치 수를 모르면 0, 1을 넘지 않음")


func test_targets_round_trip() -> void:
	var daily := GameConfig.MEASURED_DAILY_KILLS
	var c := Balance.chances_for(daily)
	var got := Balance.expected(daily, c["core"], c["shining"], c["variant"])
	expect_near(got["cores_per_day"], 12.5, "잰 처치 수 × 코어 확률 = 하루 12.5개(목표 10~15)")
	expect_near(got["shining_per_week"], 3.0, "빛나는 코어 = 주 3개")
	expect_near(got["variants_per_month"], 3.5, "변이체 = 월 3.5마리(목표 3~4)")
	expect_near(c["shining"], 3.0 / 7.0 / 12.5, "빛나는 비율 = (주 3개 ÷ 7일) ÷ 하루 코어 12.5개")


## 기획서 8장: 보너스를 모두 더한 B → 유효 = B × K ÷ (B + K) → 최종 = 기본 × (1 + 유효). 변이체 K = 50%
func test_bonus_diminishing() -> void:
	var k := GameConfig.VARIANT_BONUS_K
	expect_near(Balance.effective_bonus(k, k), k * 0.5, "B = K면 유효 보너스는 K의 절반")
	expect_near(Balance.effective_bonus(0.2, 0.5), 0.2 * 0.5 / 0.7, "B 20% · K 50% → 유효 약 14.3%")
	expect_true(Balance.effective_bonus(100.0, k) < k and Balance.effective_bonus(0.0, k) == 0.0, "아무리 더해도 K를 넘지 않음, 없으면 0")
	expect_near(Balance.with_bonus(0.01, 0.2, 0.5), 0.01 * (1.0 + 0.2 * 0.5 / 0.7), "최종 = 기본 × (1 + 유효)")
	expect_true(Balance.with_bonus(0.9, 100.0, k) == 1.0, "최종 확률은 1을 넘지 않음")
	expect_true(Balance.variant_chance(GameConfig.MANUAL_VARIANT_BONUS) > Balance.variant_chance(), "수동 중 변이체 우대")


func test_dev_boost() -> void:
	var real := Balance.core_chance()
	Balance.dev_boost = GameConfig.DEV_DROP_BOOST
	var boosted := Balance.core_chance()
	var shining := Balance.shining_chance()
	Balance.dev_boost = 1.0
	expect_near(boosted, minf(real * GameConfig.DEV_DROP_BOOST, 1.0), "드랍 확인 배율을 켜면 코어 확률 × %d" % roundi(GameConfig.DEV_DROP_BOOST))
	expect_near(shining, Balance.shining_chance(), "빛나는 비율은 배율과 상관없음")

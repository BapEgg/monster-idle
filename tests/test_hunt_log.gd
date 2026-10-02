extends "res://tests/suite.gd"
## core/hunt_log.gd 테스트: 하루 처치 수 측정(기획서 8장: 드랍률 = 하루 목표 ÷ 하루 처치 수).


func test_unknown_before_hunting() -> void:
	var record := HuntLog.new()
	expect_near(record.kills_per_hour(false), -1.0, "사냥 전에는 시간당 처치 수를 모른다")
	expect_near(record.daily_kills_estimate(), -1.0, "하루 예상도 모른다")
	expect_true(is_nan(record.manual_advantage()), "수동 이득도 모른다")


func test_rates_and_daily_estimate() -> void:
	var record := HuntLog.new()
	record.add_time(600.0, false)  # 자동 10분에 100마리 → 시간당 600
	for i in 100:
		record.add_kill(false)
	record.add_time(300.0, true)  # 수동 5분에 57마리 → 시간당 684 (자동보다 14% 많음)
	for i in 57:
		record.add_kill(true)
	expect_true(record.kills() == 157, "전체 처치 수")
	expect_near(record.kills_per_hour(false), 600.0, "자동 시간당 처치")
	expect_near(record.kills_per_hour(true), 684.0, "수동 시간당 처치")
	expect_near(record.daily_kills_estimate(), 14400.0, "하루 예상 = 자동 시간당 × 24")
	expect_near(record.manual_advantage(), 0.14, "수동 이득 14%(기획서 목표 10~20%)")


func test_plan_example_drop_rate() -> void:
	# 기획서 8장 예: 하루 1,000마리면 일반 코어(하루 10~15개) 드랍률은 1~1.5%
	var per_day := 1000.0
	expect_near(10.0 / per_day, 0.01, "하루 10개 목표 → 1%")
	expect_near(15.0 / per_day, 0.015, "하루 15개 목표 → 1.5%")


func test_core_count() -> void:
	var record := HuntLog.new()
	var plain := CoreItem.new()
	var shiny := CoreItem.new()
	shiny.shining = true
	record.add_core(plain)
	record.add_core(shiny)
	expect_true(record.cores == 2 and record.shining_cores == 1, "코어 수와 빛나는 코어 수")

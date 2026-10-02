extends "res://tests/suite.gd"
## core/auto_control.gd 테스트: "손대면 수동, 손 떼고 몇 초 뒤 자동".


func test_starts_auto() -> void:
	var control := AutoControl.new(3.0)
	expect_true(not control.is_manual(), "처음엔 자동")


func test_input_makes_manual_immediately() -> void:
	var control := AutoControl.new(3.0)
	control.update(0.016, true)
	expect_true(control.is_manual(), "만지면 바로 수동")
	expect_true(control.is_held(), "만지는 중")


func test_returns_to_auto_after_seconds() -> void:
	var control := AutoControl.new(3.0)
	control.update(0.016, true)
	control.update(2.9, false)
	expect_true(control.is_manual(), "손 떼고 2.9초 = 아직 수동")
	expect_true(not control.is_held(), "손 뗌")
	expect_near(control.seconds_until_auto(), 0.1, "자동까지 0.1초 남음")
	control.update(0.2, false)
	expect_true(not control.is_manual(), "3초 넘으면 자동")


func test_touch_again_resets_countdown() -> void:
	var control := AutoControl.new(3.0)
	control.update(0.016, true)
	control.update(2.5, false)
	control.update(0.016, true)
	control.update(2.5, false)
	expect_true(control.is_manual(), "다시 만지면 3초를 처음부터 센다")


func test_zero_seconds_returns_immediately() -> void:
	var control := AutoControl.new(0.0)
	control.update(0.016, true)
	expect_true(control.is_manual(), "대기 0초여도 만지는 동안은 수동")
	control.update(0.016, false)
	expect_true(not control.is_manual(), "대기 0초면 손 떼는 즉시 자동")

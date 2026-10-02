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


## 사냥 방식 3단계(사용자 결정 2026-10-02): 풀오토 / 세미오토(이동 직접, 공격 자동) / 수동(이동·공격 직접)
func test_full_auto_is_default() -> void:
	var control := AutoControl.new(0.0)
	expect_true(control.mode == AutoControl.Mode.FULL_AUTO, "기본은 풀오토")
	expect_true(control.auto_attacks(), "풀오토는 공격 자동")


func test_semi_auto_moves_by_hand_attacks_by_itself() -> void:
	var control := AutoControl.new(0.0, AutoControl.Mode.SEMI_AUTO)
	control.update(0.016, false)
	expect_true(control.is_manual(), "세미오토: 안 만져도 이동은 직접")
	expect_true(control.auto_attacks(), "세미오토: 공격은 자동")


func test_manual_attacks_by_hand() -> void:
	var control := AutoControl.new(0.0, AutoControl.Mode.MANUAL)
	control.update(0.016, false)
	expect_true(control.is_manual(), "수동: 이동 직접")
	expect_true(not control.auto_attacks(), "수동: 공격도 직접")


func test_switching_back_to_full_auto() -> void:
	var control := AutoControl.new(0.0, AutoControl.Mode.MANUAL)
	control.update(0.016, false)
	control.mode = AutoControl.Mode.FULL_AUTO
	expect_true(not control.is_manual(), "풀오토로 바꾸고 손을 안 대고 있으면 바로 자동")


## 오토 버튼(사용자 결정 2026-10-02): 누를 때마다 풀오토 → 세미오토 → 수동 → 풀오토
func test_auto_button_cycles_modes() -> void:
	expect_true(AutoControl.next_mode(AutoControl.Mode.FULL_AUTO) == AutoControl.Mode.SEMI_AUTO, "풀오토 → 세미오토")
	expect_true(AutoControl.next_mode(AutoControl.Mode.SEMI_AUTO) == AutoControl.Mode.MANUAL, "세미오토 → 수동")
	expect_true(AutoControl.next_mode(AutoControl.Mode.MANUAL) == AutoControl.Mode.FULL_AUTO, "수동 → 풀오토")

extends "res://tests/suite.gd"
## core/targeting.gd, core/hp_bar.gd 테스트: 몹을 눌러 대상 지정, 공격 버튼의 가까운 적 고르기, 체력 바 잔상.


func test_index_at_picks_nearest_under_finger() -> void:
	var points := PackedVector2Array([Vector2(0, 0), Vector2(30, 0), Vector2(100, 0)])
	expect_true(Targeting.index_at(points, Vector2(22, 0), 34.0) == 1, "누른 자리에서 가장 가까운 몹(30, 0)")
	expect_true(Targeting.index_at(points, Vector2(100, 30), 34.0) == 2, "반지름 안이면 고른다")
	expect_true(Targeting.index_at(points, Vector2(60, 60), 34.0) == -1, "반지름 밖이면 없음(-1)")
	expect_true(Targeting.index_at(PackedVector2Array(), Vector2.ZERO, 34.0) == -1, "몹이 없으면 없음(-1)")


func test_nearest_within_uses_ground_distance() -> void:
	# 화면 세로 150px는 땅 위 300px, 화면 가로 200px는 땅 위 200px → 가로 쪽이 더 가깝다
	var points := PackedVector2Array([Vector2(0, 150), Vector2(200, 0)])
	expect_true(Targeting.nearest_within(points, Vector2.ZERO, 420.0) == 1, "땅 위 거리로 가장 가까운 것")
	expect_true(Targeting.nearest_within(points, Vector2.ZERO, 150.0) == -1, "거리 밖이면 없음(-1)")


func test_hp_trail() -> void:
	expect_near(HpBar.next_trail(1.0, 0.6, 0.1), 1.0 - GameConfig.HP_TRAIL_SPEED * 0.1, "깎이면 잔상이 천천히 따라 내려옴")
	expect_near(HpBar.next_trail(1.0, 0.6, 10.0), 0.6, "잔상은 체력 아래로 내려가지 않음")
	expect_near(HpBar.next_trail(0.4, 0.7, 0.1), 0.7, "회복하면 바로 따라 올라감")


## 사용자 결정(2026-10-02): 같은 몹을 빨리 두 번 누르면 공격 버튼 없이 바로 공격
func test_double_tap() -> void:
	var window := roundi(GameConfig.DOUBLE_TAP_SECONDS * 1000.0)
	expect_true(Targeting.is_double_tap(1000, 1000 + window - 50, true), "같은 몹을 빨리 다시 누르면 더블 탭")
	expect_true(not Targeting.is_double_tap(1000, 1000 + window + 50, true), "너무 늦게 누르면 아님")
	expect_true(not Targeting.is_double_tap(1000, 1100, false), "다른 몹이면 아님")

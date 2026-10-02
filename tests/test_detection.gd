extends "res://tests/suite.gd"
## core/detection.gd 테스트: 선공 몬스터의 시야(정면 빨리 · 주변시 늦게 · 등 뒤 못 봄)와 감지 게이지.


func test_zones_by_angle() -> void:
	# 오른쪽을 보는 몬스터 기준
	expect_true(Detection.zone(Vector2.RIGHT, Vector2(200, 0)) == Detection.Zone.FRONT, "바로 앞 = 정면")
	expect_true(Detection.zone(Vector2.RIGHT, Vector2(0, -100)) == Detection.Zone.SIDE, "바로 옆(90도) = 주변시")
	expect_true(Detection.zone(Vector2.RIGHT, Vector2(-200, 0)) == Detection.Zone.BEHIND, "바로 뒤 = 등 뒤")
	expect_true(Detection.zone(Vector2.RIGHT, Vector2(-200, 30)) == Detection.Zone.BEHIND, "비스듬히 뒤 = 등 뒤")


func test_angle_is_measured_on_ground() -> void:
	# 화면에서는 22도지만, 세로를 펴서 땅 위에서 재면 39도 → 정면(35도)을 벗어나 주변시
	var offset := Vector2(100, 40)
	expect_near(rad_to_deg(Vector2.RIGHT.angle_to(offset)), 21.8, "화면 각도 22도", 0.1)
	expect_true(Detection.zone(Vector2.RIGHT, offset) == Detection.Zone.SIDE, "땅 위 각도 39도 = 주변시")


func test_fill_rate() -> void:
	expect_near(Detection.fill_rate(Vector2.RIGHT, Vector2(200, 0)), 1.0 / GameConfig.DETECT_FRONT_SECONDS, "정면: 정면 시간 만에 다 참")
	expect_near(Detection.fill_rate(Vector2.RIGHT, Vector2(0, 60)), 1.0 / GameConfig.DETECT_SIDE_SECONDS, "주변시: 주변시 시간 만에 다 참")
	expect_true(GameConfig.DETECT_FRONT_SECONDS < GameConfig.DETECT_SIDE_SECONDS, "정면이 주변시보다 빨리 알아챈다")
	expect_near(Detection.fill_rate(Vector2.RIGHT, Vector2(-100, 0)), 0.0, "등 뒤: 못 봄")
	var far := Vector2(GameConfig.DETECT_RANGE + 10.0, 0)
	expect_near(Detection.fill_rate(Vector2.RIGHT, far), 0.0, "감지 거리 밖: 못 봄")
	# 화면 세로로 떨어진 거리는 땅 위에서 두 배 → 화면 160px 아래는 땅 위 320px라 감지 거리(300) 밖
	expect_near(Detection.fill_rate(Vector2.DOWN, Vector2(0, 160)), 0.0, "화면 세로 거리는 땅 위로 펴서 잰다")


func test_gauge_fills_and_drains() -> void:
	var rate := 1.0 / GameConfig.DETECT_FRONT_SECONDS
	var gauge := Detection.next_gauge(0.0, rate, GameConfig.DETECT_FRONT_SECONDS * 0.5)
	expect_near(gauge, 0.5, "정면에서 절반 시간 = 절반")
	expect_near(Detection.next_gauge(gauge, rate, 10.0), 1.0, "1을 넘지 않음")
	expect_near(Detection.next_gauge(1.0, 0.0, GameConfig.DETECT_FORGET_SECONDS * 0.5), 0.5, "안 보이면 천천히 빠짐")
	expect_near(Detection.next_gauge(0.2, 0.0, 10.0), 0.0, "0 아래로 내려가지 않음")


func test_sneaking_from_side_beats_detection() -> void:
	# 주변시로 다가가면 감지 거리 끝에서 사거리까지 걷는 동안 다 알아채지 못한다(기습할 수 있다).
	# 정면으로 다가가면 그 전에 알아챈다.
	var walk_seconds := (GameConfig.DETECT_RANGE - GameConfig.PLAYER_STATS["attack_range"]) / GameConfig.PLAYER_SPEED
	expect_true(walk_seconds < GameConfig.DETECT_SIDE_SECONDS, "옆으로 다가가면 기습 가능 (걷는 %.2f초 < 주변시 %.1f초)" % [walk_seconds, GameConfig.DETECT_SIDE_SECONDS])
	expect_true(walk_seconds > GameConfig.DETECT_FRONT_SECONDS, "정면으로 다가가면 들킨다 (걷는 %.2f초 > 정면 %.1f초)" % [walk_seconds, GameConfig.DETECT_FRONT_SECONDS])

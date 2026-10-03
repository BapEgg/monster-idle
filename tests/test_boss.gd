extends "res://tests/suite.gd"
## 보스전 테스트: core/danger_shape.gd(장판 모양 · 피할 곳), core/boss_rules.gd(체력 구간 · 장판 차례), Iso.from_ground.

const MARGIN := 24.0


func test_ground_round_trip() -> void:
	var screen := Vector2(120, -45)
	expect_vec(Iso.from_ground(Iso.to_ground(screen)), screen, "땅 ↔ 화면 변환은 서로 반대")


func test_circle() -> void:
	var shape := DangerShape.circle(Vector2(100, 100), 80.0)
	expect_true(shape.contains(Vector2(100, 100)) and shape.contains(Vector2(170, 100)), "원 안")
	expect_true(not shape.contains(Vector2(190, 100)), "원 밖")
	expect_true(shape.contains(Vector2(100, 135)) and not shape.contains(Vector2(100, 145)), "화면 세로는 절반만 가도 땅 위로는 두 배(납작한 타원)")
	var out := shape.escape_point(Vector2(130, 110), MARGIN)
	expect_true(not shape.contains(out), "피할 곳은 원 밖")
	expect_near(Iso.ground_distance(Vector2(100, 100), out), 80.0 + MARGIN, "가운데에서 반지름 + 여유만큼", 0.5)
	expect_vec(shape.escape_point(Vector2(400, 400), MARGIN), Vector2(400, 400), "이미 밖이면 그 자리")


func test_cone() -> void:
	var shape := DangerShape.cone(Vector2.ZERO, Vector2.RIGHT, 300.0, 70.0)
	expect_true(shape.contains(Vector2(100, 0)) and shape.contains(Vector2(250, 40)), "보스 앞(오른쪽) 부채꼴 안")
	expect_true(not shape.contains(Vector2(-50, 0)), "보스 등 뒤는 안전")
	expect_true(not shape.contains(Vector2(100, 100)), "옆으로 넓게 벗어나면 안전")
	expect_true(not shape.contains(Vector2(320, 0)), "길이 밖은 안전")
	for point: Vector2 in [Vector2(100, 10), Vector2(200, -30), Vector2(290, 5), Vector2(5, 0)]:
		var out := shape.escape_point(point, MARGIN)
		expect_true(not shape.contains(out), "부채꼴 안 %s → 피할 곳 %s는 밖" % [point, out])
		expect_true(point.distance_to(out) < 300.0, "피할 곳이 너무 멀지 않다 (%.0f)" % point.distance_to(out))


func test_ring() -> void:
	var shape := DangerShape.ring(Vector2.ZERO, 100.0, 400.0)
	expect_true(not shape.contains(Vector2(50, 0)), "보스 곁(안쪽)은 안전")
	expect_true(shape.contains(Vector2(200, 0)) and not shape.contains(Vector2(450, 0)), "고리 안 / 바깥 끝 너머는 안전")
	var near := shape.escape_point(Vector2(150, 0), MARGIN)
	expect_true(not shape.contains(near) and Iso.ground_distance(Vector2.ZERO, near) < 100.0, "안쪽이 가까우면 보스 곁으로")
	var far := shape.escape_point(Vector2(390, 0), MARGIN)
	expect_true(not shape.contains(far) and Iso.ground_distance(Vector2.ZERO, far) > 400.0, "바깥이 가까우면 바깥으로")


func test_phases() -> void:
	var phases: Array = GameConfig.BOSS_PHASES
	expect_true(BossRules.phase_index(1.0) == 0 and BossRules.phase_index(0.01) == phases.size() - 1, "가득 = 첫 구간, 거의 0 = 마지막 구간")
	var first_until := float(phases[0]["until"])
	expect_true(BossRules.phase_index(first_until + 0.01) == 0 and BossRules.phase_index(first_until) == 1, "경계에서 다음 구간")
	var marks := BossRules.phase_marks()
	expect_true(marks.size() == phases.size() - 1 and marks[0] == first_until, "체력 바 눈금 = 구간 경계 %s" % [marks])
	var last := phases.size() - 1
	var seen := {}
	for i in (phases[last]["patterns"] as Array).size() * 2:
		seen[BossRules.pattern_at(last, i)] = true
	expect_true(seen.size() == (phases[last]["patterns"] as Array).size(), "마지막 구간은 장판을 차례대로 모두 쓴다")
	for phase: Dictionary in phases:
		for pattern: String in phase["patterns"]:
			expect_true(GameConfig.BOSS_PATTERNS.has(pattern), "장판 %s의 수치가 있다" % pattern)
	expect_true(HenchDb.get_species(GameConfig.BOSS_SPECIES) != null and HenchDb.get_species(GameConfig.BOSS_SPECIES).grade == "king", "연습 상대는 도감의 왕")

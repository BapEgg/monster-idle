extends "res://tests/suite.gd"
## core/iso.gd 테스트.


func test_grid_to_screen() -> void:
	var half := GameConfig.TILE_SIZE * 0.5
	expect_vec(Iso.grid_to_screen(Vector2.ZERO), Vector2.ZERO, "격자 원점 = 화면 원점")
	expect_vec(Iso.grid_to_screen(Vector2(1, 0)), Vector2(half.x, half.y), "격자 x 한 칸 = 화면 오른쪽 아래")
	expect_vec(Iso.grid_to_screen(Vector2(0, 1)), Vector2(-half.x, half.y), "격자 y 한 칸 = 화면 왼쪽 아래")
	expect_vec(Iso.grid_to_screen(Vector2(1, 1)), Vector2(0, GameConfig.TILE_SIZE.y), "대각선 한 칸 = 화면 바로 아래")


func test_screen_to_grid_round_trip() -> void:
	for grid: Vector2 in [Vector2(3, 7), Vector2(-2, 5.5), Vector2(10.25, 0.75)]:
		expect_vec(Iso.screen_to_grid(Iso.grid_to_screen(grid)), grid, "격자→화면→격자 %s" % grid)


func test_cell_center() -> void:
	expect_vec(Iso.cell_center(Vector2i.ZERO), Vector2(0, GameConfig.TILE_SIZE.y * 0.5), "(0,0) 칸 중심 = 마름모 가운데")


func test_field_polygon() -> void:
	var corners := Iso.field_polygon(Vector2i(10, 10))
	expect_true(corners.size() == 4, "꼭짓점 4개")
	expect_vec(corners[0], Vector2.ZERO, "위 꼭짓점 = 원점")
	expect_vec(corners[2], Vector2(0, GameConfig.TILE_SIZE.y * 10), "아래 꼭짓점 = 정확히 아래")


func test_ground_distance() -> void:
	var ratio := GameConfig.TILE_SIZE.x / GameConfig.TILE_SIZE.y
	expect_near(Iso.ground_distance(Vector2.ZERO, Vector2(100, 0)), 100.0, "가로는 그대로")
	expect_near(Iso.ground_distance(Vector2.ZERO, Vector2(0, 50)), 50.0 * ratio, "세로는 타일 비율만큼 펴서 잰다")
	var cell_step := Iso.grid_to_screen(Vector2(1, 0))
	var cell_step_other := Iso.grid_to_screen(Vector2(0, 1))
	expect_near(Iso.ground_distance(Vector2.ZERO, cell_step), Iso.ground_distance(Vector2.ZERO, cell_step_other), "격자 두 축 한 칸 길이가 같다")


func test_move_velocity_axes() -> void:
	expect_vec(Iso.move_velocity(Vector2.RIGHT, 200.0, 0.5), Vector2(200, 0), "오른쪽 = 제 속력")
	expect_vec(Iso.move_velocity(Vector2.LEFT, 200.0, 0.5), Vector2(-200, 0), "왼쪽 = 제 속력")
	expect_vec(Iso.move_velocity(Vector2.UP, 200.0, 0.5), Vector2(0, -100), "위 = 비율 0.5배 속력")
	expect_vec(Iso.move_velocity(Vector2.DOWN, 200.0, 1.0), Vector2(0, 200), "비율 1이면 세로도 제 속력")


func test_move_velocity_keeps_direction_and_ground_speed() -> void:
	for input: Vector2 in [Vector2(1, -1).normalized(), Vector2(-0.3, 0.9).normalized()]:
		var v := Iso.move_velocity(input, 200.0, 0.5)
		expect_near(v.angle(), input.angle(), "화면 방향은 입력 그대로 %s" % input)
		# 세로를 비율로 펴서 잰 땅 위 속력은 어느 방향이든 같다.
		expect_near(Vector2(v.x, v.y / 0.5).length(), 200.0, "땅 위 속력 일정 %s" % input)


func test_move_velocity_analog() -> void:
	expect_vec(Iso.move_velocity(Vector2.ZERO, 200.0, 0.5), Vector2.ZERO, "입력 없음 = 멈춤")
	expect_vec(Iso.move_velocity(Vector2(0.5, 0), 200.0, 0.5), Vector2(100, 0), "반만 기울이면 반 속력")
	expect_vec(Iso.move_velocity(Vector2(3, 0), 200.0, 0.5), Vector2(200, 0), "1보다 커도 최대 속력까지만")


func test_to_ground() -> void:
	var ratio := GameConfig.TILE_SIZE.x / GameConfig.TILE_SIZE.y
	expect_vec(Iso.to_ground(Vector2(30, 20)), Vector2(30, 20 * ratio), "세로만 타일 비율만큼 편다")
	expect_near(Iso.ground_distance(Vector2(5, 5), Vector2(35, 25)), Iso.to_ground(Vector2(30, 20)).length(), "땅 위 거리 = 편 차이의 길이")

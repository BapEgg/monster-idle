extends "res://tests/suite.gd"
## core/shapes.gd 테스트: 감지 전구의 차오르는 띠.


func test_bulb_fill_rows() -> void:
	var center := Vector2(10, -20)
	var radius := 8.0
	expect_true(Shapes.circle_fill_rows(center, radius, 0.0).is_empty(), "0이면 빈 전구")
	for ratio: float in [0.03, 0.5, 1.0]:
		var rows := Shapes.circle_fill_rows(center, radius, ratio)
		var height := 0.0
		var inside := true
		for row in rows:
			height += row.size.y
			inside = inside and row.position.y >= center.y - radius - 0.001 and row.end.y <= center.y + radius + 0.001
			inside = inside and row.position.x >= center.x - radius - 0.001 and row.end.x <= center.x + radius + 0.001
		expect_near(height, 2.0 * radius * ratio, "%.2f만큼 찬 높이" % ratio)
		expect_true(inside, "%.2f: 띠가 원 안에 있음" % ratio)
	var half := Shapes.circle_fill_rows(center, radius, 0.5)
	expect_near(half[half.size() - 1].size.x, 2.0 * radius, "절반이면 맨 위 띠가 원의 지름만큼 넓다", 0.5)
	expect_near(half[0].position.y + half[0].size.y, center.y + radius, "아래에서부터 찬다")

class_name Shapes
extends RefCounted
## 임시 도형 그림용 다각형 도우미. 그림이 들어오면 쓰임이 줄어든다.


## 타원 둘레의 점들.
static func ellipse(center: Vector2, radius: Vector2, points := 24) -> PackedVector2Array:
	var result := PackedVector2Array()
	for i in points:
		var angle := TAU * i / points
		result.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	return result


## 원호와, 시작·끝을 잇는 현으로 이뤄진 다각형. 각도는 오른쪽 0, 시계 방향(화면 y가 아래라서).
static func arc(center: Vector2, radius: float, from_angle: float, to_angle: float, points := 16) -> PackedVector2Array:
	var result := PackedVector2Array()
	for i in points + 1:
		var angle := lerpf(from_angle, to_angle, float(i) / points)
		result.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return result


## 원을 아래에서부터 ratio(0~1)만큼 채운 부분을 높이 1px짜리 가로 띠들로 나눈 것. 감지 전구의 차오르는 게이지에 쓴다.
## 다각형 하나로 그리면 아주 조금 찼을 때(가는 조각) 삼각형 나누기가 실패해 오류가 나므로 띠로 그린다.
static func circle_fill_rows(center: Vector2, radius: float, ratio: float) -> Array[Rect2]:
	var rows: Array[Rect2] = []
	var height := 2.0 * radius * clampf(ratio, 0.0, 1.0)
	var bottom := center.y + radius
	var filled := 0.0
	while filled < height:
		var band := minf(1.0, height - filled)
		var dy := (bottom - filled - band * 0.5) - center.y  # 띠 가운데가 원 중심에서 떨어진 높이
		var half := sqrt(maxf(radius * radius - dy * dy, 0.0))
		rows.append(Rect2(center.x - half, bottom - filled - band, half * 2.0, band))
		filled += band
	return rows


## 닫힌 다각형의 테두리 선을 그린다. canvas의 _draw() 안에서만 부른다.
static func draw_outline(canvas: CanvasItem, polygon: PackedVector2Array, color: Color, width: float) -> void:
	var closed := polygon.duplicate()
	closed.append(polygon[0])
	canvas.draw_polyline(closed, color, width, true)

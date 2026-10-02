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


## 닫힌 다각형의 테두리 선을 그린다. canvas의 _draw() 안에서만 부른다.
static func draw_outline(canvas: CanvasItem, polygon: PackedVector2Array, color: Color, width: float) -> void:
	var closed := polygon.duplicate()
	closed.append(polygon[0])
	canvas.draw_polyline(closed, color, width, true)

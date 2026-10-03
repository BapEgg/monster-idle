class_name BossZone
extends Node2D
## 보스 장판(임시 도형): 빨간 경고가 windup초 동안 차오르고, 다 차면 터진다(detonated). 터진 뒤 잠깐 번쩍였다가 사라진다.
## 판정 모양은 DangerShape(땅 위 거리)이고, 그림은 그 모양을 화면에 맞춰 납작하게 그린 것이다.
## 원 · 부채꼴은 가운데부터, 고리는 바깥부터 안쪽으로 차오른다(보스 곁이 안전하다는 뜻).
## 시간은 물리 프레임으로 센다(실행 검사·느린 기기에서도 판정 시각이 같게).

signal detonated(zone: BossZone)

const FLASH_SECONDS := 0.25
const POINTS := 48
const EDGE := 3.0

var shape: DangerShape
var windup := 1.0

var _time := 0.0
var _done := false
var _flash_left := 0.0


func setup(of_shape: DangerShape, seconds: float) -> void:
	shape = of_shape
	windup = maxf(seconds, 0.01)
	position = of_shape.center


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF


## 아직 안 터졌나.
func is_pending() -> bool:
	return not _done


## 차오른 비율(0~1).
func progress() -> float:
	return clampf(_time / windup, 0.0, 1.0)


func _physics_process(delta: float) -> void:
	if _done:
		_flash_left -= delta
		if _flash_left <= 0.0:
			queue_free()
	else:
		_time += delta
		if _time >= windup:
			_done = true
			_flash_left = FLASH_SECONDS
			detonated.emit(self)
	queue_redraw()


func _draw() -> void:
	if _done:
		_fill(1.0, Color(Palette.DANGER_FLASH, Palette.DANGER_FLASH.a * _flash_left / FLASH_SECONDS))
		return
	_fill(1.0, Palette.DANGER_FILL)
	_fill(progress(), Palette.DANGER_PROGRESS)
	_outline()


## 모양을 ratio만큼(원·부채꼴 = 반지름, 고리 = 바깥에서 안쪽으로) 칠한다. 너무 작으면(1px 미만) 칠하지 않는다.
func _fill(ratio: float, color: Color) -> void:
	match shape.kind:
		DangerShape.Kind.CIRCLE:
			if shape.radius * ratio >= 1.0:
				draw_colored_polygon(_arc(shape.radius * ratio, 0.0, TAU, false, false), color)
		DangerShape.Kind.CONE:
			if shape.radius * ratio >= 1.0:
				draw_colored_polygon(_cone(shape.radius * ratio), color)
		DangerShape.Kind.RING:
			var inner := shape.radius - (shape.radius - shape.inner) * ratio
			if shape.radius - inner < 1.0:
				return
			var outer_points := _arc(shape.radius, 0.0, TAU, false)
			var inner_points := _arc(inner, 0.0, TAU, false)
			for i in POINTS:
				draw_colored_polygon(PackedVector2Array([outer_points[i], outer_points[i + 1], inner_points[i + 1], inner_points[i]]), color)


func _outline() -> void:
	match shape.kind:
		DangerShape.Kind.CIRCLE:
			draw_polyline(_arc(shape.radius, 0.0, TAU, false), Palette.DANGER_EDGE, EDGE, true)
		DangerShape.Kind.CONE:
			var points := _cone(shape.radius)
			points.append(points[0])
			draw_polyline(points, Palette.DANGER_EDGE, EDGE, true)
		DangerShape.Kind.RING:
			draw_polyline(_arc(shape.radius, 0.0, TAU, false), Palette.DANGER_EDGE, EDGE, true)
			draw_polyline(_arc(shape.inner, 0.0, TAU, false), Palette.DANGER_EDGE, EDGE, true)


## 땅 위 원호(반지름 radius, 각도 from~to)를 화면 점들로. closed면 마지막 점이 첫 점과 같다(선 긋기용).
## 칠할 때(draw_colored_polygon)는 겹치는 점이 있으면 삼각형 나누기가 실패하므로 closed = false.
func _arc(radius: float, from: float, to: float, with_center: bool, closed := true) -> PackedVector2Array:
	var points := PackedVector2Array()
	if with_center:
		points.append(Vector2.ZERO)
	for i in (POINTS + 1 if closed else POINTS):
		var angle := lerpf(from, to, float(i) / POINTS)
		points.append(Iso.from_ground(Vector2.from_angle(angle) * radius))
	return points


func _cone(radius: float) -> PackedVector2Array:
	var middle := shape.direction.angle()
	return _arc(radius, middle - shape.half_angle, middle + shape.half_angle, true)

class_name DangerShape
extends RefCounted
## 보스 장판의 모양(순수 계산). 판정은 모두 땅 위 거리(Iso.to_ground)로 하므로 화면에서는 납작한 타원·부채꼴로 보인다.
## - 원(CIRCLE): center에서 radius 안
## - 부채꼴(CONE): center(보스)에서 direction 쪽으로 radius 길이, 좌우 half_angle 안
## - 고리(RING): center에서 inner 바깥 ~ radius 안(보스에게 바짝 붙으면 안전)
## escape_point는 그 자리에서 가장 가까운 안전한 곳(자동 회피가 걸어가는 곳)이다.

enum Kind { CIRCLE, CONE, RING }

var kind := Kind.CIRCLE
## 가운데(화면 좌표, 필드 기준)
var center := Vector2.ZERO
## 바깥 반지름(땅 위 px)
var radius := 0.0
## 고리의 안쪽 반지름(땅 위 px)
var inner := 0.0
## 부채꼴이 향하는 쪽(땅 위 방향, 길이 1)
var direction := Vector2.RIGHT
## 부채꼴의 반쪽 각도(라디안)
var half_angle := 0.0


static func circle(at: Vector2, of_radius: float) -> DangerShape:
	var shape := DangerShape.new()
	shape.kind = Kind.CIRCLE
	shape.center = at
	shape.radius = of_radius
	return shape


## toward = 화면에서 본 방향(보스 → 대상). angle_degrees = 부채꼴 전체 각도.
static func cone(origin: Vector2, toward: Vector2, of_radius: float, angle_degrees: float) -> DangerShape:
	var shape := DangerShape.new()
	shape.kind = Kind.CONE
	shape.center = origin
	shape.radius = of_radius
	var ground := Iso.to_ground(toward)
	shape.direction = ground.normalized() if ground.length() > 0.001 else Vector2.RIGHT
	shape.half_angle = deg_to_rad(angle_degrees) * 0.5
	return shape


static func ring(at: Vector2, of_inner: float, of_radius: float) -> DangerShape:
	var shape := DangerShape.new()
	shape.kind = Kind.RING
	shape.center = at
	shape.inner = of_inner
	shape.radius = of_radius
	return shape


## 그 자리(화면 좌표)가 장판 안인가.
func contains(point: Vector2) -> bool:
	var offset := Iso.to_ground(point - center)
	var distance := offset.length()
	match kind:
		Kind.CIRCLE:
			return distance <= radius
		Kind.CONE:
			if distance > radius:
				return false
			return distance < 0.001 or absf(direction.angle_to(offset)) <= half_angle
		Kind.RING:
			return distance >= inner and distance <= radius
	return false


## 그 자리에서 가장 가까운 안전한 곳(화면 좌표). 장판 밖이면 그 자리 그대로. margin = 경계에서 더 나갈 거리(땅 위 px).
func escape_point(point: Vector2, margin: float) -> Vector2:
	if not contains(point):
		return point
	var offset := Iso.to_ground(point - center)
	var away := offset.normalized() if offset.length() > 0.001 else Vector2.RIGHT
	match kind:
		Kind.CIRCLE:
			return center + Iso.from_ground(away * (radius + margin))
		Kind.RING:
			# 안쪽(보스 곁)이 대개 더 가깝다. 바깥이 더 가까우면 바깥으로.
			var to_inside := offset.length() - inner
			var to_outside := radius - offset.length()
			var target := away * maxf(inner - margin, 0.0) if to_inside <= to_outside else away * (radius + margin)
			return center + Iso.from_ground(target)
		Kind.CONE:
			return center + Iso.from_ground(_cone_escape(offset, margin))
	return point


## 부채꼴 밖으로: 가까운 옆 가장자리 바깥(수직으로) 또는 끝(반지름) 바깥 중 가까운 쪽.
func _cone_escape(offset: Vector2, margin: float) -> Vector2:
	var side := 1.0 if direction.cross(offset) >= 0.0 else -1.0
	var edge := direction.rotated(side * half_angle)
	var normal := edge.rotated(side * PI * 0.5)  # 부채꼴 바깥쪽
	var to_edge := absf(edge.cross(offset))
	var sideways := offset + normal * (to_edge + margin)
	var beyond := offset.normalized() * (radius + margin)
	return sideways if to_edge + margin <= (beyond - offset).length() else beyond

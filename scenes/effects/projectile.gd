class_name Projectile
extends Node2D
## 원거리 공격의 탄(임시 도형: 작은 원). 대상을 따라 날아가 닿으면 피해를 준다.
## 날아가는 사이 대상이 쓰러지거나 사라지면 그냥 없어진다.

const RADIUS := 5.0

var _source: Unit
var _target: Unit
var _damage := 0.0


func setup(source: Unit, target: Unit, damage: float) -> void:
	_source = source
	_target = target
	_damage = damage
	position = source.position + source.body_center()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_target) or not _target.is_alive():
		queue_free()
		return
	var goal := _target.position + _target.body_center()
	var step := GameConfig.PROJECTILE_SPEED * delta
	if position.distance_to(goal) <= step:
		_target.take_damage(_damage, _source if is_instance_valid(_source) else null)
		queue_free()
		return
	position += (goal - position).normalized() * step


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS + 1.5, Palette.OUTLINE, true, -1.0, true)
	draw_circle(Vector2.ZERO, RADIUS, Palette.PROJECTILE, true, -1.0, true)

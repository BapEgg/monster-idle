class_name SkillBeam
extends Node2D
## 일직선 스킬 연출(임시 도형, 관통 화살): 바닥에 빛줄기가 잠깐 남았다 사라진다. 그림 단계에서 바꾼다.

const SECONDS := 0.4

var from := Vector2.ZERO
var to := Vector2.ZERO
## 땅 위 폭(px). 화면에서는 쿼터뷰만큼 얇아질 수 있지만 임시라 그대로 그린다.
var width := 30.0
var color := Color.WHITE

var _time := 0.0


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF


func _process(delta: float) -> void:
	_time += delta
	if _time >= SECONDS:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var fade := 1.0 - _time / SECONDS
	draw_line(from - position, to - position, Color(color, 0.25 * fade), width, true)
	draw_line(from - position, to - position, Color(color, 0.9 * fade), maxf(width * 0.2, 2.0), true)

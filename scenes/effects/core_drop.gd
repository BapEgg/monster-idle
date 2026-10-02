class_name CoreDrop
extends Node2D
## 떨어진 코어(메이플키우기 방식): 몹 자리에서 튀어 올랐다가 땅에 떨어지고, 잠깐 뒤 주인공에게 빨려 들어간다.
## 주인공 몸에 닿으면 collected 신호를 보내고 사라진다. 원점 = 땅(그림자 자리)이라 y정렬로 앞뒤가 맞는다.
## 그림은 종 색 보석으로 대체한다(빛나는 코어는 금빛 테두리와 반짝임). 시간·높이 수치는 GameConfig.CORE_*.

signal collected(item: CoreItem)

# 임시 도형 치수(px). 그림이 들어오면 사라진다.
const GEM_HALF := Vector2(6, 9)
const SHADOW_RADIUS := Vector2(7, 3)
const SHINE_RADIUS := 13.0
const SHINE_PULSE := 8.0
const OUTLINE_WIDTH := 1.5
## 주인공 몸 가운데에서 이만큼 가까워지면 주운 것으로 본다.
const COLLECT_DISTANCE := 10.0

enum Phase { POP, REST, FLY }

var item: CoreItem
var color := Color.WHITE
## 빨려 들어갈 대상(주인공)
var target: Unit

var _phase := Phase.POP
var _time := 0.0
var _from := Vector2.ZERO
var _to := Vector2.ZERO
var _height := 0.0  # 땅에서 뜬 높이(px)
var _speed := 0.0


## at = 떨어지는 자리(몹 발밑), scatter = 튀어 나가 내려앉을 자리까지의 차이.
func setup(at: Vector2, scatter: Vector2, of_item: CoreItem, of_color: Color, to_unit: Unit) -> void:
	position = at
	_from = at
	_to = at + scatter
	item = of_item
	color = of_color
	target = to_unit
	_speed = GameConfig.CORE_FLY_SPEED


## 땅에서 뜬 높이(px). 실행 검사에서 튀어 오르는지 볼 때 쓴다.
func height() -> float:
	return _height


func _ready() -> void:
	# 물리 프레임이 아니라 화면 프레임에서 움직이므로 물리 보간을 끈다.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF


func _process(delta: float) -> void:
	_time += delta
	match _phase:
		Phase.POP:
			var t := minf(_time / GameConfig.CORE_POP_SECONDS, 1.0)
			position = _from.lerp(_to, t)
			_height = 4.0 * GameConfig.CORE_POP_HEIGHT * t * (1.0 - t)  # 포물선: 가운데에서 가장 높다
			if t >= 1.0:
				_next(Phase.REST)
		Phase.REST:
			if _time >= GameConfig.CORE_REST_SECONDS:
				_next(Phase.FLY)
		Phase.FLY:
			_fly(delta)
	queue_redraw()


func _next(phase: Phase) -> void:
	_phase = phase
	_time = 0.0
	_height = 0.0


## 주인공 몸 가운데를 향해 점점 빨라지며 날아간다. 땅 위 자리와 높이를 함께 좁힌다.
func _fly(delta: float) -> void:
	if not is_instance_valid(target):
		queue_free()
		return
	_speed += GameConfig.CORE_FLY_ACCEL * delta
	var goal_height := -target.body_center().y
	var gap := Vector2(target.position.x - position.x, target.position.y - position.y - (goal_height - _height))
	var step := _speed * delta
	if gap.length() <= maxf(step, COLLECT_DISTANCE):
		collected.emit(item)
		queue_free()
		return
	var k := step / gap.length()
	position = position.lerp(target.position, k)
	_height = lerpf(_height, goal_height, k)


func _draw() -> void:
	var lift := Vector2(0, -_height)
	var shadow := 1.0 - clampf(_height / (GameConfig.CORE_POP_HEIGHT * 2.0), 0.0, 0.7)
	draw_colored_polygon(Shapes.ellipse(Vector2.ZERO, SHADOW_RADIUS * shadow), Palette.SHADOW)
	draw_gem(self, lift + Vector2(0, -GEM_HALF.y), color, item.shining, _time)


## 보석 하나(코어 임시 그림)를 그린다. 가방 창의 코어 칸도 같이 쓴다. canvas의 _draw() 안에서만 부른다.
static func draw_gem(canvas: CanvasItem, center: Vector2, fill: Color, shining: bool, time := 0.0) -> void:
	if shining:
		var glow := Palette.CORE_SHINE
		glow.a = 0.25 + 0.15 * sin(time * SHINE_PULSE)
		canvas.draw_circle(center, SHINE_RADIUS, glow, true, -1.0, true)
	var gem := PackedVector2Array([
		center + Vector2(0, -GEM_HALF.y), center + Vector2(GEM_HALF.x, -GEM_HALF.y * 0.25),
		center + Vector2(0, GEM_HALF.y), center + Vector2(-GEM_HALF.x, -GEM_HALF.y * 0.25),
	])
	canvas.draw_colored_polygon(gem, fill)
	canvas.draw_line(gem[3], gem[1], Palette.CORE_GLINT, 1.0, true)  # 윗면 반짝임
	Shapes.draw_outline(canvas, gem, Palette.CORE_SHINE if shining else Palette.CORE_OUTLINE, OUTLINE_WIDTH)

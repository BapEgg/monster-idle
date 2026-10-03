class_name Field
extends Node2D
## 필드(섬의 한 지역): 바닥, 가장자리 벽, 장식물(나무·바위), 길찾기, 숫자·투사체 같은 연출.
## 필드 위에서 움직이거나 서 있는 것은 모두 Objects 아래에 둔다.
## Objects는 y정렬이 켜져 있어서 발밑이 화면 아래쪽일수록 앞에 그려진다.
## Effects는 그보다 위(z_index)에 그려서 숫자·투사체가 나무에 가려지지 않는다.
## GroundEffects는 바닥 바로 위(유닛보다 아래)에 그리는 연출(스킬 범위 고리)이다.

@onready var objects: Node2D = $Objects
@onready var effects: Node2D = $Effects
@onready var ground_effects: Node2D = $GroundEffects

## 길찾기 격자. 장식물이 있는 칸은 막힌 칸이다.
var _grid := AStarGrid2D.new()


func _ready() -> void:
	_build_edge_wall()
	_build_grid()
	_scatter_props()


## 주인공이 처음 서는 칸(필드 한가운데).
## 칸 번호는 정수여야 하므로 소수점 버림은 의도한 것이다(칸 수가 홀수여도 가운데 칸이 나온다).
func spawn_cell() -> Vector2i:
	@warning_ignore("integer_division")
	return GameConfig.FIELD_CELLS / 2


## 주인공이 처음 서는 자리(가운데 칸의 중심).
func spawn_position() -> Vector2:
	return Iso.cell_center(spawn_cell())


## 필드를 감싸는 사각형. 카메라 한계에 쓴다.
func bounds() -> Rect2:
	var corners := Iso.field_polygon(GameConfig.FIELD_CELLS)
	var rect := Rect2(corners[0], Vector2.ZERO)
	for corner in corners:
		rect = rect.expand(corner)
	return rect


# ─── 칸·길찾기 ─────────────────────────────────────

## 화면 좌표가 놓인 칸.
func cell_at(point: Vector2) -> Vector2i:
	return Vector2i(Iso.screen_to_grid(point).floor())


## 걸어갈 수 있는 자리인가(필드 안이고 장식물 칸이 아님).
func is_walkable(point: Vector2) -> bool:
	var cell := cell_at(point)
	return _grid.is_in_boundsv(cell) and not _grid.is_point_solid(cell)


## from에서 to까지 거쳐 갈 지점들(화면 좌표). 마지막 점은 to.
## 같은 칸이거나 길을 못 찾으면 빈 배열 → 곧장 걸어간다(지형에 부딪히면 미끄러져 지나간다).
func find_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	var start := cell_at(from)
	var goal := cell_at(to)
	if start == goal or not _grid.is_in_boundsv(start) or not _grid.is_in_boundsv(goal) or _grid.is_point_solid(start):
		return points
	var cells := _grid.get_id_path(start, goal, true)  # true: 목표가 막혀 있으면 가장 가까운 곳까지
	for i in range(1, cells.size()):
		points.append(Iso.cell_center(cells[i]))
	if not cells.is_empty() and cells[cells.size() - 1] == goal:
		points[points.size() - 1] = to
	return points


## 막히지 않은 칸 중 하나를 고른다. away_from에서 min_cells칸 이상 떨어진 곳으로.
func random_free_cell(rng: RandomNumberGenerator, away_from: Vector2, min_cells: float) -> Vector2i:
	var cells := GameConfig.FIELD_CELLS
	var away := Iso.screen_to_grid(away_from)
	for attempt in 200:
		var cell := Vector2i(rng.randi_range(1, cells.x - 2), rng.randi_range(1, cells.y - 2))
		if not _grid.is_point_solid(cell) and Vector2(cell).distance_to(away) >= min_cells:
			return cell
	return spawn_cell()


# ─── 연출 ────────────────────────────────────────

## 떠오르는 숫자(피해·회복).
func show_number(at: Vector2, text: String, color: Color) -> void:
	var number := FloatingNumber.new()
	number.text = text
	number.color = color
	number.position = at
	effects.add_child(number)


## 스킬 범위 연출: 그 자리(발밑)에 땅 위 반지름 radius(px)의 고리가 퍼지며 사라진다.
func show_burst(at: Vector2, radius: float, color: Color) -> void:
	var burst := SkillBurst.new()
	burst.position = at
	burst.radius = radius
	burst.color = color
	ground_effects.add_child(burst)


## 보스 장판을 바닥 위(유닛 아래)에 깐다.
func add_danger(zone: BossZone) -> void:
	ground_effects.add_child(zone)


## 그 자리가 (min_progress 이상 차오른) 아직 안 터진 장판 안이면 가장 가까운 안전한 곳, 아니면 Vector2.INF.
## 안전한 곳 = 어느 장판에도 들지 않고 걸어갈 수 있는 곳. 먼저 각 장판의 출구(DangerShape.escape_point)를 보고,
## 장판이 겹쳐 출구가 다른 장판 안이면 둘레를 훑는다(GameConfig.DODGE_SEARCH_*). 그래도 없으면 첫 장판의 출구.
func escape_point(at: Vector2, min_progress: float) -> Vector2:
	var zones: Array[BossZone] = []
	var inside: Array[BossZone] = []
	for node in ground_effects.get_children():
		var zone := node as BossZone
		if zone != null and zone.is_pending():
			zones.append(zone)
			if zone.progress() >= min_progress and zone.shape.contains(at):
				inside.append(zone)
	if inside.is_empty():
		return Vector2.INF
	var fallback := inside[0].shape.escape_point(at, GameConfig.DODGE_MARGIN)
	var candidates: Array[Vector2] = []
	for zone in inside:
		candidates.append(zone.shape.escape_point(at, GameConfig.DODGE_MARGIN))
	var best := Vector2.INF
	var best_distance := INF
	for point in candidates:
		if _is_safe(point, zones) and Iso.ground_distance(at, point) < best_distance:
			best = point
			best_distance = Iso.ground_distance(at, point)
	if best != Vector2.INF:
		return best
	for step in range(1, GameConfig.DODGE_SEARCH_STEPS + 1):
		for i in GameConfig.DODGE_SEARCH_DIRECTIONS:
			var ground := Vector2.from_angle(TAU * i / GameConfig.DODGE_SEARCH_DIRECTIONS) * GameConfig.DODGE_SEARCH_STEP * step
			var point := at + Iso.from_ground(ground)
			if _is_safe(point, zones):
				return point  # 가까운 걸음부터 보므로 처음 찾은 곳이 (거의) 가장 가깝다
	return fallback


func _is_safe(point: Vector2, zones: Array[BossZone]) -> bool:
	if not is_walkable(point):
		return false
	for zone in zones:
		if zone.shape.contains(point):
			return false
	return true


## 아직 안 터진 장판이 있나.
func has_danger() -> bool:
	for node in ground_effects.get_children():
		var zone := node as BossZone
		if zone != null and zone.is_pending():
			return true
	return false


## 깔린 장판을 모두 치운다(보스전이 끝났을 때).
func clear_dangers() -> void:
	for node in ground_effects.get_children():
		if node is BossZone:
			node.queue_free()


## 원거리 공격: 투사체를 날려 닿으면 피해를 준다.
func shoot(from: Unit, to: Unit, damage: float) -> void:
	var bullet := Projectile.new()
	bullet.setup(from, to, damage)
	effects.add_child(bullet)
	bullet.reset_physics_interpolation()


# ─── 만들기 ──────────────────────────────────────

## 필드 가장자리에 보이지 않는 벽을 둘러 바다로 못 나가게 한다.
func _build_edge_wall() -> void:
	var edge := CollisionPolygon2D.new()
	edge.build_mode = CollisionPolygon2D.BUILD_SEGMENTS
	edge.polygon = Iso.field_polygon(GameConfig.FIELD_CELLS)
	var wall := StaticBody2D.new()
	wall.name = "EdgeWall"
	wall.add_child(edge)
	add_child(wall)


func _build_grid() -> void:
	_grid.region = Rect2i(Vector2i.ZERO, GameConfig.FIELD_CELLS)
	_grid.cell_size = Vector2.ONE
	# 대각선(= 화면 가로·세로)으로도 가되, 막힌 칸 모서리를 깎아 지나가지는 않는다.
	_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_grid.update()


## 나무·바위를 흩어 놓는다. 씨앗이 같으면 매번 같은 배치가 나온다.
func _scatter_props() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = GameConfig.FIELD_SEED
	_place_props(FieldProp.Kind.TREE, GameConfig.FIELD_TREE_COUNT, rng)
	_place_props(FieldProp.Kind.ROCK, GameConfig.FIELD_ROCK_COUNT, rng)


func _place_props(kind: FieldProp.Kind, count: int, rng: RandomNumberGenerator) -> void:
	var cells := GameConfig.FIELD_CELLS
	var spawn := Vector2(spawn_cell())
	var placed := 0
	var attempts := 0
	while placed < count and attempts < count * 20:
		attempts += 1
		# 가장자리 한 줄은 비운다.
		var cell := Vector2i(rng.randi_range(1, cells.x - 2), rng.randi_range(1, cells.y - 2))
		if _grid.is_point_solid(cell) or Vector2(cell).distance_to(spawn) < GameConfig.FIELD_SPAWN_CLEAR_CELLS:
			continue
		_grid.set_point_solid(cell)
		var prop := FieldProp.new()
		prop.kind = kind
		prop.position = Iso.cell_center(cell) + Vector2(rng.randf_range(-16, 16), rng.randf_range(-8, 8))
		objects.add_child(prop)
		placed += 1

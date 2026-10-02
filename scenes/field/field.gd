class_name Field
extends Node2D
## 필드(섬의 한 지역): 바닥, 가장자리 벽, 장식물(나무·바위).
## 필드 위에서 움직이거나 서 있는 것은 모두 Objects 아래에 둔다.
## Objects는 y정렬이 켜져 있어서 발밑이 화면 아래쪽일수록 앞에 그려진다.

@onready var objects: Node2D = $Objects


func _ready() -> void:
	_build_edge_wall()
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


## 필드 가장자리에 보이지 않는 벽을 둘러 바다로 못 나가게 한다.
func _build_edge_wall() -> void:
	var edge := CollisionPolygon2D.new()
	edge.build_mode = CollisionPolygon2D.BUILD_SEGMENTS
	edge.polygon = Iso.field_polygon(GameConfig.FIELD_CELLS)
	var wall := StaticBody2D.new()
	wall.name = "EdgeWall"
	wall.add_child(edge)
	add_child(wall)


## 나무·바위를 흩어 놓는다. 씨앗이 같으면 매번 같은 배치가 나온다.
func _scatter_props() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = GameConfig.FIELD_SEED
	var taken := {}
	_place_props(FieldProp.Kind.TREE, GameConfig.FIELD_TREE_COUNT, rng, taken)
	_place_props(FieldProp.Kind.ROCK, GameConfig.FIELD_ROCK_COUNT, rng, taken)


func _place_props(kind: FieldProp.Kind, count: int, rng: RandomNumberGenerator, taken: Dictionary) -> void:
	var cells := GameConfig.FIELD_CELLS
	var spawn := Vector2(spawn_cell())
	var placed := 0
	var attempts := 0
	while placed < count and attempts < count * 20:
		attempts += 1
		# 가장자리 한 줄은 비운다.
		var cell := Vector2i(rng.randi_range(1, cells.x - 2), rng.randi_range(1, cells.y - 2))
		if taken.has(cell) or Vector2(cell).distance_to(spawn) < GameConfig.FIELD_SPAWN_CLEAR_CELLS:
			continue
		taken[cell] = true
		var prop := FieldProp.new()
		prop.kind = kind
		prop.position = Iso.cell_center(cell) + Vector2(rng.randf_range(-16, 16), rng.randf_range(-8, 8))
		objects.add_child(prop)
		placed += 1

class_name FieldProp
extends StaticBody2D
## 필드 장식물(나무·바위). 지나갈 수 없고, 주인공이 뒤로 가면 가려진다.
## 원점 = 바닥 중심(y정렬 기준). 그림은 도형으로 대체한다.

enum Kind { TREE, ROCK }

# 임시 도형 치수(px). 그림이 들어오면 사라진다.
const OUTLINE_WIDTH := 2.0
const TREE_FOOT := Vector2(14, 7)
const TREE_SHADOW := Vector2(28, 11)
const TREE_TRUNK := Rect2(-7, -38, 14, 38)
const ROCK_FOOT := Vector2(26, 12)
const ROCK_SHADOW := Vector2(32, 12)
const ROCK_BODY_CENTER := Vector2(0, -14)
const ROCK_BODY := Vector2(28, 18)

@export var kind := Kind.TREE


func _ready() -> void:
	var foot := CollisionPolygon2D.new()
	foot.polygon = Shapes.ellipse(Vector2.ZERO, TREE_FOOT if kind == Kind.TREE else ROCK_FOOT, 12)
	add_child(foot)


func _draw() -> void:
	match kind:
		Kind.TREE:
			_draw_tree()
		Kind.ROCK:
			_draw_rock()


func _draw_tree() -> void:
	draw_colored_polygon(Shapes.ellipse(Vector2.ZERO, TREE_SHADOW), Palette.SHADOW)
	draw_rect(TREE_TRUNK.grow(OUTLINE_WIDTH), Palette.OUTLINE)
	draw_rect(TREE_TRUNK, Palette.TREE_TRUNK)
	# 잎: 원 세 개. 테두리용 큰 원을 먼저 다 그리고 그 위에 채운 원을 올려 겉테두리만 남긴다.
	var leaves: Array[Vector3] = [Vector3(-18, -60, 22), Vector3(18, -60, 22), Vector3(0, -80, 28)]
	for leaf in leaves:
		draw_circle(Vector2(leaf.x, leaf.y), leaf.z + OUTLINE_WIDTH, Palette.OUTLINE, true, -1.0, true)
	for leaf in leaves:
		draw_circle(Vector2(leaf.x, leaf.y), leaf.z, Palette.TREE_LEAF, true, -1.0, true)
	draw_circle(Vector2(-8, -90), 9.0, Palette.TREE_LEAF_LIGHT, true, -1.0, true)


func _draw_rock() -> void:
	draw_colored_polygon(Shapes.ellipse(Vector2.ZERO, ROCK_SHADOW), Palette.SHADOW)
	var body := Shapes.ellipse(ROCK_BODY_CENTER, ROCK_BODY, 20)
	draw_colored_polygon(body, Palette.ROCK)
	draw_colored_polygon(Shapes.ellipse(ROCK_BODY_CENTER + Vector2(-7, -7), Vector2(12, 6)), Palette.ROCK_LIGHT)
	Shapes.draw_outline(self, body, Palette.OUTLINE, OUTLINE_WIDTH)

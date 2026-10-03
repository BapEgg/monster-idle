class_name FieldGround
extends Node2D
## 필드 바닥: 쿼터뷰 마름모 타일을 도형으로 그린다.
## 그림이 생기면 TileMapLayer(아이소메트릭 타일셋)로 바꾼다. 그때도 좌표는 Iso와 같게 맞춘다.

## 섬 옆면(두께)의 높이(px). 임시 도형 치수.
const SIDE_DEPTH := 36.0
const EDGE_WIDTH := 3.0
## 섬마다 풀색에 섞는 종족 색의 양, 지역이 깊을수록 어둡게(지역 차례 0 · 1 · 2). 임시 도형 값.
const TINT_STRENGTH := 0.22
const REGION_DARKEN := [0.0, 0.1, 0.2]

## 섬 색(종족 색)과 지역 차례(0 = 입문). 바꾸면 다시 그린다(Field.rebuild).
var tint := Color.WHITE
var tint_strength := 0.0
var region_index := 0


func _draw() -> void:
	var cells := GameConfig.FIELD_CELLS
	var corners := Iso.field_polygon(cells)  # 위, 오른쪽, 아래, 왼쪽
	var down := Vector2(0, SIDE_DEPTH)

	# 섬 옆면: 아래쪽 두 변 밑으로 흙 띠를 내려 두께를 준다.
	draw_colored_polygon(PackedVector2Array([
		corners[3], corners[2], corners[2] + down, corners[3] + down,
	]), Palette.FIELD_SIDE_LEFT)
	draw_colored_polygon(PackedVector2Array([
		corners[2], corners[1], corners[1] + down, corners[2] + down,
	]), Palette.FIELD_SIDE_RIGHT)

	# 타일: 옅은 체크무늬로 칸이 보이게 한다(움직임과 방향을 느끼기 쉽게).
	for y in cells.y:
		for x in cells.x:
			var color := Palette.GRASS_A if (x + y) % 2 == 0 else Palette.GRASS_B
			draw_colored_polygon(Iso.cell_polygon(Vector2i(x, y)), _shade(color))

	Shapes.draw_outline(self, corners, _shade(Palette.FIELD_EDGE), EDGE_WIDTH)


## 섬 색을 조금 섞고 깊은 지역일수록 어둡게.
func _shade(color: Color) -> Color:
	return color.lerp(tint, tint_strength).darkened(REGION_DARKEN[clampi(region_index, 0, REGION_DARKEN.size() - 1)])


## 섬 · 지역에 맞춘 바닥 색으로 다시 그린다.
func paint(island_tint: Color, of_region: int) -> void:
	tint = island_tint
	tint_strength = TINT_STRENGTH
	region_index = of_region
	queue_redraw()

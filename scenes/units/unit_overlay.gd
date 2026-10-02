class_name UnitOverlay
extends Node2D
## 유닛 머리 위의 이름표와 체력 바.
## z_index를 높여 유닛·나무보다 위에 그린다(나무 뒤에 서도 이름표는 보인다).

const Z := 5
const FONT_SIZE := 13
const FONT_OUTLINE := 4
const BAR_SIZE := Vector2(36, 5)
const GAP := 4.0

var unit: Unit


func _ready() -> void:
	z_index = Z


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if not unit.is_alive():
		return
	var y := -unit.overlay_height()
	if unit.shows_hp_bar():
		var bar := Rect2(Vector2(-BAR_SIZE.x * 0.5, y - BAR_SIZE.y), BAR_SIZE)
		draw_rect(bar.grow(1.0), Palette.HP_BAR_BACK)
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * unit.hp / unit.stats.max_hp, bar.size.y)), unit.hp_bar_color())
		y -= BAR_SIZE.y + GAP
	if unit.display_name != "":
		var font := ThemeDB.fallback_font
		var width := font.get_string_size(unit.display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
		var at := Vector2(-width * 0.5, y - 2.0)
		draw_string_outline(font, at, unit.display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, FONT_OUTLINE, Palette.TEXT_OUTLINE)
		draw_string(font, at, unit.display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, unit.name_color())

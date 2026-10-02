class_name UnitOverlay
extends Node2D
## 유닛 머리 위의 체력 바, 이름표, 표시(감지 전구 · "!" · 추격 포기 파란 표시).
## 체력 바는 다쳤을 때와 주인공의 대상일 때 보인다. 방금 깎인 만큼은 잔상으로 잠깐 남는다(HpBar).
## z_index를 높여 유닛·나무보다 위에 그린다(나무 뒤에 서도 이름표는 보인다).

const Z := 5
const FONT_SIZE := 13
const FONT_OUTLINE := 4
const BAR_SIZE := Vector2(42, 6)
const GAP := 4.0
# 표시(임시 도형): "!"·"?" 글자 크기, 전구 유리 반지름·꼭지 크기, 이름표와의 간격
const MARK_FONT_SIZE := 26
const MARK_OUTLINE := 6
const MARK_GAP := 4.0
const BULB_RADIUS := 11.0
const BULB_SOCKET := Vector2(10, 6)
const BULB_LINE := 2.0

var unit: Unit

var _trail := 1.0  # 체력 바 잔상(0~1)


func _ready() -> void:
	z_index = Z


func _process(delta: float) -> void:
	_trail = HpBar.next_trail(_trail, _hp_ratio(), delta)
	queue_redraw()


func _hp_ratio() -> float:
	return clampf(unit.hp / unit.stats.max_hp, 0.0, 1.0)


func _draw() -> void:
	if not unit.is_alive():
		return
	var y := -unit.overlay_height()
	if unit.shows_hp_bar():
		HpBar.draw(self, Rect2(Vector2(-BAR_SIZE.x * 0.5, y - BAR_SIZE.y), BAR_SIZE), _hp_ratio(), _trail, unit.hp_bar_color())
		y -= BAR_SIZE.y + GAP
	if unit.display_name != "":
		_draw_text(unit.display_name, y - 2.0, FONT_SIZE, FONT_OUTLINE, unit.name_color())
		y -= FONT_SIZE + 2.0
	var bottom := y - MARK_GAP
	match unit.mark():
		Unit.Mark.DETECTING:
			_draw_bulb(Vector2(0, bottom), unit.detect_ratio())
		Unit.Mark.ALERT:
			_draw_text(UiText.MARK_ALERT, bottom, MARK_FONT_SIZE, MARK_OUTLINE, Palette.MARK_ALERT)
		Unit.Mark.GIVE_UP:
			_draw_text(UiText.MARK_GIVE_UP, bottom, MARK_FONT_SIZE, MARK_OUTLINE, Palette.MARK_GIVE_UP)


## 가운데 맞춘 글자. baseline = 글자 밑줄 높이.
func _draw_text(text: String, baseline: float, size: int, outline: int, color: Color) -> void:
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var at := Vector2(-width * 0.5, baseline)
	draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, outline, Palette.TEXT_OUTLINE)
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


## 감지 전구: 유리알이 아래에서부터 ratio만큼 차오르고, 찰수록 노랑 → 주황으로 진해진다. bottom = 꼭지 아래 끝.
func _draw_bulb(bottom: Vector2, ratio: float) -> void:
	var socket := Rect2(bottom - Vector2(BULB_SOCKET.x * 0.5, BULB_SOCKET.y), BULB_SOCKET)
	var glass := bottom - Vector2(0, BULB_SOCKET.y + BULB_RADIUS - 1.0)
	draw_circle(glass, BULB_RADIUS, Palette.BULB_GLASS, true, -1.0, true)
	var fill := Palette.BULB_FILL_LOW.lerp(Palette.BULB_FILL_HIGH, ratio)
	for row in Shapes.circle_fill_rows(glass, BULB_RADIUS, ratio):
		draw_rect(row, fill)
	draw_arc(glass, BULB_RADIUS, 0.0, TAU, 24, Palette.OUTLINE, BULB_LINE, true)
	draw_rect(socket, Palette.BULB_SOCKET)
	draw_rect(socket, Palette.OUTLINE, false, 1.0)

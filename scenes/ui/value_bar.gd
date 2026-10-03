@tool
class_name ValueBar
extends Control
## 이름표 + 막대 + 숫자 한 줄(코어 정보창의 HP · MP). 이름표는 연한 회색, 숫자는 흰색 굵게.
## 막대는 코어의 최대값이라 늘 가득 차 있다(필드의 지금 체력이 아니다).
## @tool: 에디터에서는 보기용 예시를 그린다.

const CAPTION_FONT_SIZE := 16
const NUMBER_FONT_SIZE := 17
const CAPTION_WIDTH := 38.0
const NUMBER_WIDTH := 64.0
const BAR_HEIGHT := 10.0

var caption := ""
var value := 0
var fill := Color.WHITE


## 한 번에 바꾸고 다시 그린다.
func show_value(of_caption: String, of_value: int, of_fill: Color) -> void:
	caption = of_caption
	value = of_value
	fill = of_fill
	queue_redraw()


func _draw() -> void:
	var text := caption
	var number := str(value)
	var color := fill
	if Engine.is_editor_hint():
		text = UiText.INFO_HP
		number = "1234"
		color = Palette.INFO_HP_BAR
	var middle := size.y * 0.5
	draw_string(ThemeDB.fallback_font, Vector2(0, middle + CAPTION_FONT_SIZE * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, CAPTION_FONT_SIZE, Palette.TEXT_LABEL)
	var bar := Rect2(CAPTION_WIDTH, middle - BAR_HEIGHT * 0.5, maxf(size.x - CAPTION_WIDTH - NUMBER_WIDTH, 0.0), BAR_HEIGHT)
	draw_rect(bar, Palette.INFO_BAR_BACK)
	draw_rect(bar, color)
	var font := UiKit.bold_font()
	var width := font.get_string_size(number, HORIZONTAL_ALIGNMENT_LEFT, -1, NUMBER_FONT_SIZE).x
	draw_string(font, Vector2(size.x - width, middle + NUMBER_FONT_SIZE * 0.35), number, HORIZONTAL_ALIGNMENT_LEFT, -1, NUMBER_FONT_SIZE, Palette.TEXT)

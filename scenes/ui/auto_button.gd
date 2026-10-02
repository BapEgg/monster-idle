class_name AutoButton
extends TouchScreenButton
## 오토 버튼: 공격 버튼 위의 작은 버튼(메이플키우기의 Full Auto처럼). 누를 때마다 풀오토 → 세미오토 → 수동.
## 지금 사냥 방식을 글자와 바탕색으로 보여 준다. 원점 = 버튼 가운데.
## 조이스틱을 쥔 채 다른 손가락으로 누를 수 있게(멀티터치) 기본 노드 TouchScreenButton을 쓴다.

const FONT_SIZE := 15
const CORNER := 17

## 보여 줄 사냥 방식. 바꾸면 다시 그린다.
var mode := AutoControl.Mode.FULL_AUTO:
	set(value):
		mode = value
		queue_redraw()


func _ready() -> void:
	var box := RectangleShape2D.new()
	box.size = GameConfig.AUTO_BUTTON_SIZE
	shape = box


## 버튼이 차지하는 사각형(HUD 기준 좌표).
func area() -> Rect2:
	return Rect2(position - GameConfig.AUTO_BUTTON_SIZE * 0.5, GameConfig.AUTO_BUTTON_SIZE)


func _draw() -> void:
	var size := GameConfig.AUTO_BUTTON_SIZE
	var box := StyleBoxFlat.new()
	box.bg_color = Palette.AUTO_BUTTON_FILLS[mode]
	box.set_corner_radius_all(CORNER)
	draw_style_box(box, Rect2(-size * 0.5, size))
	var text: String = UiText.CONTROL_MODE_NAMES[mode]
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	draw_string(font, Vector2(-width * 0.5, FONT_SIZE * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Palette.AUTO_BUTTON_TEXTS[mode])

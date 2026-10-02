@tool
class_name AttackButton
extends TouchScreenButton
## 공격 버튼(늘 보임). 누르는 동안 attack 입력 액션을 누른다(키보드 Space와 같다).
## 조이스틱을 쥔 채 다른 손가락으로 누를 수 있게(멀티터치) Godot 기본 노드 TouchScreenButton을 쓴다.
## 그림은 원 + 글자로 대체한다. 원점 = 원의 중심. 크기는 shape(CircleShape2D)의 반지름을 따른다.
## @tool: 에디터에서도 그려져서, hud.tscn을 열고 끌어서 자리를 잡을 수 있다.

const FONT_SIZE := 22
const RING_WIDTH := 3.0


func _ready() -> void:
	pressed.connect(queue_redraw)
	released.connect(queue_redraw)


func _draw() -> void:
	var circle := shape as CircleShape2D
	if circle == null:
		return
	draw_circle(Vector2.ZERO, circle.radius, Palette.ATTACK_BUTTON_DOWN if is_pressed() else Palette.ATTACK_BUTTON, true, -1.0, true)
	draw_arc(Vector2.ZERO, circle.radius, 0.0, TAU, 48, Palette.ATTACK_BUTTON_RING, RING_WIDTH, true)
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(UiText.ATTACK_BUTTON, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	var at := Vector2(-width * 0.5, FONT_SIZE * 0.35)
	draw_string_outline(font, at, UiText.ATTACK_BUTTON, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, 6, Palette.TEXT_OUTLINE)
	draw_string(font, at, UiText.ATTACK_BUTTON, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Palette.TEXT)

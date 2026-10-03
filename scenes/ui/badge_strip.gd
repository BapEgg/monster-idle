@tool
class_name BadgeStrip
extends Control
## 둥근 배지 여러 개를 왼쪽부터 한 줄로 그린다(코어 정보창의 나이 · 성별 · 변이).
## @tool: 에디터에서는 보기용 예시 배지를 그린다.

const FONT_SIZE := 15
const GAP := 6.0

## [[글자, 바탕색], …]
var badges: Array = []:
	set(value):
		badges = value
		queue_redraw()


func _draw() -> void:
	var list := badges
	if Engine.is_editor_hint():
		list = [[UiText.AGE_NAMES[1], Palette.BADGE_AGE], [UiText.GENDER_NAMES[0], Palette.BADGE_FEMALE]]
	var x := 0.0
	for badge: Array in list:
		var rect := UiKit.draw_badge(self, Vector2(x, size.y * 0.5), Vector2(0, 0.5), badge[0], badge[1], FONT_SIZE)
		x = rect.end.x + GAP

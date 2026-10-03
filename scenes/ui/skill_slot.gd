@tool
class_name SkillSlot
extends TouchScreenButton
## 스킬 칸 하나(사용자 결정 2026-10-02: 공격 버튼 옆 6칸). 1~3번 = 파티 헨치 1~3의 고유 액티브,
## 4~6번 = 주인공 직업 액티브, 따로 하나 = 궁극기 칸. 누르면 그 스킬을 쓴다(풀오토가 아니어도).
## 그림은 주인(헨치 · 직업) 색 바탕 + 스킬 이름(두 줄)으로 대체한다. 대기 중에는 이름 대신 어두운 부채꼴과 남은 초가 보인다.
## 아직 배우지 않은 궁극기 칸은 locked_text("Lv 25")를 보여 준다(레벨이 모자라면 빨강, 됐으면 회색 — 직업 창과 같은 뜻).
## 테두리: 쓸 수 있으면 금빛, 눌러서 쓰려고 기다리는 중이면 흰색.
## 원점 = 칸 가운데. 크기는 shape(RectangleShape2D)의 크기를 따른다(여섯 칸이 같은 shape를 함께 써서 한 번에 바뀐다).
## @tool: 에디터에서도 그려져서, hud.tscn을 열고 칸마다 끌어서 자리를 잡을 수 있다(에디터에서는 빈 칸으로 보인다).

const CORNER := 10
const BORDER := 2
const READY_BORDER := 3
const FONT_SIZE := 11
const SECONDS_FONT_SIZE := 18
const OUTLINE := 4
const TINT_ALPHA := 0.45
const PIE_POINTS := 32

## 보여 줄 스킬(없으면 빈 칸). HUD가 매 프레임 넣어 준다.
var skill: SkillTimer
## 빈 칸일 때 보일 글자(예: 궁극기 칸 "Lv 25")와 색(레벨이 모자라면 빨강, 레벨은 됐는데 안 배웠으면 회색)
var locked_text := ""
var locked_color := Palette.TEXT_LABEL
## 스킬 주인(헨치) 색
var tint := Color.TRANSPARENT
## 눌러서 쓰려고 기다리는 중
var requested := false


## 보여 줄 것을 한 번에 바꾸고 다시 그린다.
func show_skill(of_skill: SkillTimer, of_tint: Color, is_requested: bool, of_locked := "", of_locked_color := Palette.TEXT_LABEL) -> void:
	skill = of_skill
	locked_text = of_locked
	locked_color = of_locked_color
	tint = of_tint
	requested = is_requested
	queue_redraw()


func _draw() -> void:
	var box_shape := shape as RectangleShape2D
	if box_shape == null:
		return
	var rect := Rect2(-box_shape.size * 0.5, box_shape.size)
	var box := StyleBoxFlat.new()
	box.bg_color = Palette.SKILL_SLOT if skill == null else Color(tint, TINT_ALPHA)
	box.border_color = Palette.SKILL_SLOT_BORDER
	box.set_border_width_all(BORDER)
	box.set_corner_radius_all(CORNER)
	if skill != null and requested:
		box.border_color = Palette.SKILL_SLOT_REQUESTED
		box.set_border_width_all(READY_BORDER)
	elif skill != null and skill.is_ready():
		box.border_color = Palette.SKILL_SLOT_READY
		box.set_border_width_all(READY_BORDER)
	draw_style_box(box, rect)
	if skill == null:
		if locked_text != "":
			_draw_centered(locked_text, FONT_SIZE, FONT_SIZE * 0.35, locked_color)
		return
	if skill.is_ready():
		_draw_title(skill.title)
	else:
		_draw_cooldown(rect, skill.wait_ratio())
		_draw_centered(str(ceili(skill.left)), SECONDS_FONT_SIZE, SECONDS_FONT_SIZE * 0.35)


## 스킬 이름을 두 줄로(가운데에 가까운 띄어쓰기에서 나눈다).
func _draw_title(title: String) -> void:
	var lines := _split_two(title)
	var line_height := FONT_SIZE + 2.0
	var top := -line_height * (lines.size() - 1) * 0.5 + FONT_SIZE * 0.35
	for i in lines.size():
		_draw_centered(lines[i], FONT_SIZE, top + line_height * i)


static func _split_two(text: String) -> PackedStringArray:
	var middle := text.length() * 0.5
	var best := -1
	for i in text.length():
		if text[i] == " " and (best < 0 or absf(i - middle) < absf(best - middle)):
			best = i
	if best < 0:
		return PackedStringArray([text])
	return PackedStringArray([text.substr(0, best), text.substr(best + 1)])


## 대기 중: 남은 비율만큼 12시 방향부터 시계 방향으로 어두운 부채꼴(칸 모양으로 잘라서).
func _draw_cooldown(rect: Rect2, ratio: float) -> void:
	if ratio <= 0.0:
		return
	var reach := rect.size.length()
	var pie := PackedVector2Array([Vector2.ZERO])
	for i in PIE_POINTS + 1:
		var angle := -PI * 0.5 + TAU * ratio * i / PIE_POINTS
		pie.append(Vector2(cos(angle), sin(angle)) * reach)
	var square := PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	for piece in Geometry2D.intersect_polygons(pie, square):
		draw_colored_polygon(piece, Palette.SKILL_SLOT_COOLDOWN)


func _draw_centered(text: String, font_size: int, baseline: float, color := Palette.TEXT) -> void:
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var at := Vector2(-width * 0.5, baseline)
	draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, OUTLINE, Palette.TEXT_OUTLINE)
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

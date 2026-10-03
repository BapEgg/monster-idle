@tool
class_name TargetFrame
extends Control
## 화면 위 가운데의 대상 창: 지금 대상의 이름과 체력 바, 남은 체력 숫자.
## 굶지마 투게더의 보스 체력 바를 작게 줄인 느낌(사용자 결정 2026-10-02). 대상이 없으면 숨는다.
## 이름 색은 머리 위 이름표와 같다(선공 = 빨강, 비선공 = 흰색). 체력 바 너비 = 이 창의 너비.
## 아래 줄 = 종족 상성(사용자 결정 2026-10-03, 추천 A): 종족(종족 색) · 약점 ○○족(초록 — 데려가면 유리) · ○○족에게 강함(빨강 — 데려가면 불리).
## @tool: 에디터에서는 보기용 예시를 그려서, hud.tscn을 열고 끌어서 자리·너비를 잡을 수 있다.

const NAME_FONT_SIZE := 17
const NUMBER_FONT_SIZE := 12
const OUTLINE := 5
const NAME_GAP := 8.0
const BAR_HEIGHT := 10.0
const AFFINITY_FONT_SIZE := 13
const AFFINITY_GAP := 4.0
## 에디터 보기용 예시의 체력 비율
const PREVIEW_RATIO := 0.7

## 보여 줄 대상(주인공의 대상). HUD가 매 프레임 넣어 준다.
var unit: Unit:
	set(value):
		if is_instance_valid(value) and (not is_instance_valid(unit) or value != unit):
			_trail = _ratio_of(value)
		unit = value

var _trail := 1.0


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	visible = is_instance_valid(unit) and unit.is_alive()
	if visible:
		_trail = HpBar.next_trail(_trail, _ratio_of(unit), delta)
		queue_redraw()


func _draw() -> void:
	if Engine.is_editor_hint():
		_draw_frame(UiText.TARGET_PREVIEW_NAME, Palette.NAME_AGGRESSIVE, PREVIEW_RATIO, PREVIEW_RATIO, Palette.HP_BAR_WILD, UiText.TARGET_HP % [70, 100])
		return
	if not is_instance_valid(unit):
		return
	var number := UiText.TARGET_HP % [ceili(unit.hp), roundi(unit.stats.max_hp)]
	_draw_frame(unit.title(), unit.name_color(), _ratio_of(unit), _trail, unit.hp_bar_color(), number, unit.hp_bar_marks())
	var parts := affinity_parts(unit.tribe())
	if not parts.is_empty():
		_draw_parts(ThemeDB.fallback_font, parts, NAME_FONT_SIZE + NAME_GAP + BAR_HEIGHT + NUMBER_FONT_SIZE + AFFINITY_GAP + AFFINITY_FONT_SIZE * 2.0)


## 상성 줄 조각들 [[글자, 색], …]: 종족 · 약점 · 강함. 종족이 없으면 [].
static func affinity_parts(tribe_id: String) -> Array:
	var tribe := TribeDb.get_tribe(tribe_id)
	if tribe == null:
		return []
	var parts: Array = [[tribe.name, tribe.color.lightened(0.3)]]
	var weak := TribeDb.get_tribe(Affinity.beaten_by(tribe_id))
	if weak != null:
		parts.append([UiText.LIST_SEPARATOR_DOT, Palette.TEXT_LABEL])
		parts.append([UiText.AFFINITY_WEAKNESS % weak.name, Palette.AFFINITY_STRONG])
	var strong := TribeDb.get_tribe(tribe.beats)
	if strong != null:
		parts.append([UiText.LIST_SEPARATOR_DOT, Palette.TEXT_LABEL])
		parts.append([UiText.AFFINITY_TARGET_STRONG % strong.name, Palette.AFFINITY_WEAK])
	return parts


## 상성 줄 글자(실행 검사용).
func affinity_text() -> String:
	var text := ""
	for part: Array in affinity_parts(unit.tribe() if is_instance_valid(unit) else ""):
		text += str(part[0])
	return text


## 여러 색 조각을 한 줄로 가운데에.
func _draw_parts(font: Font, parts: Array, baseline: float) -> void:
	var width := 0.0
	for part: Array in parts:
		width += font.get_string_size(str(part[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, AFFINITY_FONT_SIZE).x
	var x := (size.x - width) * 0.5
	for part: Array in parts:
		var text := str(part[0])
		draw_string_outline(font, Vector2(x, baseline), text, HORIZONTAL_ALIGNMENT_LEFT, -1, AFFINITY_FONT_SIZE, OUTLINE, Palette.TEXT_OUTLINE)
		draw_string(font, Vector2(x, baseline), text, HORIZONTAL_ALIGNMENT_LEFT, -1, AFFINITY_FONT_SIZE, part[1])
		x += font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, AFFINITY_FONT_SIZE).x


func _draw_frame(title: String, title_color: Color, ratio: float, trail: float, bar_color: Color, number: String, marks: Array[float] = []) -> void:
	var font := ThemeDB.fallback_font
	_draw_centered(font, title, NAME_FONT_SIZE, NAME_FONT_SIZE, title_color)
	var bar := Rect2(Vector2(0, NAME_FONT_SIZE + NAME_GAP), Vector2(size.x, BAR_HEIGHT))
	HpBar.draw(self, bar, ratio, trail, bar_color, marks)
	_draw_centered(font, number, NUMBER_FONT_SIZE, bar.end.y + NUMBER_FONT_SIZE + 2.0, Palette.TEXT)


func _draw_centered(font: Font, text: String, font_size: int, baseline: float, color: Color) -> void:
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var at := Vector2((size.x - width) * 0.5, baseline)
	draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, OUTLINE, Palette.TEXT_OUTLINE)
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


static func _ratio_of(of_unit: Unit) -> float:
	return clampf(of_unit.hp / of_unit.stats.max_hp, 0.0, 1.0)

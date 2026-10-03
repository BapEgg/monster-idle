@tool
class_name LevelBar
extends Control
## 화면 왼쪽 위 주인공 레벨 · 경험치 막대(성장 1차): "Lv 5" + 가는 경험치 막대 + 비율(%).
## 자리·크기는 hud.tscn에서 끌어서 정한다. @tool: 에디터에서도 예시 값으로 그려진다.

const LEVEL_FONT_SIZE := 22
const PERCENT_FONT_SIZE := 14
const BAR_HEIGHT := 8.0
const BAR_GAP := 6.0
const OUTLINE := 5

var level := 1:
	set(value):
		level = value
		queue_redraw()
## 다음 레벨까지 찬 비율(0~1)
var ratio := 0.0:
	set(value):
		ratio = clampf(value, 0.0, 1.0)
		queue_redraw()
## 최고 레벨인가(막대 대신 "최고")
var at_max := false:
	set(value):
		at_max = value
		queue_redraw()


## 주인공 성장에 잇는다(바뀔 때마다 다시 그린다).
func bind(progress: PlayerProgress) -> void:
	progress.changed.connect(func() -> void: show_progress(progress))
	show_progress(progress)


func show_progress(progress: PlayerProgress) -> void:
	level = progress.level
	ratio = progress.progress()
	at_max = progress.is_max()


## 보이는 글자(실행 검사용).
func level_text() -> String:
	return UiText.LEVEL_LABEL % level


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var bold := UiKit.bold_font()
	var text := UiText.LEVEL_LABEL % (level if not Engine.is_editor_hint() else 5)
	var baseline := Vector2(0, LEVEL_FONT_SIZE)
	draw_string_outline(bold, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, LEVEL_FONT_SIZE, OUTLINE, Palette.TEXT_OUTLINE)
	draw_string(bold, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, LEVEL_FONT_SIZE, Palette.TEXT)
	var bar := Rect2(0, LEVEL_FONT_SIZE + BAR_GAP, size.x, BAR_HEIGHT)
	var fill := 1.0 if at_max else (ratio if not Engine.is_editor_hint() else 0.4)
	draw_rect(bar.grow(1.0), Palette.TEXT_OUTLINE)
	draw_rect(bar, Palette.LEVEL_BAR_BG)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * fill, bar.size.y)), Palette.LEVEL_BAR_FILL)
	var label := UiText.LEVEL_MAX if at_max else UiText.PERCENT % floori(fill * 100.0)
	var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, PERCENT_FONT_SIZE).x
	var at := Vector2(size.x - width, LEVEL_FONT_SIZE - 2.0)
	draw_string_outline(font, at, label, HORIZONTAL_ALIGNMENT_LEFT, -1, PERCENT_FONT_SIZE, OUTLINE - 1, Palette.TEXT_OUTLINE)
	draw_string(font, at, label, HORIZONTAL_ALIGNMENT_LEFT, -1, PERCENT_FONT_SIZE, Palette.TEXT_LABEL)

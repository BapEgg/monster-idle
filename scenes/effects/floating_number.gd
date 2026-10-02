class_name FloatingNumber
extends Node2D
## 피해·회복 숫자. 위로 떠오르며 사라진다.

const FONT_SIZE := 16
const FONT_OUTLINE := 4
const RISE := 28.0
const SECONDS := 0.7

var text := ""
var color := Color.WHITE


func _ready() -> void:
	# 물리 프레임이 아니라 화면 프레임(트윈)으로 움직이므로 물리 보간을 끈다.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "position:y", position.y - RISE, SECONDS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate:a", 0.0, SECONDS * 0.5).set_delay(SECONDS * 0.5)
	tween.chain().tween_callback(queue_free)


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	var at := Vector2(-width * 0.5, 0)
	draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, FONT_OUTLINE, Palette.TEXT_OUTLINE)
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, color)

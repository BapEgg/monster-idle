class_name Hud
extends CanvasLayer
## 화면 위 UI: 가상 조이스틱, 조작 안내 문구, 사냥 상태(자동/수동), 처치 수.
## 조이스틱은 Godot 4.7 기본 노드(VirtualJoystick, 동적 모드)를 쓴다.
## 자기 영역(화면 왼쪽)을 누르면 그 자리에 생기고, 기울인 만큼 move_* 입력 액션을 눌러 준다.
## 그래서 주인공은 키보드와 똑같이 Input.get_vector()로 읽는다.
## PC에서는 마우스 왼쪽 버튼도 터치로 취급된다(project.godot: emulate_touch_from_mouse).

const HINT_FONT_SIZE := 18
const MODE_FONT_SIZE := 22
const KILLS_FONT_SIZE := 18
const OUTLINE_SIZE := 6
const JOYSTICK_RING_WIDTH := 3

@onready var joystick: VirtualJoystick = $Joystick
@onready var _hint: Label = $Hint
@onready var _mode: Label = $Mode
@onready var _kills: Label = $Kills

var _player: Player


func _ready() -> void:
	_hint.text = UiText.HINT_MOVE
	_style_label(_hint, HINT_FONT_SIZE)
	_style_label(_mode, MODE_FONT_SIZE)
	_style_label(_kills, KILLS_FONT_SIZE)
	_setup_joystick()


func bind_player(player: Player) -> void:
	_player = player


func set_kills(count: int) -> void:
	_kills.text = UiText.KILLS % count


func _process(_delta: float) -> void:
	if _player == null:
		return
	if not _player.is_alive():
		_show_mode(UiText.MODE_DOWN, Palette.MODE_DOWN)
	elif not _player.control.is_manual():
		_show_mode(UiText.MODE_AUTO, Palette.MODE_AUTO)
	elif _player.control.is_held():
		_show_mode(UiText.MODE_MANUAL, Palette.MODE_MANUAL)
	else:
		_show_mode(UiText.MODE_RETURNING % ceili(_player.control.seconds_until_auto()), Palette.MODE_MANUAL)


func _show_mode(text: String, color: Color) -> void:
	_mode.text = text
	_mode.add_theme_color_override("font_color", color)


func _style_label(label: Label, font_size: int) -> void:
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Palette.TEXT)
	label.add_theme_color_override("font_outline_color", Palette.TEXT_OUTLINE)
	label.add_theme_constant_override("outline_size", OUTLINE_SIZE)


func _setup_joystick() -> void:
	joystick.anchor_right = GameConfig.JOYSTICK_ZONE_WIDTH
	joystick.offset_right = 0.0
	joystick.joystick_size = GameConfig.JOYSTICK_RADIUS * 2.0  # 지름
	joystick.tip_size = GameConfig.JOYSTICK_KNOB_RADIUS * 2.0
	joystick.add_theme_stylebox_override("normal_joystick", _circle(Palette.JOYSTICK_BASE_IDLE, Palette.JOYSTICK_RING_IDLE))
	joystick.add_theme_stylebox_override("pressed_joystick", _circle(Palette.JOYSTICK_BASE, Palette.JOYSTICK_RING))
	joystick.add_theme_stylebox_override("normal_tip", _circle(Palette.JOYSTICK_KNOB_IDLE))
	joystick.add_theme_stylebox_override("pressed_tip", _circle(Palette.JOYSTICK_KNOB))
	joystick.resized.connect(_place_joystick_rest)
	_place_joystick_rest()


## 쉬는 위치를 화면 왼쪽·아래 가장자리에서 정해진 거리만큼 안쪽에 둔다(노치 피하기).
## 기본 노드는 위치를 영역 크기에 대한 비율로 받으므로 화면 크기가 바뀔 때마다 다시 계산한다.
func _place_joystick_rest() -> void:
	var area := joystick.size
	if area.x <= 0.0 or area.y <= 0.0:
		return
	var margin := GameConfig.JOYSTICK_REST_MARGIN
	joystick.initial_offset_ratio = Vector2(margin.x / area.x, 1.0 - margin.y / area.y)


## 둥근 StyleBox. 모서리를 크게 깎아 원으로 만든다.
func _circle(fill: Color, ring := Color.TRANSPARENT) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.set_corner_radius_all(4096)
	box.corner_detail = 24
	if ring.a > 0.0:
		box.border_color = ring
		box.set_border_width_all(JOYSTICK_RING_WIDTH)
	return box

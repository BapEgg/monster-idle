class_name Hud
extends CanvasLayer
## 화면 위 UI: 가상 조이스틱, 조작 안내 문구, 사냥 상태, 처치 수, 사냥 방식 버튼(풀오토·세미오토·수동), 공격 버튼.
## 조이스틱은 Godot 4.7 기본 노드(VirtualJoystick, 동적 모드)를 쓴다.
## 자기 영역(화면 왼쪽)을 누르면 그 자리에 생기고, 기울인 만큼 move_* 입력 액션을 눌러 준다.
## 그래서 주인공은 키보드와 똑같이 Input.get_vector()로 읽는다.
## PC에서는 마우스 왼쪽 버튼도 터치로 취급된다(project.godot: emulate_touch_from_mouse).

## 사냥 방식 버튼을 눌렀을 때. main이 받아 주인공에게 알려 준다.
signal control_mode_selected(mode: AutoControl.Mode)

const HINT_FONT_SIZE := 18
const MODE_FONT_SIZE := 22
const KILLS_FONT_SIZE := 18
const MODE_BUTTON_FONT_SIZE := 16
const MODE_BUTTON_GAP := 6
const MODE_BUTTON_CORNER := 10
const OUTLINE_SIZE := 6
const JOYSTICK_RING_WIDTH := 3

@onready var joystick: VirtualJoystick = $Joystick
@onready var attack_button: AttackButton = $AttackButton
@onready var _hint: Label = $Hint
@onready var _mode: Label = $Mode
@onready var _kills: Label = $Kills
@onready var _mode_buttons: HBoxContainer = $ModeButtons

var _player: Player


func _ready() -> void:
	_style_label(_hint, HINT_FONT_SIZE)
	_style_label(_mode, MODE_FONT_SIZE)
	_style_label(_kills, KILLS_FONT_SIZE)
	_setup_joystick()
	_setup_mode_buttons()
	get_viewport().size_changed.connect(_place_attack_button)
	_place_attack_button()


func bind_player(player: Player) -> void:
	_player = player
	show_control_mode(player.control.mode)


func set_kills(count: int) -> void:
	_kills.text = UiText.KILLS % count


## 사냥 방식 버튼(AutoControl.Mode 순서). 실행 검사에서 누를 때도 쓴다.
func mode_button(mode: AutoControl.Mode) -> Button:
	return _mode_buttons.get_child(mode) as Button


## 고른 사냥 방식을 버튼·안내 문구·공격 버튼에 반영한다.
func show_control_mode(mode: AutoControl.Mode) -> void:
	# 신호 없이 바꾸면 ButtonGroup이 나머지를 풀어 주지 않으므로 하나하나 맞춘다.
	for i in _mode_buttons.get_child_count():
		(_mode_buttons.get_child(i) as Button).set_pressed_no_signal(i == mode)
	_hint.text = UiText.HINT_BY_MODE[mode] + "  ·  " + UiText.HINT_MOVE
	attack_button.visible = mode == AutoControl.Mode.MANUAL


func _process(_delta: float) -> void:
	if _player == null:
		return
	var control := _player.control
	if not _player.is_alive():
		_show_mode(UiText.MODE_DOWN, Palette.MODE_DOWN)
	elif control.mode == AutoControl.Mode.SEMI_AUTO:
		_show_mode(UiText.MODE_SEMI_AUTO, Palette.MODE_MANUAL)
	elif control.mode == AutoControl.Mode.MANUAL:
		_show_mode(UiText.MODE_FULL_MANUAL, Palette.MODE_MANUAL)
	elif not control.is_manual():
		_show_mode(UiText.MODE_AUTO, Palette.MODE_AUTO)
	elif control.is_held():
		_show_mode(UiText.MODE_MANUAL, Palette.MODE_MANUAL)
	else:
		_show_mode(UiText.MODE_RETURNING % ceili(control.seconds_until_auto()), Palette.MODE_MANUAL)


func _show_mode(text: String, color: Color) -> void:
	_mode.text = text
	_mode.add_theme_color_override("font_color", color)


func _style_label(label: Label, font_size: int) -> void:
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Palette.TEXT)
	label.add_theme_color_override("font_outline_color", Palette.TEXT_OUTLINE)
	label.add_theme_constant_override("outline_size", OUTLINE_SIZE)


# ─── 사냥 방식 버튼 · 공격 버튼 ─────────────────────

## 버튼 셋을 한 묶음(ButtonGroup)으로 만들어 늘 하나만 눌려 있게 한다.
## 버튼 줄은 화면 오른쪽 아래 모서리에 붙여 두고(앵커), 가장자리에서 정해진 거리만큼 안쪽에 둔다(노치 피하기).
func _setup_mode_buttons() -> void:
	var group := ButtonGroup.new()
	for value: int in AutoControl.Mode.values():
		var mode := value as AutoControl.Mode
		var button := mode_button(mode)
		button.text = UiText.CONTROL_MODE_NAMES[mode]
		button.button_group = group
		button.custom_minimum_size = GameConfig.MODE_BUTTON_SIZE
		button.add_theme_font_size_override("font_size", MODE_BUTTON_FONT_SIZE)
		var off := _button_box(Palette.MODE_BUTTON)
		var on := _button_box(Palette.MODE_BUTTON_ON)
		for state: String in ["normal", "hover", "disabled"]:
			button.add_theme_stylebox_override(state, off)
		for state: String in ["pressed", "hover_pressed"]:
			button.add_theme_stylebox_override(state, on)
		button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		for state: String in ["font_color", "font_hover_color", "font_focus_color"]:
			button.add_theme_color_override(state, Palette.MODE_BUTTON_TEXT)
		for state: String in ["font_pressed_color", "font_hover_pressed_color"]:
			button.add_theme_color_override(state, Palette.MODE_BUTTON_TEXT_ON)
		button.pressed.connect(_on_mode_button.bind(mode))
	_mode_buttons.add_theme_constant_override("separation", MODE_BUTTON_GAP)
	var count := _mode_buttons.get_child_count()
	var row := Vector2(GameConfig.MODE_BUTTON_SIZE.x * count + MODE_BUTTON_GAP * (count - 1), GameConfig.MODE_BUTTON_SIZE.y)
	var margin := GameConfig.MODE_BUTTONS_MARGIN
	_mode_buttons.offset_right = -margin.x
	_mode_buttons.offset_bottom = -margin.y
	_mode_buttons.offset_left = -margin.x - row.x
	_mode_buttons.offset_top = -margin.y - row.y


func _on_mode_button(mode: AutoControl.Mode) -> void:
	show_control_mode(mode)
	control_mode_selected.emit(mode)


## 공격 버튼은 Node2D라 앵커가 없으므로, 화면 크기가 바뀔 때마다 오른쪽 아래 기준으로 다시 놓는다.
func _place_attack_button() -> void:
	attack_button.position = get_viewport().get_visible_rect().size - GameConfig.ATTACK_BUTTON_MARGIN


func _button_box(fill: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.set_corner_radius_all(MODE_BUTTON_CORNER)
	return box


# ─── 조이스틱 ────────────────────────────────────

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

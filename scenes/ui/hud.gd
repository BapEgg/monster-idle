class_name Hud
extends CanvasLayer
## 화면 위 UI: 가상 조이스틱, 사냥 상태, 처치 수, 대상 창(위 가운데),
## 오른쪽 아래의 공격 버튼(늘 보임) · 오토 버튼 · 스킬 칸(메이플키우기 배치를 따름, 사용자 결정 2026-10-02).
## 위치·크기는 이 장면(hud.tscn)을 에디터에서 열어 끌어서 정한다. 코드는 자리를 건드리지 않는다.
## 오른쪽 아래 버튼들은 화면 오른쪽 아래 모서리에 붙은 Controls 아래에 있어서, 휴대폰이 길어져도 모서리에서 같은 거리에 남는다.
## 조이스틱은 Godot 4.7 기본 노드(VirtualJoystick, 동적 모드)를 쓴다.
## 자기 영역(화면 왼쪽)을 누르면 그 자리에 생기고, 기울인 만큼 move_* 입력 액션을 눌러 준다.
## 그래서 주인공은 키보드와 똑같이 Input.get_vector()로 읽는다.
## PC에서는 마우스 왼쪽 버튼도 터치로 취급된다(project.godot: emulate_touch_from_mouse).

## 오토 버튼으로 사냥 방식을 바꿨을 때. main이 받아 주인공에게 알려 준다.
signal control_mode_selected(mode: AutoControl.Mode)

const MODE_FONT_SIZE := 22
const KILLS_FONT_SIZE := 18
const OUTLINE_SIZE := 6
const JOYSTICK_RING_WIDTH := 3
## 오른쪽 아래 버튼들 둘레의 여유(px). 이 안을 누르면 몹을 대상으로 지정하지 않는다(버튼을 누른 것으로 본다).
const CONTROLS_PADDING := 8.0

@onready var joystick: VirtualJoystick = $Joystick
@onready var attack_button: AttackButton = $Controls/AttackButton
@onready var auto_button: AutoButton = $Controls/AutoButton
@onready var target_frame: TargetFrame = $TargetFrame
@onready var _controls: Control = $Controls
@onready var _mode: Label = $Mode
@onready var _kills: Label = $Kills

var _player: Player


func _ready() -> void:
	_style_label(_mode, MODE_FONT_SIZE)
	_style_label(_kills, KILLS_FONT_SIZE)
	_setup_joystick()
	auto_button.pressed.connect(_on_auto_button)


func bind_player(player: Player) -> void:
	_player = player
	auto_button.mode = player.control.mode


func set_kills(count: int) -> void:
	_kills.text = UiText.KILLS % count


## 그 자리(화면 좌표)가 오른쪽 아래 버튼들(공격 · 오토 · 스킬 칸) 위인가.
func is_over_controls(point: Vector2) -> bool:
	for node in _controls.get_children():
		var button := node as TouchScreenButton
		if button != null and button.visible and _covers(button, point):
			return true
	return false


## 버튼 모양(shape) 안인가(둘레 CONTROLS_PADDING까지).
static func _covers(button: TouchScreenButton, point: Vector2) -> bool:
	var local := button.get_global_transform().affine_inverse() * point
	if button.shape is CircleShape2D:
		return local.length() <= (button.shape as CircleShape2D).radius + CONTROLS_PADDING
	if button.shape is RectangleShape2D:
		var size := (button.shape as RectangleShape2D).size
		return Rect2(-size * 0.5, size).grow(CONTROLS_PADDING).has_point(local)
	return false


func _process(_delta: float) -> void:
	if _player == null:
		return
	target_frame.unit = _player.target if is_instance_valid(_player.target) else null
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


func _on_auto_button() -> void:
	var mode := AutoControl.next_mode(auto_button.mode)
	auto_button.mode = mode
	control_mode_selected.emit(mode)


func _show_mode(text: String, color: Color) -> void:
	_mode.text = text
	_mode.add_theme_color_override("font_color", color)


func _style_label(label: Label, font_size: int) -> void:
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Palette.TEXT)
	label.add_theme_color_override("font_outline_color", Palette.TEXT_OUTLINE)
	label.add_theme_constant_override("outline_size", OUTLINE_SIZE)


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

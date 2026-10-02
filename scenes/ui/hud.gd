class_name Hud
extends CanvasLayer
## 화면 위 UI: 가상 조이스틱, 조작 안내 문구, 사냥 상태, 처치 수, 대상 창(위 가운데),
## 오른쪽 아래의 공격 버튼(늘 보임) · 오토 버튼 · 스킬 칸(메이플키우기 배치를 따름, 사용자 결정 2026-10-02).
## 조이스틱은 Godot 4.7 기본 노드(VirtualJoystick, 동적 모드)를 쓴다.
## 자기 영역(화면 왼쪽)을 누르면 그 자리에 생기고, 기울인 만큼 move_* 입력 액션을 눌러 준다.
## 그래서 주인공은 키보드와 똑같이 Input.get_vector()로 읽는다.
## PC에서는 마우스 왼쪽 버튼도 터치로 취급된다(project.godot: emulate_touch_from_mouse).

## 오토 버튼으로 사냥 방식을 바꿨을 때. main이 받아 주인공에게 알려 준다.
signal control_mode_selected(mode: AutoControl.Mode)

const HINT_FONT_SIZE := 15
const MODE_FONT_SIZE := 22
const KILLS_FONT_SIZE := 18
const OUTLINE_SIZE := 6
const JOYSTICK_RING_WIDTH := 3
## 오른쪽 아래 버튼들 둘레의 여유(px). 이 안을 누르면 몹을 대상으로 지정하지 않는다(버튼을 누른 것으로 본다).
const CONTROLS_PADDING := 8.0

@onready var joystick: VirtualJoystick = $Joystick
@onready var attack_button: AttackButton = $AttackButton
@onready var auto_button: AutoButton = $AutoButton
@onready var target_frame: TargetFrame = $TargetFrame
@onready var _skill_slots: SkillSlots = $SkillSlots
@onready var _hint: Label = $Hint
@onready var _mode: Label = $Mode
@onready var _kills: Label = $Kills

var _player: Player


func _ready() -> void:
	_hint.text = UiText.HINT
	_style_label(_hint, HINT_FONT_SIZE)
	_style_label(_mode, MODE_FONT_SIZE)
	_style_label(_kills, KILLS_FONT_SIZE)
	_setup_joystick()
	_setup_target_frame()
	auto_button.pressed.connect(_on_auto_button)
	get_viewport().size_changed.connect(_place_controls)
	_place_controls()


func bind_player(player: Player) -> void:
	_player = player
	auto_button.mode = player.control.mode


func set_kills(count: int) -> void:
	_kills.text = UiText.KILLS % count


## 그 자리(화면 좌표)가 오른쪽 아래 버튼들(공격 · 오토 · 스킬 칸) 위인가.
func is_over_controls(point: Vector2) -> bool:
	var center := attack_button.position
	if point.distance_to(center) <= GameConfig.ATTACK_BUTTON_RADIUS + CONTROLS_PADDING:
		return true
	if auto_button.area().grow(CONTROLS_PADDING).has_point(point):
		return true
	var slots := _skill_slots.bounds()
	return Rect2(slots.position + center, slots.size).grow(CONTROLS_PADDING).has_point(point)


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


# ─── 오른쪽 아래 버튼 · 대상 창 ─────────────────────

## 공격 버튼·오토 버튼·스킬 칸은 Node2D라 앵커(화면 모서리에 붙이는 기능)가 없으므로,
## 화면 크기가 바뀔 때마다 오른쪽 아래 기준으로 다시 놓는다.
func _place_controls() -> void:
	var center := get_viewport().get_visible_rect().size - GameConfig.ATTACK_BUTTON_MARGIN
	attack_button.position = center
	auto_button.position = center + GameConfig.AUTO_BUTTON_OFFSET
	_skill_slots.position = center


## 대상 창은 위 가운데에 붙여 둔다(앵커 = 화면 가로 가운데).
func _setup_target_frame() -> void:
	var half := GameConfig.TARGET_FRAME_WIDTH * 0.5
	target_frame.offset_left = -half
	target_frame.offset_right = half
	target_frame.offset_top = GameConfig.TARGET_FRAME_TOP
	target_frame.offset_bottom = GameConfig.TARGET_FRAME_TOP + TargetFrame.NAME_FONT_SIZE + TargetFrame.NAME_GAP + GameConfig.TARGET_FRAME_BAR_HEIGHT + TargetFrame.NUMBER_FONT_SIZE + 4.0


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

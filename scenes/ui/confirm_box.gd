class_name ConfirmBox
extends PanelContainer
## 확인 창: "예/취소"로 묻거나(ask) "확인"만 있는 알림(tell). 가방·믹스 창보다 위에 뜬다.

const TEXT_FONT_SIZE := 17
const BUTTON_FONT_SIZE := 15

var _on_yes := Callable()

@onready var _message: Label = %Message
@onready var _yes: Button = %Yes
@onready var _no: Button = %No


func _ready() -> void:
	add_theme_stylebox_override("panel", UiKit.panel_box())
	UiKit.style_label(_message, TEXT_FONT_SIZE, Palette.TEXT)
	UiKit.style_button(_yes, BUTTON_FONT_SIZE)
	UiKit.style_button(_no, BUTTON_FONT_SIZE)
	_no.text = UiText.BTN_CANCEL
	_yes.pressed.connect(_on_yes_pressed)
	_no.pressed.connect(hide)


## 묻는다. "예"를 누르면 on_yes를 부른다.
func ask(text: String, on_yes: Callable) -> void:
	_message.text = text
	_yes.text = UiText.BTN_YES
	_no.visible = true
	_on_yes = on_yes
	show()


## 알린다("확인"만).
func tell(text: String) -> void:
	_message.text = text
	_yes.text = UiText.BTN_OK
	_no.visible = false
	_on_yes = Callable()
	show()


func _on_yes_pressed() -> void:
	hide()
	if _on_yes.is_valid():
		_on_yes.call()

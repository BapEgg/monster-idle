@tool
class_name GearDoll
extends Control
## 장비 인형(디아블로 · 믹스마스터 장비창처럼, 사용자 요청 2026-10-03): 가운데 흐린 사람 모양 둘레에 장비 7칸(기획서 3장).
## 가운데 줄 = 투구 · 갑옷 · 신발, 왼쪽 = 무기(세로로 긴 칸) · 장갑, 오른쪽 = 장신구 둘.
## 빈 칸 = 흐린 부위 도형 + 부위 이름, 낀 칸 = 아이템 칸과 같은 그림(GearCard.draw_gear). 칸을 누르면 slot_pressed.
## 자리 · 크기는 이 노드의 크기에 맞춰 정한다(그림이 들어오면 인형 그림으로 바꾼다). @tool이라 에디터에서도 보인다.

signal slot_pressed(slot: String)

# 임시 UI 치수
const PAD := 6.0
const GAP_RATIO := 0.4
const WEAPON_TALL := 1.45
const NAME_FONT := 13
const CORNER := 10

## 칸 → 낀 장비(없으면 칸이 없다). 바꾸면 다시 그린다.
var items := {}:
	set(value):
		items = value
		queue_redraw()
## 고른 칸(흰 테두리 + 체크)
var selected_slot := "":
	set(value):
		selected_slot = value
		queue_redraw()
## 무기 칸 빈 그림이 이 직업의 무기
var job_id := GameConfig.START_JOB:
	set(value):
		job_id = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(queue_redraw)


func _gui_input(event: InputEvent) -> void:
	# 터치는 마우스 누름으로도 들어오므로(emulate_mouse_from_touch) 마우스 누름만 본다
	var press := event as InputEventMouseButton
	if press != null and press.pressed and press.button_index == MOUSE_BUTTON_LEFT:
		var slot := slot_at(press.position)
		if slot != "":
			accept_event()
			slot_pressed.emit(slot)


## 칸 한 변(px).
func _side() -> float:
	return minf((size.y - PAD * 2.0) / 3.4, size.x / 4.6)


## 그 칸의 자리(이 노드 안 좌표).
func slot_rect(slot: String) -> Rect2:
	var s := _side()
	var gap_y := (size.y - PAD * 2.0 - s * 3.0) * 0.5
	var mid := size.x * 0.5
	var left := mid - s * 0.5 - s * GAP_RATIO - s
	var right := mid + s * 0.5 + s * GAP_RATIO
	var top := PAD
	var bottom := size.y - PAD - s
	match slot:
		"helmet":
			return Rect2(mid - s * 0.5, top, s, s)
		"armor":
			return Rect2(mid - s * 0.5, top + s + gap_y, s, s)
		"boots":
			return Rect2(mid - s * 0.5, bottom, s, s)
		"weapon":
			return Rect2(left, top + s * 0.25, s, s * WEAPON_TALL)
		"gloves":
			return Rect2(left, bottom, s, s)
		"accessory_1":
			return Rect2(right, top + s * 0.25, s, s)
		"accessory_2":
			return Rect2(right, bottom, s, s)
	return Rect2()


## 그 자리(이 노드 안 좌표)의 칸. 없으면 "".
func slot_at(point: Vector2) -> String:
	for slot: String in GearRules.SLOTS:
		if slot_rect(slot).has_point(point):
			return slot
	return ""


func _draw() -> void:
	var s := _side()
	# 흐린 사람 모양: 머리(투구 칸) · 몸(갑옷 칸) · 다리(신발 칸까지)
	var head := slot_rect("helmet").get_center()
	var body := slot_rect("armor")
	draw_circle(head, s * 0.42, Palette.GEAR_DOLL, true, -1.0, true)
	draw_rect(Rect2(body.position + Vector2(-s * 0.18, -s * 0.12), body.size + Vector2(s * 0.36, s * 0.3)), Palette.GEAR_DOLL)
	var feet := slot_rect("boots")
	draw_rect(Rect2(Vector2(body.position.x + s * 0.12, body.end.y), Vector2(s * 0.28, feet.position.y - body.end.y)), Palette.GEAR_DOLL)
	draw_rect(Rect2(Vector2(body.end.x - s * 0.4, body.end.y), Vector2(s * 0.28, feet.position.y - body.end.y)), Palette.GEAR_DOLL)
	var font := ThemeDB.fallback_font
	for slot: String in GearRules.SLOTS:
		var rect := slot_rect(slot)
		var item: GearItem = items.get(slot)
		if item != null:
			GearCard.draw_gear(self, rect, item, slot == selected_slot, GearRules.Problem.OK, false)
			continue
		var box := StyleBoxFlat.new()
		box.bg_color = Palette.GEAR_SLOT_BG
		box.border_color = Palette.CARD_SELECTED_BORDER if slot == selected_slot else Palette.GEAR_SLOT_EMPTY
		box.set_border_width_all(2)
		box.set_corner_radius_all(CORNER)
		draw_style_box(box, rect)
		var kind := GearRules.slot_kind(slot)
		GearGlyph.draw(self, kind, job_id, Rect2(rect.position + rect.size * 0.22, rect.size * 0.56), Palette.GEAR_GLYPH_EMPTY)
		var label: String = UiText.GEAR_SLOT_NAMES.get(kind, kind)
		var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_FONT).x
		draw_string(font, Vector2(rect.get_center().x - width * 0.5, rect.end.y - 7.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_FONT, Palette.TEXT_LABEL)

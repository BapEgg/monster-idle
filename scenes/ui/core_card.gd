class_name CoreCard
extends Button
## 가방 칸 하나(믹스마스터식): 종족 색 보석 아이콘 + 이름, 모서리 배지(나이 · 성별 · 변이 · 잠금/파티).
## 빛나는 코어는 금빛 테두리, 고른 칸은 밝은 바탕과 흰 테두리. 누르면 Button의 pressed 신호.
## 아이콘은 종족 그림(TribeDb.icon, data/tribes.json 경로)을 쓰고, 파일이 없으면 보석 도형으로 그린다.

# 임시 UI 치수(px)
const SIZE := Vector2(108, 108)
const ICON_SIZE := Vector2(44, 44)
const ICON_CENTER_Y := 42.0
const NAME_BASELINE := 84.0
const NAME_FONT_SIZE := 13
const CORNER := 10
const INSET := 5.0
const SHINE_RADIUS := 26.0

var item: CoreItem
## 고른 칸인가(흰 테두리).
var selected := false:
	set(value):
		selected = value
		queue_redraw()


static func create(of_item: CoreItem) -> CoreCard:
	var card := CoreCard.new()
	card.item = of_item
	return card


func _ready() -> void:
	custom_minimum_size = SIZE
	flat = true
	focus_mode = Control.FOCUS_NONE
	# 스크롤 목록 안에서 끌어 굴릴 수 있게 누름을 부모(스크롤)에게도 넘긴다.
	mouse_filter = Control.MOUSE_FILTER_PASS
	for state: String in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())


func _draw() -> void:
	if item == null:
		return
	var rect := Rect2(Vector2.ZERO, size)
	var box := StyleBoxFlat.new()
	box.bg_color = Palette.CARD_SELECTED_BG if selected else Palette.CARD_BG
	box.set_corner_radius_all(CORNER)
	box.border_color = Palette.CORE_SHINE if item.shining else (Palette.CARD_SELECTED_BORDER if selected else Palette.CARD_BORDER)
	box.set_border_width_all(3 if item.shining or selected else 1)
	draw_style_box(box, rect)
	if item.shining and selected:
		draw_rect(rect.grow(-4.0), Palette.CARD_SELECTED_BORDER, false, 1.5)

	var species := item.species()
	var center := Vector2(size.x * 0.5, ICON_CENTER_Y)
	if item.shining:
		var glow := Palette.CORE_SHINE
		glow.a = 0.3
		draw_circle(center, SHINE_RADIUS, glow, true, -1.0, true)
	var picture := TribeDb.icon(species.tribe)
	if picture != null:
		draw_texture_rect(picture, Rect2(center - ICON_SIZE * 0.5, ICON_SIZE), false)
	else:
		CoreDrop.draw_gem(self, center, TribeDb.get_tribe(species.tribe).color, item.shining)

	var font := ThemeDB.fallback_font
	var width := font.get_string_size(species.name, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_FONT_SIZE).x
	draw_string(font, Vector2((size.x - width) * 0.5, NAME_BASELINE), species.name, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_FONT_SIZE, Palette.CORE_SHINE if item.shining else Palette.TEXT)

	var top_left := Vector2(INSET, INSET)
	var top_right := Vector2(size.x - INSET, INSET)
	var bottom_left := Vector2(INSET, size.y - INSET)
	var bottom_right := Vector2(size.x - INSET, size.y - INSET)
	UiKit.draw_badge(self, top_left, Vector2.ZERO, UiText.AGE_NAMES[item.age], Palette.BADGE_AGE)
	UiKit.draw_badge(self, top_right, Vector2(1, 0), UiText.GENDER_SHORT[item.gender], Palette.BADGE_FEMALE if item.gender == CoreItem.Gender.FEMALE else Palette.BADGE_MALE)
	if item.variant:
		UiKit.draw_badge(self, bottom_left, Vector2(0, 1), UiText.VARIANT, Palette.BADGE_VARIANT)
	if item.in_party():
		UiKit.draw_badge(self, bottom_right, Vector2.ONE, UiText.BADGE_PARTY, Palette.BADGE_PARTY)
	elif item.locked:
		UiKit.draw_badge(self, bottom_right, Vector2.ONE, UiText.BADGE_LOCK, Palette.BADGE_LOCK)

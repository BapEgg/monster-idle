class_name CoreCard
extends Button
## 가방 칸 하나(믹스마스터식): 종족 색 보석 아이콘 + 이름, 모서리 배지(나이 · 성별 · 변이 · 잠금/파티).
## 칸 테두리 뜻(사용자 결정 2026-10-03): 노랑 = 빛나는 코어, 흰색 = 고른 칸, 보라 반짝임 = 변이.
## 겹치면 바깥 테두리가 앞의 것(고른 칸 > 빛나는 > 변이)이고, 나머지는 안쪽 고리로 함께 보인다.
## 누르면 Button의 pressed 신호. 아이콘은 종족 그림(TribeDb.icon, data/tribes.json 경로)이고, 파일이 없으면 보석 도형.

# 임시 UI 치수(px): 믹스창 칸 / 가방 칸(휴대폰 가로 화면 기준으로 크게)
const SIZE := Vector2(108, 108)
const BAG_SIZE := Vector2(124, 124)
## 칸 크기에 대한 비율: 아이콘 크기 · 아이콘 가운데 높이 · 이름 밑줄 높이 · 이름 글자 · 배지 글자
const ICON_RATIO := 0.4
const ICON_CENTER_RATIO := 0.4
const NAME_BASELINE_RATIO := 0.8
const NAME_FONT_RATIO := 0.13
const BADGE_FONT_RATIO := 0.1
const CORNER := 10
const INSET := 5.0
const EDGE := 3
const INNER_INSET := 5.0
const INNER_EDGE := 2.0
const SHINE_RADIUS_RATIO := 0.25
## 변이 반짝임: 색이 오가는 빠르기, 테두리를 도는 빛 한 점의 빠르기(바퀴/초)·크기
const SHIMMER_SPEED := 5.0
const SPARKLE_LAPS := 0.5
const SPARKLE_RADIUS := 3.5

var item: CoreItem
## 고를 수 없는 까닭(믹스창 재료 목록). 비어 있지 않으면 칸을 어둡게 덮고 까닭을 가운데에 쓴다.
var block_reason := "":
	set(value):
		block_reason = value
		queue_redraw()
## 고른 칸인가(흰 테두리).
var selected := false:
	set(value):
		selected = value
		queue_redraw()

var _card_size := SIZE


static func create(of_item: CoreItem, card_size := SIZE) -> CoreCard:
	var card := CoreCard.new()
	card.item = of_item
	card._card_size = card_size
	return card


func _ready() -> void:
	custom_minimum_size = _card_size
	flat = true
	focus_mode = Control.FOCUS_NONE
	# 스크롤 목록 안에서 끌어 굴릴 수 있게 누름을 부모(스크롤)에게도 넘긴다.
	mouse_filter = Control.MOUSE_FILTER_PASS
	for state: String in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	set_process(item != null and item.variant)  # 변이 칸만 반짝이느라 매 프레임 다시 그린다


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if item == null:
		return
	var rect := Rect2(Vector2.ZERO, size)
	var edges := _edge_colors()
	var box := StyleBoxFlat.new()
	box.bg_color = Palette.CARD_SELECTED_BG if selected else Palette.CARD_BG
	box.set_corner_radius_all(CORNER)
	box.border_color = edges[0] if not edges.is_empty() else Palette.CARD_BORDER
	box.set_border_width_all(EDGE if not edges.is_empty() else 1)
	draw_style_box(box, rect)
	for i in range(1, edges.size()):
		draw_rect(rect.grow(-INNER_INSET * i), edges[i], false, INNER_EDGE)
	if item.variant:
		var ring := (1 if selected else 0) + (1 if item.shining else 0)  # 변이 테두리가 바깥에서 몇 번째 고리인가
		_draw_sparkle(rect.grow(-EDGE * 0.5 - INNER_INSET * ring))

	var species := item.species()
	var icon_size := _card_size * ICON_RATIO
	var center := Vector2(size.x * 0.5, size.y * ICON_CENTER_RATIO)
	if item.shining:
		var glow := Palette.CORE_SHINE
		glow.a = 0.3
		draw_circle(center, size.x * SHINE_RADIUS_RATIO, glow, true, -1.0, true)
	var picture := TribeDb.icon(species.tribe)
	if picture != null:
		draw_texture_rect(picture, Rect2(center - icon_size * 0.5, icon_size), false)
	else:
		CoreDrop.draw_gem(self, center, TribeDb.get_tribe(species.tribe).color, item.shining)

	var font := ThemeDB.fallback_font
	var name_size := roundi(size.x * NAME_FONT_RATIO)
	var width := font.get_string_size(species.name, HORIZONTAL_ALIGNMENT_LEFT, -1, name_size).x
	draw_string(font, Vector2((size.x - width) * 0.5, size.y * NAME_BASELINE_RATIO), species.name, HORIZONTAL_ALIGNMENT_LEFT, -1, name_size, Palette.CORE_SHINE if item.shining else Palette.TEXT)

	var badge_size := roundi(size.x * BADGE_FONT_RATIO)
	var top_left := Vector2(INSET, INSET)
	var top_right := Vector2(size.x - INSET, INSET)
	var bottom_left := Vector2(INSET, size.y - INSET)
	var bottom_right := Vector2(size.x - INSET, size.y - INSET)
	UiKit.draw_badge(self, top_left, Vector2.ZERO, UiText.AGE_NAMES[item.age], Palette.BADGE_AGE, badge_size)
	UiKit.draw_badge(self, top_right, Vector2(1, 0), UiText.GENDER_SHORT[item.gender], Palette.BADGE_FEMALE if item.gender == CoreItem.Gender.FEMALE else Palette.BADGE_MALE, badge_size)
	if item.variant:
		UiKit.draw_badge(self, bottom_left, Vector2(0, 1), UiText.VARIANT, Palette.BADGE_VARIANT, badge_size)
	if item.in_party():
		UiKit.draw_badge(self, bottom_right, Vector2.ONE, UiText.BADGE_PARTY, Palette.BADGE_PARTY, badge_size)
	elif item.locked:
		UiKit.draw_badge(self, bottom_right, Vector2.ONE, UiText.BADGE_LOCK, Palette.BADGE_LOCK, badge_size)
	if block_reason != "":
		_draw_blocked(rect, name_size)


## 고를 수 없는 칸: 어둡게 덮고 까닭을 가운데에.
func _draw_blocked(rect: Rect2, font_size: int) -> void:
	var shade := StyleBoxFlat.new()
	shade.bg_color = Palette.CARD_BLOCKED_SHADE
	shade.set_corner_radius_all(CORNER)
	draw_style_box(shade, rect)
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(block_reason, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var at := Vector2((size.x - width) * 0.5, size.y * 0.5 + font_size * 0.35)
	draw_string_outline(font, at, block_reason, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 4, Palette.TEXT_OUTLINE)
	draw_string(font, at, block_reason, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Palette.TEXT)


## 테두리 색들(바깥부터): 고른 칸 = 흰색, 빛나는 = 노랑, 변이 = 보라 반짝임. 아무것도 아니면 빈 배열(얇은 기본 테두리).
func _edge_colors() -> Array[Color]:
	var colors: Array[Color] = []
	if selected:
		colors.append(Palette.CARD_SELECTED_BORDER)
	if item.shining:
		colors.append(Palette.CORE_SHINE)
	if item.variant:
		colors.append(_variant_color())
	return colors


## 변이 테두리 색: 두 보라 사이를 오간다.
func _variant_color() -> Color:
	var t := Time.get_ticks_msec() / 1000.0
	return Palette.CARD_VARIANT_DIM.lerp(Palette.CARD_VARIANT_BRIGHT, 0.5 + 0.5 * sin(t * SHIMMER_SPEED))


## 변이 반짝임: 빛 한 점이 테두리를 따라 돈다.
func _draw_sparkle(edge: Rect2) -> void:
	var perimeter := (edge.size.x + edge.size.y) * 2.0
	var along := fposmod(Time.get_ticks_msec() / 1000.0 * SPARKLE_LAPS, 1.0) * perimeter
	var at: Vector2
	if along < edge.size.x:
		at = edge.position + Vector2(along, 0)
	elif along < edge.size.x + edge.size.y:
		at = edge.position + Vector2(edge.size.x, along - edge.size.x)
	elif along < edge.size.x * 2.0 + edge.size.y:
		at = edge.end - Vector2(along - edge.size.x - edge.size.y, 0)
	else:
		at = Vector2(edge.position.x, edge.end.y - (along - edge.size.x * 2.0 - edge.size.y))
	draw_circle(at, SPARKLE_RADIUS, Palette.CARD_VARIANT_BRIGHT, true, -1.0, true)

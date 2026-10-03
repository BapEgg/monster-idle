class_name GearCard
extends Button
## 아이템 칸 하나(장비, 한 칸에 하나 — 디아블로처럼 크기만큼 칸을 차지하지 않는다, 사용자 요청 2026-10-03).
## 테두리 = 등급 색(일반 회색 · 마법 파랑 · 희귀 노랑 · 전설 주황 · 세트 초록, 전설 · 세트는 두껍게), 고른 칸 = 흰 테두리 + 체크(다른 창과 같은 뜻).
## 가운데 = 부위 도형(GearGlyph), 왼쪽 위 = "Lv n"(주인공 레벨이 모자라면 빨강), 왼쪽 아래 = 품질 점(하급 1 ~ 최상급 4),
## 오른쪽 위 = 지금 낀 것보다 좋으면 초록 ▲, 오른쪽 아래 = 잠금. 못 끼는 장비(다른 직업 무기 · 레벨 모자람)는 흐리게.
## 누르면 Button의 pressed 신호(두 번 누르기 · 고르기는 GearView가 본다).

# 임시 UI 치수(px)
const SIZE := Vector2(80, 80)
const CORNER := 10
const EDGE := 2
const EDGE_RARE := 3
const SELECTED_EDGE := 3
const GLYPH_INSET := 0.24
const PIP := 3.0
const BADGE_FONT := 12
const CHECK_RADIUS := 10.0
const LOCK_WIDTH := 13.0
const BLOCKED_ALPHA := 0.45

var item: GearItem
var selected := false:
	set(value):
		selected = value
		queue_redraw()
## 못 끼는 까닭(GearRules.Problem)
var problem := GearRules.Problem.OK
## 지금 낀 것보다 좋은가(오른쪽 위 ▲)
var upgrade := false
## 인형 칸처럼 크기를 바꿀 때
var _card_size := SIZE


static func create(of_item: GearItem, card_size := SIZE) -> GearCard:
	var card := GearCard.new()
	card.item = of_item
	card._card_size = card_size
	card.name = "Gear%d" % of_item.uid
	return card


func _ready() -> void:
	custom_minimum_size = _card_size
	flat = true
	focus_mode = Control.FOCUS_NONE
	# 스크롤 목록 안에서 끌어 굴릴 수 있게 누름을 부모(스크롤)에게도 넘긴다.
	mouse_filter = Control.MOUSE_FILTER_PASS
	for state: String in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())


func _draw() -> void:
	if item == null:
		return
	draw_gear(self, Rect2(Vector2.ZERO, size), item, selected, problem, upgrade)


## 장비 한 칸을 그린다(아이템 칸과 인형 칸이 같이 쓴다).
static func draw_gear(canvas: CanvasItem, rect: Rect2, gear: GearItem, is_selected: bool, why: GearRules.Problem, better: bool) -> void:
	var grade_color: Color = Palette.GEAR_GRADE_COLORS[gear.grade]
	var alpha := BLOCKED_ALPHA if why != GearRules.Problem.OK else 1.0
	var box := StyleBoxFlat.new()
	box.bg_color = Palette.GEAR_CARD_BG.lerp(grade_color, 0.12)
	box.set_corner_radius_all(CORNER)
	box.border_color = Palette.CARD_SELECTED_BORDER if is_selected else grade_color
	box.set_border_width_all(SELECTED_EDGE if is_selected else (EDGE_RARE if gear.grade >= 3 else EDGE))
	canvas.draw_style_box(box, rect)
	if is_selected:  # 고른 칸: 흰 테두리 안쪽에 등급 색 고리를 하나 더
		var inner := StyleBoxFlat.new()
		inner.draw_center = false
		inner.border_color = grade_color
		inner.set_border_width_all(EDGE)
		inner.set_corner_radius_all(CORNER - SELECTED_EDGE)
		canvas.draw_style_box(inner, rect.grow(-SELECTED_EDGE))
	var glyph_rect := rect.grow(-minf(rect.size.x, rect.size.y) * GLYPH_INSET)
	GearGlyph.draw(canvas, gear.kind, gear.job_id, glyph_rect, Color(grade_color.lerp(Palette.GEAR_GLYPH, 0.55), alpha))
	var short := why == GearRules.Problem.LEVEL
	UiKit.draw_badge(canvas, rect.position + Vector2(5, 5), Vector2.ZERO, "Lv %d" % gear.level, Palette.GEAR_LEVEL_SHORT if short else Color(0, 0, 0, 0.55), BADGE_FONT)
	for i in gear.quality + 1:
		canvas.draw_circle(rect.position + Vector2(10.0 + i * PIP * 2.8, rect.size.y - 10.0), PIP, Color(Palette.TEXT, alpha), true, -1.0, true)
	if better and why == GearRules.Problem.OK:
		var tip := rect.position + Vector2(rect.size.x - 12.0, 8.0)
		canvas.draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(7, 10), tip + Vector2(-7, 10)]), Palette.GEAR_UP)
	var corner := rect.position + rect.size
	if is_selected:
		UiKit.draw_check(canvas, corner - Vector2(CHECK_RADIUS + 3.0, CHECK_RADIUS + 3.0), CHECK_RADIUS)
	if gear.locked:  # 고른 칸이면 체크 왼쪽에
		var shift := CHECK_RADIUS * 2.0 + 4.0 if is_selected else 0.0
		UiKit.draw_lock(canvas, corner - Vector2(13.0 + shift, 14.0), LOCK_WIDTH, Palette.TEXT)

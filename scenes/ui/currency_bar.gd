@tool
class_name CurrencyBar
extends Control
## 화면 오른쪽 위 재화(사용자 결정 2026-10-03: 가방 창 왼쪽 위에서 메인 화면 오른쪽 위로 옮김): 골드 · 경험치 조각.
## 오른쪽 끝에 붙여 [아이콘 숫자]를 늘어놓는다. 코어 조각은 종마다 따로라 가방의 조각 칸(n/12)에서 본다.
## "+" 구매 버튼은 넣지 않는다(기획서 7장 화면 원칙). 자리·크기는 hud.tscn에서 끌어서 정한다. @tool: 에디터에서도 예시 값으로 그려진다.

const FONT_SIZE := 20
const OUTLINE := 5
## 임시 아이콘 치수(px): 동전 반지름 · 조각 반 크기 · 아이콘과 숫자 사이 · 재화 사이
const COIN_RADIUS := 10.0
const SHARD_HALF := Vector2(8.0, 11.0)
const ICON_GAP := 6.0
const ITEM_GAP := 20.0

var gold := 0:
	set(value):
		gold = value
		queue_redraw()
var exp_shards := 0:
	set(value):
		exp_shards = value
		queue_redraw()


## 지갑에 잇는다(바뀔 때마다 다시 그린다).
func bind(wallet: Wallet) -> void:
	wallet.changed.connect(func() -> void: show_wallet(wallet))
	show_wallet(wallet)


func show_wallet(wallet: Wallet) -> void:
	gold = wallet.gold
	exp_shards = wallet.exp_shards


## 보이는 숫자들(실행 검사용): [골드, 경험치 조각].
func texts() -> PackedStringArray:
	return PackedStringArray([UiKit.thousands(gold), UiKit.thousands(exp_shards)])


func _draw() -> void:
	var shown_gold := gold if not Engine.is_editor_hint() else 12345
	var shown_shards := exp_shards if not Engine.is_editor_hint() else 7
	var right := size.x
	right = _draw_item(right, UiKit.thousands(shown_shards), _draw_shard_icon)
	right -= ITEM_GAP
	_draw_item(right, UiKit.thousands(shown_gold), _draw_coin_icon)


## 오른쪽 끝(right)에서 왼쪽으로 [아이콘 숫자] 하나를 그리고, 그 왼쪽 끝을 돌려준다.
func _draw_item(right: float, text: String, icon: Callable) -> float:
	var bold := UiKit.bold_font()
	var width := bold.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	var baseline := Vector2(right - width, size.y * 0.5 + FONT_SIZE * 0.36)
	draw_string_outline(bold, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, OUTLINE, Palette.TEXT_OUTLINE)
	draw_string(bold, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Palette.TEXT)
	var icon_right := right - width - ICON_GAP
	return icon.call(icon_right)


## 골드: 노란 동전(테두리 + 안쪽 고리). 왼쪽 끝을 돌려준다.
func _draw_coin_icon(right: float) -> float:
	var center := Vector2(right - COIN_RADIUS, size.y * 0.5)
	draw_circle(center, COIN_RADIUS + 1.5, Palette.TEXT_OUTLINE, true, -1.0, true)
	draw_circle(center, COIN_RADIUS, Palette.CURRENCY_GOLD, true, -1.0, true)
	draw_arc(center, COIN_RADIUS * 0.6, 0.0, TAU, 16, Palette.CURRENCY_GOLD_DARK, 2.0, true)
	return right - COIN_RADIUS * 2.0


## 경험치 조각: 하늘색 마름모 결정(필드에서 주울 때 글자 색과 같다). 왼쪽 끝을 돌려준다.
func _draw_shard_icon(right: float) -> float:
	var center := Vector2(right - SHARD_HALF.x, size.y * 0.5)
	var points := PackedVector2Array([
		center + Vector2(0, -SHARD_HALF.y), center + Vector2(SHARD_HALF.x, 0),
		center + Vector2(0, SHARD_HALF.y), center + Vector2(-SHARD_HALF.x, 0),
	])
	var outline := points.duplicate()
	outline.append(points[0])
	draw_colored_polygon(points, Palette.EXP_SHARD)
	draw_polyline(outline, Palette.TEXT_OUTLINE, 1.5, true)
	draw_line(center + Vector2(0, -SHARD_HALF.y * 0.6), center + Vector2(SHARD_HALF.x * 0.4, 0), Palette.FLASK_SHINE, 2.0, true)
	return right - SHARD_HALF.x * 2.0

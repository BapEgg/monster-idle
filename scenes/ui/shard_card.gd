class_name ShardCard
extends Button
## 가방의 코어 조각 칸(사용자 결정 2026-10-03): 그 종의 코어 조각을 얼마나 모았나("코어 조각 1/12" + 가는 막대).
## 아직 덜 모였으면 색을 빼고(흑백 셰이더) 흐리게 그려 시선이 몰리지 않게, 다 모이면 색이 돌아오고 "만들기" 배지.
## 가방 칸(CoreCard)과 같은 크기 · 같은 아이콘 자리. 누르면 Button의 pressed 신호(가방 창이 정보 · 만들기를 처리).

const GRAYSCALE := preload("res://scenes/ui/grayscale.gdshader")
## 칸 크기에 대한 비율: 아이콘 크기 · 아이콘 가운데 높이 · 이름 밑줄 · 막대 높이 자리 · 진행 글자 밑줄 · 글자 크기
const ICON_RATIO := 0.34
const ICON_CENTER_RATIO := 0.32
const NAME_BASELINE_RATIO := 0.62
const BAR_TOP_RATIO := 0.7
const PROGRESS_BASELINE_RATIO := 0.9
const NAME_FONT_RATIO := 0.12
const PROGRESS_FONT_RATIO := 0.1
const BADGE_FONT_RATIO := 0.1
# 임시 UI 치수(px)
const CORNER := 10
const INSET := 5.0
const BAR_HEIGHT := 5.0
const BAR_SIDE := 12.0

var species_id := ""
var count := 0

var _card_size := CoreCard.BAG_SIZE


static func create(of_species: String, shards: int, card_size := CoreCard.BAG_SIZE) -> ShardCard:
	var card := ShardCard.new()
	card.species_id = of_species
	card.count = shards
	card._card_size = card_size
	return card


## 다 모였나(누르면 만들 수 있다).
func is_ready() -> bool:
	return count >= GameConfig.CORE_SHARDS_PER_CORE


## 진행 글자(실행 검사용): "코어 조각 1/12".
func progress_text() -> String:
	return UiText.SHARD_PROGRESS % [mini(count, GameConfig.CORE_SHARDS_PER_CORE), GameConfig.CORE_SHARDS_PER_CORE]


func _ready() -> void:
	custom_minimum_size = _card_size
	flat = true
	focus_mode = Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_PASS
	for state: String in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	if not is_ready():
		var gray := ShaderMaterial.new()
		gray.shader = GRAYSCALE
		material = gray


func _draw() -> void:
	var species := HenchDb.get_species(species_id)
	if species == null:
		return
	var ready_now := is_ready()
	var rect := Rect2(Vector2.ZERO, size)
	var box := StyleBoxFlat.new()
	box.bg_color = Palette.SHARD_CARD_BG
	box.set_corner_radius_all(CORNER)
	box.border_color = Palette.SHARD_READY if ready_now else Palette.SHARD_CARD_BORDER
	box.set_border_width_all(2 if ready_now else 1)
	draw_style_box(box, rect)
	var icon_size := size * ICON_RATIO
	var center := Vector2(size.x * 0.5, size.y * ICON_CENTER_RATIO)
	var picture := TribeDb.icon(species.tribe)
	var tint := Color(1, 1, 1, 1.0 if ready_now else 0.55)
	if picture != null:
		draw_texture_rect(picture, Rect2(center - icon_size * 0.5, icon_size), false, tint)
	else:
		CoreDrop.draw_gem(self, center, TribeDb.get_tribe(species.tribe).color, false)
	var font := ThemeDB.fallback_font
	var name_size := roundi(size.x * NAME_FONT_RATIO)
	var name_color := Palette.TEXT if ready_now else Palette.TEXT_LABEL
	var width := font.get_string_size(species.name, HORIZONTAL_ALIGNMENT_LEFT, -1, name_size).x
	draw_string(font, Vector2((size.x - width) * 0.5, size.y * NAME_BASELINE_RATIO), species.name, HORIZONTAL_ALIGNMENT_LEFT, -1, name_size, name_color)
	# 진행 막대 + "코어 조각 n/12"
	var bar := Rect2(BAR_SIDE, size.y * BAR_TOP_RATIO, size.x - BAR_SIDE * 2.0, BAR_HEIGHT)
	draw_rect(bar, Palette.SHARD_BAR_BG)
	var ratio := clampf(float(count) / GameConfig.CORE_SHARDS_PER_CORE, 0.0, 1.0)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * ratio, bar.size.y)), Palette.SHARD_READY if ready_now else Palette.SHARD_BAR_FILL)
	var progress_size := roundi(size.x * PROGRESS_FONT_RATIO)
	var progress := progress_text()
	width = font.get_string_size(progress, HORIZONTAL_ALIGNMENT_LEFT, -1, progress_size).x
	draw_string(font, Vector2((size.x - width) * 0.5, size.y * PROGRESS_BASELINE_RATIO), progress, HORIZONTAL_ALIGNMENT_LEFT, -1, progress_size, Palette.TEXT_LABEL)
	if ready_now:
		UiKit.draw_badge(self, Vector2(size.x - INSET, INSET), Vector2(1, 0), UiText.SHARD_READY, Palette.BADGE_PARTY, roundi(size.x * BADGE_FONT_RATIO))

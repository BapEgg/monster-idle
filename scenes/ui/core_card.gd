class_name CoreCard
extends PanelContainer
## 가방 창의 코어 칸 하나: 보석 그림 + 종 이름 + 접미사 · 나이 (+ 빛나는 코어 표시).
## 빛나는 코어는 칸 테두리와 이름이 금빛이다.

# 임시 UI 치수(px)
const MIN_SIZE := Vector2(124, 70)
const ICON_SIZE := Vector2(26, 40)
const NAME_FONT_SIZE := 15
const DETAIL_FONT_SIZE := 12
const CORNER := 8
const PADDING := 6

var item: CoreItem


static func create(of_item: CoreItem) -> CoreCard:
	var card := CoreCard.new()
	card.item = of_item
	return card


func _ready() -> void:
	custom_minimum_size = MIN_SIZE
	mouse_filter = Control.MOUSE_FILTER_PASS
	var box := StyleBoxFlat.new()
	box.bg_color = Palette.CARD_BG
	box.border_color = Palette.CORE_SHINE if item.shining else Palette.CARD_BORDER
	box.set_border_width_all(2 if item.shining else 1)
	box.set_corner_radius_all(CORNER)
	box.set_content_margin_all(PADDING)
	add_theme_stylebox_override("panel", box)

	var species := HenchDb.get_species(item.species_id)
	var row := HBoxContainer.new()
	add_child(row)
	var icon := Control.new()
	icon.custom_minimum_size = ICON_SIZE
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.draw.connect(func() -> void: CoreDrop.draw_gem(icon, icon.size * 0.5, species.color, item.shining))
	row.add_child(icon)
	var lines := VBoxContainer.new()
	lines.add_theme_constant_override("separation", 0)
	row.add_child(lines)
	lines.add_child(_label(species.name, NAME_FONT_SIZE, Palette.CORE_SHINE if item.shining else Palette.TEXT))
	lines.add_child(_label(UiText.CORE_DETAIL % [SuffixDb.display_name(item.suffix_id), UiText.AGE_NAMES[item.age]], DETAIL_FONT_SIZE, Palette.TEXT_DIM))
	if item.shining:
		lines.add_child(_label(UiText.SHINING, DETAIL_FONT_SIZE, Palette.CORE_SHINE))


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

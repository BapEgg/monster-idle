class_name IslandMap
extends PanelContainer
## 섬 지도 창(기획서 7장 섬 구조, 로드맵 8): 오른쪽 위 "지도" 버튼이나 미니맵을 누르면 열린다.
## 왼쪽 = 바다 위 섬 8개(WorldMapView). 섬을 누르면 오른쪽에 그 섬: 이름 · 섬의 왕 · 열렸나, 지역 3줄(입문 · 특수 · 심장부:
## 레벨대 · 나오는 종 · 버튼 — 갈 수 있으면 "이동", 지금 있는 곳이면 "지금 여기", 레벨이 모자라면 "Lv n부터").
## 섬 개방(도감 → 레시피 힌트 → 길잡이 믹스)은 다음 단계라, 닫힌 섬은 안내만 하고 지역 버튼이 꺼져 있다.
## "이동"을 누르면 travel_requested(섬, 지역)를 내고 창을 닫는다(실제 이동은 Main). 위치 · 크기는 island_map.tscn에서.

signal travel_requested(island_id: String, region_id: String)

const TITLE_FONT_SIZE := 24
const TEXT_FONT_SIZE := 17
const NAME_FONT_SIZE := 26
const SMALL_FONT_SIZE := 15
const REGION_FONT_SIZE := 19
const ROW_PAD := 12.0
const BUTTON_SIZE := Vector2(130, 48)

var _world: WorldState
var _progress: PlayerProgress
var _selected := ""

@onready var _title: Label = %Title
@onready var _here: Label = %Here
@onready var _close: Button = %Close
@onready var _map: WorldMapView = %World
@onready var _divider: VSeparator = %Divider
@onready var _island_name: Label = %IslandName
@onready var _king: Label = %King
@onready var _status: Label = %Status
@onready var _regions: VBoxContainer = %Regions


func _ready() -> void:
	add_theme_stylebox_override("panel", UiKit.panel_box())
	UiKit.style_label(_title, TITLE_FONT_SIZE, Palette.TEXT)
	_title.add_theme_font_override("font", UiKit.bold_font())
	_title.text = UiText.MAP_TITLE
	UiKit.style_caption(_here, TEXT_FONT_SIZE)
	UiKit.style_button(_close, TEXT_FONT_SIZE)
	_close.text = UiText.MAP_CLOSE
	_close.pressed.connect(hide)
	UiKit.style_label(_island_name, NAME_FONT_SIZE, Palette.TEXT)
	_island_name.add_theme_font_override("font", UiKit.bold_font())
	UiKit.style_caption(_king, TEXT_FONT_SIZE)
	UiKit.style_label(_status, SMALL_FONT_SIZE, Palette.TEXT_LABEL)
	var line := StyleBoxLine.new()
	line.vertical = true
	line.color = Palette.PANEL_DIVIDER
	line.thickness = 1
	_divider.add_theme_stylebox_override("separator", line)
	_map.island_pressed.connect(select_island)


func bind(world: WorldState, progress: PlayerProgress) -> void:
	_world = world
	_progress = progress
	_world.moved.connect(func() -> void:
		if visible:
			refresh())


## 연다: 지금 섬을 고른 채로.
func open() -> void:
	_selected = _world.island
	visible = true
	refresh()


func refresh() -> void:
	if _world == null:
		return
	var open_ids := {}
	for island in IslandDb.islands():
		open_ids[island.id] = _world.is_island_open(island.id)
	_map.open_ids = open_ids
	_map.current = _world.island
	_map.selected = _selected
	var here := IslandDb.get_island(_world.island)
	_here.text = UiText.MAP_HERE % [here.name, IslandDb.get_region(_world.region).name]
	_show_island(IslandDb.get_island(_selected))


## 섬을 고른다(지도에서 누르거나 실행 검사에서).
func select_island(id: String) -> void:
	if IslandDb.get_island(id) == null:
		return
	_selected = id
	refresh()


func _show_island(island: IslandDb.Island) -> void:
	if island == null:
		return
	var unlocked := _world.is_island_open(island.id)
	_island_name.text = island.name
	var king := IslandDb.king(island.id)
	_king.text = UiText.MAP_KING % (king.name if king != null else "-")
	_status.text = "" if unlocked else UiText.MAP_LOCKED_ISLAND
	_status.visible = not unlocked
	for child in _regions.get_children():
		_regions.remove_child(child)
		child.queue_free()
	for region in IslandDb.regions():
		_regions.add_child(_region_row(island, region, unlocked))


## 지역 한 줄: 이름 · 레벨대 / 나오는 종(드문 종은 표시) / 버튼.
func _region_row(island: IslandDb.Island, region: IslandDb.Region, island_open: bool) -> PanelContainer:
	var row := PanelContainer.new()
	row.name = region.id
	var box := StyleBoxFlat.new()
	var here := island.id == _world.island and region.id == _world.region
	box.bg_color = Palette.MAP_ROW_HERE if here else Palette.JOB_SECTION_BG
	box.border_color = Palette.MAP_HERE if here else Palette.PANEL_DIVIDER
	box.set_border_width_all(2 if here else 1)
	box.set_corner_radius_all(UiKit.PANEL_CORNER)
	box.set_content_margin_all(ROW_PAD)
	row.add_theme_stylebox_override("panel", box)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 14)
	row.add_child(line)
	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(texts)
	var levels := IslandDb.level_range(island.id, region.id)
	var title := Label.new()
	UiKit.style_label(title, REGION_FONT_SIZE, Palette.TEXT)
	title.add_theme_font_override("font", UiKit.bold_font())
	title.text = UiText.MAP_REGION % [region.name, levels.x, levels.y]
	texts.add_child(title)
	var species := Label.new()
	UiKit.style_caption(species, SMALL_FONT_SIZE)
	species.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	species.text = species_line(island.id, region.id)
	texts.add_child(species)
	var button := Button.new()
	button.name = "Go"
	button.custom_minimum_size = BUTTON_SIZE
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	UiKit.style_button(button, TEXT_FONT_SIZE)
	if here:
		button.text = UiText.MAP_HERE_TAG
		button.disabled = true
	elif not island_open:
		button.text = UiText.MAP_CLOSED
		button.disabled = true
	elif not IslandDb.is_region_open(island.id, region.id, _progress.level):
		button.text = UiText.MAP_NEED_LEVEL % levels.x
		button.disabled = true
	else:
		button.text = UiText.MAP_GO
		UiKit.accent_button(button)
		button.pressed.connect(func() -> void:
			hide()
			travel_requested.emit(island.id, region.id))
	line.add_child(button)
	return row


## 그 지역에 나오는 종 이름들(심장부의 드문 종은 "(드묾)").
static func species_line(island_id: String, region_id: String) -> String:
	var names := PackedStringArray()
	for row: Array in IslandDb.spawn_table(island_id, region_id):
		var species := HenchDb.get_species(str(row[0]))
		names.append(species.name if float(row[1]) >= 1.0 else UiText.MAP_RARE % species.name)
	return UiText.LIST_SEPARATOR.join(names)


# ─── 실행 검사용 ──────────────────────────────────

## 그 지역 줄의 버튼(지금 고른 섬). 없으면 null.
func region_button(region_id: String) -> Button:
	var row := _regions.get_node_or_null(region_id)
	return row.find_child("Go", true, false) as Button if row != null else null


func selected_island() -> String:
	return _selected


## 지도 위 그 섬 가운데(화면 좌표).
func island_point(id: String) -> Vector2:
	return _map.get_global_transform() * _map.island_center(id)

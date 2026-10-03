class_name CoreInfo
extends VBoxContainer
## 코어 정보창(가방 창 오른쪽): 임시 초상화, "접미사 + 이름", 종족·역할·등급·나이·성별, LV, HP·MP, 능력치 9종,
## 파티에 넣으면 싸우는 값(임시 환산), 믹스로 태어났으면 주 코어 성별에 따른 능력치 경향,
## 고유 액티브·패시브(유산이면 원래 주인 표시). 버튼: 파티 편성 / 믹스 / 분해 / 잠금.
## 버튼은 신호만 보내고, 실제 처리는 가방 창(→ Workshop, main)이 한다.
## 초상화는 종족 그림(TribeDb.portrait, data/tribes.json 경로)이다.

signal party_requested(item: CoreItem, slot: int)
signal party_leave_requested(item: CoreItem)
signal mix_requested(item: CoreItem)
signal dismantle_requested(item: CoreItem)
signal lock_requested(item: CoreItem)

const TITLE_FONT_SIZE := 19
const TEXT_FONT_SIZE := 14
const SMALL_FONT_SIZE := 13
const BUTTON_FONT_SIZE := 14
const PORTRAIT_BORDER := 2

## 보고 있는 코어(없으면 null)
var item: CoreItem
## 파티 자리마다 지금 헨치 이름을 돌려주는 함수(main.party_names)
var party_names := Callable()

@onready var _empty: Label = %Empty
@onready var _body: VBoxContainer = %Body
@onready var _portrait_frame: PanelContainer = %PortraitFrame
@onready var _portrait: TextureRect = %Portrait
@onready var _title: Label = %Title
@onready var _kind: Label = %Kind
@onready var _body_text: Label = %BodyText
@onready var _level: Label = %Level
@onready var _hp_mp: Label = %HpMp
@onready var _stats: GridContainer = %Stats
@onready var _combat: Label = %Combat
@onready var _birth: Label = %Birth
@onready var _active: Label = %Active
@onready var _passive: Label = %Passive
@onready var _notice: Label = %Notice
@onready var _party: Button = %Party
@onready var _mix: Button = %MixButton
@onready var _dismantle: Button = %Dismantle
@onready var _lock: Button = %Lock
@onready var _party_pick: VBoxContainer = %PartyPick
@onready var _party_pick_title: Label = %PartyPickTitle
@onready var _party_slots: HBoxContainer = %PartySlots


func _ready() -> void:
	UiKit.style_label(_empty, TEXT_FONT_SIZE, Palette.TEXT_DIM)
	_empty.text = UiText.INFO_EMPTY
	UiKit.style_label(_title, TITLE_FONT_SIZE, Palette.TEXT)
	for label: Label in [_kind, _body_text, _level, _hp_mp]:
		UiKit.style_label(label, TEXT_FONT_SIZE, Palette.TEXT)
	for label: Label in [_active, _passive]:
		UiKit.style_label(label, SMALL_FONT_SIZE, Palette.TEXT)
	UiKit.style_label(_combat, SMALL_FONT_SIZE, Palette.TEXT_DIM)
	UiKit.style_label(_birth, SMALL_FONT_SIZE, Palette.STAT_BOOSTED)
	UiKit.style_label(_notice, SMALL_FONT_SIZE, Palette.TEXT_WARNING)
	UiKit.style_label(_party_pick_title, SMALL_FONT_SIZE, Palette.TEXT_DIM)
	_party_pick_title.text = UiText.PARTY_PICK
	for button: Button in [_party, _mix, _dismantle, _lock]:
		UiKit.style_button(button, BUTTON_FONT_SIZE)
	_mix.text = UiText.BTN_MIX
	_dismantle.text = UiText.BTN_DISMANTLE
	for stat in SuffixDb.ids():
		var label := Label.new()
		UiKit.style_label(label, SMALL_FONT_SIZE, Palette.TEXT_DIM)
		label.name = stat
		_stats.add_child(label)
	_party.pressed.connect(_on_party)
	_mix.pressed.connect(func() -> void: mix_requested.emit(item))
	_dismantle.pressed.connect(func() -> void: dismantle_requested.emit(item))
	_lock.pressed.connect(func() -> void: lock_requested.emit(item))
	show_core(null)


## 그 코어를 보여 준다(null = 빈 안내).
func show_core(of_item: CoreItem) -> void:
	item = of_item
	_party_pick.visible = false
	_notice.text = ""
	refresh()


func refresh() -> void:
	_empty.visible = item == null
	_body.visible = item != null
	if item == null:
		return
	var species := item.species()
	var tribe := TribeDb.get_tribe(species.tribe)
	_portrait.texture = TribeDb.portrait(species.tribe)
	var frame := StyleBoxFlat.new()
	frame.bg_color = Palette.PORTRAIT_BG
	frame.border_color = Palette.CORE_SHINE if item.shining else Palette.CARD_BORDER
	frame.set_border_width_all(PORTRAIT_BORDER)
	frame.set_corner_radius_all(UiKit.PANEL_CORNER)
	_portrait_frame.add_theme_stylebox_override("panel", frame)
	_title.text = item.title()
	_title.add_theme_color_override("font_color", Palette.CORE_SHINE if item.shining else Palette.TEXT)
	_kind.text = UiText.INFO_KIND % [tribe.name, UiText.ROLE_NAMES.get(species.role, species.role), UiText.GRADE_NAMES.get(species.grade, species.grade)]
	var body := UiText.INFO_BODY % [UiText.AGE_NAMES[item.age], UiText.GENDER_NAMES[item.gender]]
	if item.shining:
		body += " · " + UiText.SHINING
	if item.variant:
		body += " · " + UiText.VARIANT
	_body_text.text = body
	var stats := CoreStats.compute(item)
	_level.text = UiText.INFO_LEVEL % item.level
	_hp_mp.text = UiText.INFO_HP_MP % [stats["hp"], stats["mp"]]
	var boosted := CoreStats.main_gender_stats(item)
	for label in _stats.get_children():
		var stat := String(label.name)
		var color := Palette.TEXT_DIM
		if stat == item.suffix_id:
			color = Palette.CORE_SHINE
		elif stat in boosted:
			color = Palette.STAT_BOOSTED
		(label as Label).text = UiText.INFO_STAT % [SuffixDb.stat_name(stat), stats.get(stat, 0)]
		(label as Label).add_theme_color_override("font_color", color)
	var combat := UnitStats.from_core(item)
	_combat.text = UiText.INFO_COMBAT % [roundi(combat.attack), combat.attack_interval]
	if combat.heal > 0.0:
		_combat.text += UiText.INFO_COMBAT_HEAL % roundi(combat.heal)
	_birth.visible = not boosted.is_empty()
	if not boosted.is_empty():
		_birth.text = UiText.INFO_BIRTH % [UiText.GENDER_NAMES[item.main_parent_gender], SuffixDb.stat_list(boosted), roundi(GameConfig.MIX_MAIN_GENDER_BONUS * 100.0)]
	_active.text = UiText.INFO_ACTIVE % species.active
	var holder := HenchDb.get_species(item.passive_owner_id())
	_passive.text = (UiText.INFO_LEGACY % [holder.name, holder.passive]) if holder != species else (UiText.INFO_PASSIVE % species.passive)
	_party.text = UiText.BTN_PARTY_LEAVE if item.in_party() else UiText.BTN_PARTY
	_lock.text = UiText.BTN_UNLOCK if item.locked else UiText.BTN_LOCK
	_dismantle.disabled = item.locked or item.in_party()
	_mix.disabled = item.locked or item.in_party()


func _on_party() -> void:
	if item.in_party():
		party_leave_requested.emit(item)
		return
	# 넣을 자리 고르기: 자리마다 지금 헨치 이름 버튼 + 취소
	for child in _party_slots.get_children():
		child.queue_free()
	var names: PackedStringArray = party_names.call() if party_names.is_valid() else PackedStringArray()
	for slot in names.size():
		var button := Button.new()
		button.text = UiText.PARTY_SLOT % [slot + 1, names[slot]]
		UiKit.style_button(button, BUTTON_FONT_SIZE)
		button.pressed.connect(func() -> void:
			_party_pick.visible = false
			party_requested.emit(item, slot))
		_party_slots.add_child(button)
	var cancel := Button.new()
	cancel.text = UiText.BTN_CANCEL
	UiKit.style_button(cancel, BUTTON_FONT_SIZE)
	cancel.pressed.connect(func() -> void: _party_pick.visible = false)
	_party_slots.add_child(cancel)
	_party_pick.visible = true

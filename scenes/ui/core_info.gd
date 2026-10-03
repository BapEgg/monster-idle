class_name CoreInfo
extends VBoxContainer
## 코어 정보창(가방 창 왼쪽, 사용자 결정 2026-10-03). 위에서부터:
## 초상화 + 이름(크게) + 종족·역할·등급 / 나이·성별·변이 배지, LV /
## 왼쪽 HP · MP · EXP 막대(반 폭) + 오른쪽 스킬 카드(고유 액티브 · 패시브 · 변이 또는 믹스 계승, 사용자 결정 2026-10-03) /
## 능력치 9개(이름 왼쪽 · 숫자 오른쪽, 2열 표) / 버튼 4개.
## 스킬 카드를 누르면 스킬 상세 창(모션 미리보기 · 설명 · 계수) — 신호(skill_detail_requested)로 HUD의 SkillWindow가 띄운다.
## 글자: 숫자는 흰색 굵게, 이름표는 연한 회색. 접미사로 강한 능력치 한 줄만 강조색(Palette.STAT_ACCENT).
## LV 옆에 경험치 조각 먹이기 버튼, HP · MP 아래에 경험치 막대(헨치도 경험치로 오른다, 상한 = 주인공 레벨 — 못 하면 까닭이 버튼에 보인다).
## 버튼은 신호만 보내고, 실제 처리는 가방 창(→ Workshop, main)이 한다.
## 초상화는 종족 그림(TribeDb.portrait, data/tribes.json 경로)이다.
## 믹스창도 이 정보창을 쓴다(사용자 결정 2026-10-03): 버튼은 숨기고(show_actions = false), 재료를 누르면 그 코어,
## 결과 칸을 누르면 미리보기(show_preview: 예상 레벨 · 접미사 확률 · 계승 스탯 · 나이 · 성별 확률 + 스킬 카드)를 보여 준다.
## 휴대폰 가로 화면 기준 글자 크기다. 자리·크기는 core_info.tscn을 에디터에서 열어 바꾼다.

signal party_requested(item: CoreItem, slot: int)
signal party_leave_requested(item: CoreItem)
signal mix_requested(item: CoreItem)
signal dismantle_requested(item: CoreItem)
signal lock_requested(item: CoreItem)
signal feed_requested(item: CoreItem)
## 스킬 카드를 눌렀을 때: sheet = SkillSheet 내용, caster = 시전자 색(종족 색)
signal skill_detail_requested(sheet: Dictionary, caster: Color)
## 상성 줄을 누름: 그 종족을 고른 채로 상성표를 연다
signal affinity_requested(tribe_id: String)

const TITLE_FONT_SIZE := 26
const TEXT_FONT_SIZE := 17
const LEVEL_FONT_SIZE := 20
const STAT_FONT_SIZE := 17
const STAT_NUMBER_FONT_SIZE := 18
const SMALL_FONT_SIZE := 15
const BUTTON_FONT_SIZE := 18
const PORTRAIT_BORDER := 2
const STAT_NUMBER_WIDTH := 44

## 보고 있는 코어(없으면 null). 미리보기 중이면 null.
var item: CoreItem
## 버튼 4개(파티 편성 · 믹스 · 분해 · 잠금)를 보일까. 믹스창에서는 숨긴다.
var show_actions := true:
	set(value):
		show_actions = value
		if is_node_ready():
			_buttons.visible = value
## 믹스 결과 미리보기를 보여 주는 중인가.
var previewing := false
## 맨 위 작은 제목(믹스창: "재료 정보" / "결과 미리보기"). 비우면 숨긴다(가방 창).
var heading := "":
	set(value):
		heading = value
		if is_node_ready():
			_heading.text = value
			_heading.visible = value != ""
## 파티 자리마다 지금 헨치 이름을 돌려주는 함수(main.party_names)
var party_names := Callable()
## 경험치 조각 · 상한을 물어볼 곳(가방 창이 넣어 준다). 없으면 먹이기 버튼을 숨긴다.
var workshop: Workshop

var _stat_names := {}  # 능력치 id → 이름 Label
var _affinity_tribe := ""  # 상성 줄을 누르면 열 종족
var _caster_color := Color.WHITE  # 스킬 상세 창 미리보기의 시전자 색(종족 색)
var _stat_values := {}  # 능력치 id → 숫자 Label

@onready var _heading: Label = %Heading
@onready var _empty: Label = %Empty
@onready var _body: VBoxContainer = %Body
@onready var _portrait_frame: PanelContainer = %PortraitFrame
@onready var _portrait: TextureRect = %Portrait
@onready var _preview: GridContainer = %Preview
@onready var _badge_row: HBoxContainer = %BadgeRow
@onready var _buttons: HBoxContainer = %Buttons
@onready var _bars: VBoxContainer = %Bars
@onready var _chips: VBoxContainer = %Chips
@onready var _active_chip: SkillChip = %ActiveChip
@onready var _passive_chip: SkillChip = %PassiveChip
@onready var _extra_chip: SkillChip = %ExtraChip
@onready var _title: Label = %Title
@onready var _kind: Label = %Kind
@onready var _affinity: HBoxContainer = %Affinity
@onready var _affinity_strong: Button = %AffinityStrong
@onready var _affinity_weak: Button = %AffinityWeak
@onready var _badges: BadgeStrip = %Badges
@onready var _level: Label = %Level
@onready var _hp_bar: ValueBar = %HpBar
@onready var _mp_bar: ValueBar = %MpBar
@onready var _exp_bar: ValueBar = %ExpBar
@onready var _stats: GridContainer = %Stats
@onready var _notice: Label = %Notice
@onready var _party: Button = %Party
@onready var _mix: Button = %MixButton
@onready var _dismantle: Button = %Dismantle
@onready var _lock: Button = %Lock
@onready var _feed: Button = %Feed
@onready var _party_pick: VBoxContainer = %PartyPick
@onready var _party_pick_title: Label = %PartyPickTitle
@onready var _party_slots: HBoxContainer = %PartySlots


func _ready() -> void:
	UiKit.style_caption(_heading, SMALL_FONT_SIZE)
	_heading.text = heading
	_heading.visible = heading != ""
	UiKit.style_caption(_empty, TEXT_FONT_SIZE)
	_empty.text = UiText.INFO_EMPTY
	UiKit.style_label(_title, TITLE_FONT_SIZE, Palette.TEXT)
	_title.add_theme_font_override("font", UiKit.bold_font())
	UiKit.style_caption(_kind, TEXT_FONT_SIZE)
	for pair: Array in [[_affinity_strong, Palette.AFFINITY_STRONG], [_affinity_weak, Palette.AFFINITY_WEAK]]:
		var button: Button = pair[0]
		UiKit.style_button(button, SMALL_FONT_SIZE)
		for state: String in ["font_color", "font_hover_color", "font_pressed_color"]:
			button.add_theme_color_override(state, pair[1])
		button.pressed.connect(func() -> void: affinity_requested.emit(_affinity_tribe))
	UiKit.style_number(_level, LEVEL_FONT_SIZE)
	for chip: SkillChip in [_active_chip, _passive_chip, _extra_chip]:
		chip.pressed.connect(func() -> void:
			skill_detail_requested.emit(chip.sheet, _caster_color))
	UiKit.style_label(_notice, SMALL_FONT_SIZE, Palette.TEXT_WARNING)
	UiKit.style_caption(_party_pick_title, SMALL_FONT_SIZE)
	_party_pick_title.text = UiText.PARTY_PICK
	for button: Button in [_party, _mix, _dismantle, _lock]:
		UiKit.style_button(button, BUTTON_FONT_SIZE)
	UiKit.style_button(_feed, SMALL_FONT_SIZE)
	_feed.add_theme_color_override("font_color", Palette.EXP_SHARD)
	_feed.pressed.connect(func() -> void: feed_requested.emit(item))
	_mix.text = UiText.BTN_MIX
	_dismantle.text = UiText.BTN_DISMANTLE
	_build_stat_table()
	_buttons.visible = show_actions
	_party.pressed.connect(_on_party)
	_mix.pressed.connect(func() -> void: mix_requested.emit(item))
	_dismantle.pressed.connect(func() -> void: dismantle_requested.emit(item))
	_lock.pressed.connect(func() -> void: lock_requested.emit(item))
	show_core(null)


## 능력치 표: 칸마다 이름(왼쪽, 연한 회색) + 숫자(오른쪽, 흰색 굵게). 2열에 9종 + 치명 확률 · 치명 피해(6줄).
func _build_stat_table() -> void:
	var ids := SuffixDb.ids()
	ids.append_array(UnitStats.CRIT_STATS)
	for stat in ids:
		var cell := HBoxContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var stat_name := Label.new()
		UiKit.style_caption(stat_name, STAT_FONT_SIZE)
		stat_name.text = UiText.STAT_CRIT_NAMES.get(stat, SuffixDb.stat_name(stat))
		stat_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var number := Label.new()
		UiKit.style_number(number, STAT_NUMBER_FONT_SIZE)
		number.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		number.custom_minimum_size.x = STAT_NUMBER_WIDTH
		cell.add_child(stat_name)
		cell.add_child(number)
		cell.name = stat
		_stats.add_child(cell)
		_stat_names[stat] = stat_name
		_stat_values[stat] = number


## 그 코어를 보여 준다(null = 빈 안내).
func show_core(of_item: CoreItem) -> void:
	item = of_item
	previewing = false
	_party_pick.visible = false
	_notice.text = ""
	_set_core_parts_visible(true)
	refresh()


## 믹스 결과 미리보기: 초상화(공개 = 그림, 힌트 = 실루엣, 비밀 = 없음) + 이름 + 종류 줄 + rows([이름표, 값] 줄들).
## 공개일 때만 고유 액티브·패시브도 보인다. 코어 능력치 · 배지 · 버튼은 숨긴다.
func show_preview(title: String, kind: String, portrait: Texture2D, silhouette: bool, rows: Array, species: HenchSpecies) -> void:
	item = null
	previewing = true
	_party_pick.visible = false
	_empty.visible = false
	_body.visible = true
	_set_core_parts_visible(false)
	_portrait.texture = portrait
	_portrait.modulate = Palette.SILHOUETTE if silhouette else Color.WHITE
	var frame := StyleBoxFlat.new()
	frame.bg_color = Palette.PORTRAIT_BG
	frame.border_color = Palette.CARD_BORDER
	frame.set_border_width_all(PORTRAIT_BORDER)
	frame.set_corner_radius_all(UiKit.PANEL_CORNER)
	_portrait_frame.add_theme_stylebox_override("panel", frame)
	_title.text = title
	_title.add_theme_color_override("font_color", Palette.TEXT)
	_kind.text = kind
	for child in _preview.get_children():
		_preview.remove_child(child)
		child.queue_free()
	for row: Array in rows:
		var caption := Label.new()
		UiKit.style_caption(caption, STAT_FONT_SIZE)
		caption.text = row[0]
		var value := Label.new()
		UiKit.style_number(value, STAT_NUMBER_FONT_SIZE)
		value.text = row[1]
		value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_preview.add_child(caption)
		_preview.add_child(value)
	_chips.visible = species != null
	_affinity.visible = species != null
	if species != null:
		_show_chips(species, species, null, null)
		_show_affinity(species.tribe)


## 상성 줄: "▲ ○○족에게 강함 · ▼ ○○족에게 약함"(사용자 결정 2026-10-03, 추천 A). 누르면 상성표.
func _show_affinity(tribe_id: String) -> void:
	_affinity_tribe = tribe_id
	var strong := TribeDb.get_tribe(Affinity.beats(tribe_id))
	var weak := TribeDb.get_tribe(Affinity.beaten_by(tribe_id))
	_affinity.visible = strong != null and weak != null
	if _affinity.visible:
		_affinity_strong.text = UiText.AFFINITY_STRONG % strong.name
		_affinity_weak.text = UiText.AFFINITY_WEAK % weak.name


## 상성 줄 글자(실행 검사용): [강함, 약함].
func affinity_texts() -> PackedStringArray:
	return PackedStringArray([_affinity_strong.text, _affinity_weak.text]) if _affinity.visible else PackedStringArray()


## 미리보기 줄의 값 글자들(실행 검사용).
func preview_values() -> PackedStringArray:
	var values := PackedStringArray()
	for i in range(1, _preview.get_child_count(), 2):
		values.append((_preview.get_child(i) as Label).text)
	return values


## 코어 보기(true)와 미리보기(false)에서 보이는 칸이 다르다.
func _set_core_parts_visible(on: bool) -> void:
	for part: Control in [_badge_row, _bars, _stats, _notice]:
		part.visible = on
	_buttons.visible = on and show_actions
	_preview.visible = not on
	_chips.visible = true
	if on:
		_portrait.modulate = Color.WHITE


## 능력치 한 칸의 숫자 Label(실행 검사용).
func stat_value_label(stat: String) -> Label:
	return _stat_values[stat]


func refresh() -> void:
	if previewing:
		return
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
	_show_affinity(species.tribe)
	var badges := [
		[UiText.AGE_NAMES[item.age], Palette.BADGE_AGE],
		[UiText.GENDER_BADGE % [UiText.GENDER_SYMBOLS[item.gender], UiText.GENDER_NAMES[item.gender]], Palette.BADGE_FEMALE if item.gender == CoreItem.Gender.FEMALE else Palette.BADGE_MALE],
	]
	if item.variant:
		badges.append([UiText.VARIANT, Palette.BADGE_VARIANT])
	_badges.badges = badges
	_level.text = UiText.INFO_LEVEL % item.level
	var stats := CoreStats.compute(item)
	_hp_bar.show_value(UiText.INFO_HP, str(stats["hp"]), Palette.INFO_HP_BAR)
	_mp_bar.show_value(UiText.INFO_MP, str(stats["mp"]), Palette.INFO_MP_BAR)
	var need := Growth.exp_to_next(item.level)
	if need <= 0:
		_exp_bar.show_value(UiText.INFO_EXP, UiText.LEVEL_MAX, Palette.LEVEL_BAR_FILL, 1.0)
	else:
		_exp_bar.show_value(UiText.INFO_EXP, UiText.INFO_EXP_VALUE % [item.exp_points, need], Palette.LEVEL_BAR_FILL, float(item.exp_points) / need)
	var combat := UnitStats.from_core(item)
	for stat: String in _stat_values:
		var accent := stat == item.suffix_id
		(_stat_values[stat] as Label).text = combat.crit_text(stat) if UnitStats.CRIT_STATS.has(stat) else str(stats.get(stat, 0))
		(_stat_values[stat] as Label).add_theme_color_override("font_color", Palette.STAT_ACCENT if accent else Palette.TEXT)
		(_stat_names[stat] as Label).add_theme_color_override("font_color", Palette.STAT_ACCENT if accent else Palette.TEXT_LABEL)
	_show_chips(species, HenchDb.get_species(item.passive_owner_id()), item, combat)
	_party.text = UiText.BTN_PARTY_LEAVE if item.in_party() else UiText.BTN_PARTY
	_lock.text = UiText.BTN_UNLOCK if item.locked else UiText.BTN_LOCK
	_dismantle.disabled = item.locked or item.in_party()
	_mix.disabled = item.locked or item.in_party() or item.variant
	_show_feed()


## 경험치 조각 먹이기 버튼: 다음 레벨까지 조각이 넉넉하면 "레벨업 (조각 n개)", 모자라면 "조각 n개 먹이기"(가진 만큼).
## 못 하면 까닭(주인공 레벨까지 · 경험치 조각 없음)과 함께 꺼진다.
func _show_feed() -> void:
	_feed.visible = show_actions and workshop != null
	if not _feed.visible:
		return
	var problem := workshop.feed_problem(item)
	match problem:
		Workshop.FeedProblem.NONE:
			var need := workshop.shards_to_next(item)
			var have := workshop.wallet.exp_shards
			_feed.text = UiText.BTN_FEED_LEVEL % need if have >= need else UiText.BTN_FEED_SOME % have
		Workshop.FeedProblem.AT_CAP:
			_feed.text = UiText.FEED_PROBLEMS[problem] % workshop.progress.level
		_:
			_feed.text = UiText.FEED_PROBLEMS[problem]
	_feed.disabled = problem != Workshop.FeedProblem.NONE


## 스킬 카드: 고유 액티브(효과 종류 색) · 패시브(유산이면 "유산 패시브") · 변이 또는 믹스 계승(둘 다 아니면 숨김).
## item · stats가 없으면(미리보기) 액티브 · 패시브만, 계수에 지금 값 없이.
func _show_chips(species: HenchSpecies, holder: HenchSpecies, of_item: CoreItem, stats: UnitStats) -> void:
	_caster_color = TribeDb.get_tribe(species.tribe).color
	var active := SkillSheet.active(species, stats) if GameConfig.SKILL_KINDS.has(species.skill) else {}
	_active_chip.visible = not active.is_empty()
	if not active.is_empty():
		_set_chip(_active_chip, UiText.CHIP_ACTIVE, active, Palette.SKILL_COLORS.get(species.skill, Palette.CHIP_PASSIVE))
	var passive := SkillSheet.passive(species, holder)
	_set_chip(_passive_chip, UiText.CHIP_LEGACY if holder != null and holder != species else UiText.CHIP_PASSIVE, passive, Palette.CHIP_PASSIVE)
	var extra := {}
	if of_item != null:
		extra = SkillSheet.variant(of_item) if of_item.variant else SkillSheet.inherit(of_item)
	_extra_chip.visible = not extra.is_empty()
	if of_item != null and of_item.variant:
		_extra_chip.glyph = "variant"
		_set_chip(_extra_chip, UiText.CHIP_VARIANT, extra, Palette.CHIP_VARIANT)
	elif not extra.is_empty():
		_extra_chip.glyph = "inherit"
		_set_chip(_extra_chip, UiText.CHIP_INHERIT, extra, Palette.CHIP_INHERIT)


static func _set_chip(chip: SkillChip, caption: String, sheet: Dictionary, accent: Color) -> void:
	chip.caption = caption
	chip.title = sheet.get("title", "")
	chip.accent = accent
	chip.sheet = sheet


## 스킬 카드(실행 검사용): 0 = 액티브, 1 = 패시브, 2 = 변이 · 계승.
func skill_chip(index: int) -> SkillChip:
	return [_active_chip, _passive_chip, _extra_chip][index]


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
		button.custom_minimum_size.y = BUTTON_FONT_SIZE * 2.4
		UiKit.style_button(button, BUTTON_FONT_SIZE)
		button.pressed.connect(func() -> void:
			_party_pick.visible = false
			party_requested.emit(item, slot))
		_party_slots.add_child(button)
	var cancel := Button.new()
	cancel.text = UiText.BTN_CANCEL
	cancel.custom_minimum_size.y = BUTTON_FONT_SIZE * 2.4
	UiKit.style_button(cancel, BUTTON_FONT_SIZE)
	cancel.pressed.connect(func() -> void: _party_pick.visible = false)
	_party_slots.add_child(cancel)
	_party_pick.visible = true

class_name Boss
extends Hench
## 섬의 왕(보스전, 프로토타입 6 — 연습용 임시 보스, 왕별 전투 규칙은 기획서에서 미정).
## 야생 헨치처럼 위협 점수가 가장 높은 상대를 친다(탱커 도발이 통한다). 체력 구간(BossRules)마다 정해진 장판을 차례대로 깔고,
## 장판을 까는 동안은 멈춰 선다. 장판이 터질 때 안에 있던 파티는 최대 체력의 일정 비율만큼 다친다
## (한 번 깐 장판들이 겹쳐도 한 번만 맞는다).
## 기절하지 않는다(임시). 그림은 큰 원 + 왕관(임시 도형), 체력 바에는 구간 눈금이 그어진다.

# 임시 도형 치수(px)
const BOSS_BODY_RADIUS := 34.0
const BOSS_BODY_CENTER := Vector2(0, -40)
const BOSS_SHADOW := Vector2(38, 15)
const BOSS_EYE_GAP := 10.0
const BOSS_EYE_RADIUS := 4.0
const CROWN_WIDTH := 40.0
const CROWN_HEIGHT := 18.0

## 지금 체력 구간(0부터)
var phase := 0
## 마지막으로 깐 장판에 맞은 파티(실행 검사용). 장판을 깔 때마다 비운다.
var last_hits: Array[Unit] = []

var _intro_left := GameConfig.BOSS_INTRO_SECONDS
var _pattern_left := GameConfig.BOSS_FIRST_PATTERN_SECONDS
var _pattern_count := 0
var _zones: Array[BossZone] = []
var _cast_id := 0  # 장판을 깐 차례 번호
var _cast_hits := {}  # 차례 번호 → 그 차례 장판에 이미 맞은 유닛들(겹친 장판에 두 번 맞지 않게)


static func create_boss(of_species: HenchSpecies) -> Boss:
	var boss := Boss.new()
	boss.species = of_species
	boss.team = Team.WILD
	boss.display_name = of_species.name
	boss.level = of_species.level_min
	boss.stats = UnitStats.for_boss()
	return boss


## 싸움을 건다(처음 노릴 상대).
func engage(target: Unit) -> void:
	_threat[target] = 1.0


## 장판을 까는 중인가(아직 안 터진 장판이 있나).
func is_casting() -> bool:
	return not _zones.is_empty()


func _think_wild(delta: float) -> void:
	_update_phase()
	if _intro_left > 0.0:
		_intro_left -= delta
		return
	_pattern_left -= delta
	if is_casting():
		stop()
		return
	if _pattern_left <= 0.0:
		start_pattern(BossRules.pattern_at(phase, _pattern_count))
		_pattern_count += 1
		_pattern_left = BossRules.pattern_interval(phase)
		return
	var target := _strongest_threat()
	if target == null:
		target = nearest_alive(Team.PARTY)
		if target == null:
			return
		_threat[target] = 1.0
	if in_reach(target, stats.attack_range):
		face(target.position)
		try_attack(target)
	else:
		walk_to(target.position, stats.attack_range * 0.9)


## 다음 체력 구간에 들어서면 "분노!" 하고 그 구간의 장판 차례를 처음부터.
func _update_phase() -> void:
	var now := BossRules.phase_index(hp / stats.max_hp)
	if now == phase:
		return
	phase = now
	_pattern_count = 0
	field.show_number(_number_point() + Vector2(0, -24), UiText.BOSS_PHASE, Palette.NAME_BOSS)


## 장판을 깐다(차례가 되면 스스로 부르고, 실행 검사에서도 부른다).
## breath = 노리는 상대 쪽 부채꼴, lightning = 살아 있는 파티 한 명 한 명 발밑 원, whirl = 내 둘레 고리(곁은 안전).
func start_pattern(kind: String) -> void:
	var spec: Dictionary = GameConfig.BOSS_PATTERNS[kind]
	var shapes: Array[DangerShape] = []
	match kind:
		"breath":
			var target := _strongest_threat()
			var toward := (target.position - position) if target != null else facing
			face(position + toward)
			shapes.append(DangerShape.cone(position, toward, spec["radius"], spec["angle"]))
		"lightning":
			for node in get_tree().get_nodes_in_group(Unit.group_name(Team.PARTY)):
				var unit := node as Unit
				if unit.is_alive():
					shapes.append(DangerShape.circle(unit.position, spec["radius"]))
		"whirl":
			shapes.append(DangerShape.ring(position, spec["inner"], spec["radius"]))
	last_hits.clear()
	stop()
	_cast_id += 1
	_cast_hits[_cast_id] = []
	for shape in shapes:
		var zone := BossZone.new()
		zone.setup(shape, spec["windup"])
		zone.detonated.connect(_on_zone_detonated.bind(float(spec["damage"]), _cast_id))
		field.add_danger(zone)
		_zones.append(zone)
	field.show_number(_number_point(), UiText.BOSS_PATTERN_CAST % UiText.BOSS_PATTERN_NAMES.get(kind, kind), Palette.NAME_BOSS)


## 장판이 터짐: 그 안의 파티가 최대 체력의 damage_ratio만큼 다친다(보호막이 먼저 받는다). 같은 차례에 이미 맞았으면 넘어간다.
func _on_zone_detonated(zone: BossZone, damage_ratio: float, cast_id: int) -> void:
	_zones.erase(zone)
	var hits: Array = _cast_hits.get(cast_id, [])
	if is_alive():
		for node in get_tree().get_nodes_in_group(Unit.group_name(Team.PARTY)):
			var unit := node as Unit
			if unit.is_alive() and zone.shape.contains(unit.position) and not hits.has(unit):
				unit.take_damage(unit.stats.max_hp * damage_ratio, self, false)
				hits.append(unit)
				if cast_id == _cast_id:
					last_hits.append(unit)
	if _zones.is_empty():
		_cast_hits.clear()


## 섬의 왕은 기절하지 않는다(임시).
func stun(_seconds: float) -> void:
	pass


func _on_died() -> void:
	for zone in _zones:
		if is_instance_valid(zone):
			zone.queue_free()
	_zones.clear()
	super()


# ─── 그림 · 이름표 ─────────────────────────────────

func title() -> String:
	return UiText.BOSS_TITLE % display_name


func name_color() -> Color:
	return Palette.NAME_BOSS


func hp_bar_marks() -> Array[float]:
	return BossRules.phase_marks()


func shows_hp_bar() -> bool:
	return true


func body_center() -> Vector2:
	return BOSS_BODY_CENTER


func overlay_height() -> float:
	return -BOSS_BODY_CENTER.y + BOSS_BODY_RADIUS + CROWN_HEIGHT + 6.0


func _draw() -> void:
	draw_colored_polygon(Shapes.ellipse(Vector2.ZERO, BOSS_SHADOW), Palette.SHADOW)
	if targeted:
		Shapes.draw_outline(self, Shapes.ellipse(Vector2.ZERO, BOSS_SHADOW * 1.25), Palette.TARGET_RING, TARGET_RING_WIDTH)
	var center := BOSS_BODY_CENTER + _body_offset()
	draw_circle(center, BOSS_BODY_RADIUS + OUTLINE_WIDTH, Palette.OUTLINE, true, -1.0, true)
	draw_circle(center, BOSS_BODY_RADIUS, Palette.HIT_FLASH if _is_flashing() else species.color, true, -1.0, true)
	if facing.y > -0.5:
		var look := center + Vector2(facing.x * EYE_LOOK * 1.5, -EYE_RAISE)
		draw_circle(look + Vector2(-BOSS_EYE_GAP, 0), BOSS_EYE_RADIUS, Palette.OUTLINE, true, -1.0, true)
		draw_circle(look + Vector2(BOSS_EYE_GAP, 0), BOSS_EYE_RADIUS, Palette.OUTLINE, true, -1.0, true)
	# 왕관: 머리 위 톱니 셋
	var base := center + Vector2(0, -BOSS_BODY_RADIUS + 4.0)
	var half := CROWN_WIDTH * 0.5
	var crown := PackedVector2Array([
		base + Vector2(-half, 0), base + Vector2(-half, -CROWN_HEIGHT), base + Vector2(-half * 0.5, -CROWN_HEIGHT * 0.45),
		base + Vector2(0, -CROWN_HEIGHT), base + Vector2(half * 0.5, -CROWN_HEIGHT * 0.45), base + Vector2(half, -CROWN_HEIGHT),
		base + Vector2(half, 0),
	])
	draw_colored_polygon(crown, Palette.BOSS_CROWN)
	Shapes.draw_outline(self, crown, Palette.OUTLINE, OUTLINE_WIDTH)

class_name Hench
extends Unit
## 헨치. 그림은 색 원 + 역할 글자 + 이름표로 대체한다.
## 내 파티(PARTY): 주인공을 따라다니다가, 주인공이 노리는 적이나 파티를 공격하는 적과 싸운다.
##   모든 헨치가 기본 공격을 한다. 힐러는 그와 함께(대기 시간이 따로) 다친 동료를 회복한다.
##   고유 액티브(스킬)는 풀오토면 알아서, 아니면 스킬 칸을 눌렀을 때 쓴다(대상이 멀면 다가가서).
## 야생(WILD): 자기 자리 주변을 돌아다니다가, 맞으면 위협 점수가 가장 높은 상대에게 반격한다("!").
##   선공(빨간 이름표)은 시야로 파티를 지켜보다가(머리 위 전구가 차오름) 다 알아채면 먼저 덤빈다("!").
##   너무 멀리 쫓아가면 포기하고 돌아간다(파란 표시). 아직 알아채지 못했을 때 수동으로 넣은 첫 타는 기습이다.

# 임시 도형 치수(px)
const BODY_RADIUS := 15.0
const BODY_CENTER := Vector2(0, -17)
const SHADOW_RADIUS := Vector2(16, 7)
const RING_RADIUS := Vector2(20, 9)
## 대상 고리(주인공의 대상일 때 발밑): 크기·굵기, 깜빡이는 빠르기
const TARGET_RING_RADIUS := Vector2(25, 12)
const TARGET_RING_WIDTH := 3.0
const TARGET_RING_PULSE := 6.0
const OUTLINE_WIDTH := 2.0
const LETTER_SIZE := 13
## 역할 글자를 몸 가운데보다 이만큼 아래에(위쪽은 눈 자리)
const LETTER_DROP := 3.0
## 눈: 바라보는 쪽으로 쏠린다. 등을 보이면(화면 위쪽을 보면) 안 보인다.
const EYE_GAP := 4.5
const EYE_RADIUS := 2.0
const EYE_RAISE := 6.0
const EYE_LOOK := 5.0
const FEET_RADIUS := 6.0
const FEET_WIDTH := 22.0
const DOWNED_ALPHA := 0.35
const DEATH_FADE_SECONDS := 0.5

var species: HenchSpecies
## 나이·성별·변이·레벨(기획서 4장, 야생은 나타날 때 정해진다). 쓰러뜨리면 코어에 그대로 담긴다.
## 나이에 따른 외형(부품·크기)은 그림이 들어오면 붙인다. 지금은 대상 창에 글자로만 보인다.
var age := CoreItem.Age.ADULT
var gender := CoreItem.Gender.FEMALE
var level := 1
## 변이체: 지금은 색을 뒤집어 그리고 이름 앞에 "변이"를 붙인다(기획서: 색·크기·속성·모션 변이는 그림 단계에서).
var variant := false:
	set(value):
		variant = value
		display_name = (UiText.VARIANT + " " + species.name) if value else species.name

# 내 파티일 때
var leader: Player
## 고유 액티브(파티일 때만 쓴다). 스킬이 없는 종(왕 · 미정)은 null.
var skill: HenchSkill
## 지금까지 스킬을 쓴 횟수(실행 검사·기록용)
var skill_casts := 0
var _skill_request_left := 0.0  # 스킬 칸을 눌러 부탁받은 뒤 남은 시간. 0 = 부탁 없음
## 따라다닐 때 주인공 기준 자리(화면 px).
var slot := Vector2.ZERO
var _following := false
var _revive_left := 0.0

# 야생일 때
## 돌아다니는 중심(나타난 자리).
var home := Vector2.ZERO
## 돌아다니지 않고 제자리에 선다(실행 검사에서 바라보는 방향을 고정할 때 쓴다).
var hold_still := false
## 감지 게이지(0~1, 선공만). 다 차면 덤빈다. 머리 위 전구로 보인다.
var detect_gauge := 0.0
var _threat := {}  # 공격해 온 상대(Unit) → 위협 점수
var _fight_target: Unit
var _returning := false
var _wander_goal := Vector2.INF
var _wander_wait := 0.0
var _rng := RandomNumberGenerator.new()
var _mark := Mark.NONE  # 잠깐 띄우는 표시("!" · 파란 표시)
var _mark_left := 0.0


static func create(of_species: HenchSpecies, of_team: Team) -> Hench:
	var hench := Hench.new()
	hench.species = of_species
	hench.team = of_team
	hench.display_name = of_species.name
	hench.stats = UnitStats.for_hench(of_species.role, of_team == Team.WILD)
	if of_team == Team.PARTY:
		hench.skill = HenchSkill.for_species(of_species)
	return hench


func _ready() -> void:
	var feet := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = FEET_RADIUS
	capsule.height = FEET_WIDTH
	feet.shape = capsule
	feet.rotation = PI / 2
	add_child(feet)
	_rng.randomize()
	_wander_wait = _rng.randf_range(0.0, GameConfig.WILD_WANDER_PAUSE.y)
	super()


func _think(delta: float) -> void:
	if team == Team.PARTY:
		_think_party()
	else:
		_think_wild(delta)


func _process(delta: float) -> void:
	_mark_left = maxf(_mark_left - delta, 0.0)
	super(delta)


func _physics_process(delta: float) -> void:
	if skill != null:
		skill.tick(delta)
	_skill_request_left = maxf(_skill_request_left - delta, 0.0)
	super(delta)


## 내 헨치: 주인공이 수동 조작 중이면 나도 그렇다고 본다(기습 보너스를 함께 받는다).
func is_manually_controlled() -> bool:
	return team == Team.PARTY and is_instance_valid(leader) and leader.control.is_manual()


# ─── 내 파티 ─────────────────────────────────────

func _think_party() -> void:
	if not is_instance_valid(leader) or not leader.is_alive():
		return
	if _use_skill():
		return  # 스킬을 썼거나, 쓰려고 다가가는 중
	# 회복은 역할 특성이라 기본 공격과 따로 한다. 다친 동료가 멀면 그쪽으로 걸어가는 게 먼저다.
	var going_to_patient := stats.heal > 0.0 and _heal_someone()
	var enemy := _pick_enemy()
	if enemy != null:
		_following = false
		if in_reach(enemy, stats.attack_range):
			try_attack(enemy)
		elif not going_to_patient:
			walk_to(enemy.position, stats.attack_range * 0.9)
		return
	if not going_to_patient:
		_follow_leader()


## 싸울 상대: 파티를 공격 중인 야생 헨치와 주인공이 노리는 대상 중 나에게 가장 가까운 것.
## 주인공에게서 너무 먼 적은 쫓지 않는다.
func _pick_enemy() -> Unit:
	var candidates: Array[Unit] = []
	for node in get_tree().get_nodes_in_group(Unit.group_name(Team.WILD)):
		var wild := node as Hench
		if wild.is_alive() and wild.is_fighting():
			candidates.append(wild)
	if is_instance_valid(leader.hunt_target) and leader.hunt_target.is_alive() and leader.hunt_target not in candidates:
		candidates.append(leader.hunt_target)
	var best: Unit = null
	var best_distance := INF
	for enemy in candidates:
		if Iso.ground_distance(leader.position, enemy.position) > GameConfig.PARTY_LEASH:
			continue
		var d := Iso.ground_distance(position, enemy.position)
		if d < best_distance:
			best = enemy
			best_distance = d
	return best


## 체력이 낮은 동료가 있으면 회복한다. 사거리 밖이라 그쪽으로 걸어가는 중이면 true.
func _heal_someone() -> bool:
	var allies: Array[Unit] = []
	var ratios: Array[float] = []
	for node in get_tree().get_nodes_in_group(Unit.group_name(Team.PARTY)):
		var ally := node as Unit
		if ally.is_alive():
			allies.append(ally)
			ratios.append(ally.hp / ally.stats.max_hp)
	var index := Combat.heal_target_index(ratios, GameConfig.HEAL_THRESHOLD)
	if index < 0:
		return false
	var patient := allies[index]
	if in_reach(patient, stats.attack_range):
		try_heal(patient)
		return false
	_following = false
	walk_to(patient.position, stats.attack_range * 0.9)
	return true


# ─── 스킬 (내 파티) ──────────────────────────────

## 스킬 칸을 눌렀을 때. 쓸 수 있으면 바로(대상이 멀면 다가가서) 쓴다. 대기 중이거나 쓰러져 있으면 false.
func request_skill() -> bool:
	if skill == null or not skill.is_ready() or not is_alive():
		return false
	_skill_request_left = GameConfig.SKILL_REQUEST_SECONDS
	return true


## 스킬 칸을 눌러 쓰려고 기다리는 중인가(스킬 칸 테두리가 하얗게).
func is_skill_requested() -> bool:
	return _skill_request_left > 0.0


## 풀오토면 알아서, 아니면 부탁받았을 때 스킬을 쓴다. 썼거나 쓰려고 다가가는 중이면 true.
## 알아서 쓸 때: 공격은 싸울 상대가 사거리 안에 있을 때, 도발은 둘레에 싸우는 적이 있을 때,
## 회복은 체력이 기준(HEAL_THRESHOLD) 아래인 동료가 있을 때. 눌러서 쓸 때는 조건이 느슨하다.
func _use_skill() -> bool:
	if skill == null or not skill.is_ready():
		return false
	var asked := _skill_request_left > 0.0
	if not asked and not leader.control.auto_skills():
		return false
	var reach := stats.attack_range
	var radius := skill.value("radius")
	match skill.kind:
		"heal":
			var patient := _most_hurt_ally(1.0 if asked else GameConfig.HEAL_THRESHOLD, INF)
			return patient != null and _cast_or_approach(patient, reach, asked)
		"heal_all":
			if asked or _most_hurt_ally(GameConfig.HEAL_THRESHOLD, radius) != null:
				_cast_skill(self)
				return true
			return false
		"taunt":
			if asked or not _wilds_within(position, radius, true).is_empty():
				_cast_skill(self)
				return true
			return false
	var enemy := _pick_enemy()
	if enemy == null and asked:
		enemy = _skill_target()
	return enemy != null and _cast_or_approach(enemy, reach, asked)


## 사거리 안이면 쓰고, 부탁받았는데 멀면 다가간다.
func _cast_or_approach(target: Unit, reach: float, asked: bool) -> bool:
	if in_reach(target, reach):
		_cast_skill(target)
		return true
	if asked:
		_following = false
		walk_to(target.position, reach * 0.9)
		return true
	return false


## 눌러서 쓰는데 싸우는 상대가 없을 때: 주인공의 대상, 없으면 주인공 곁(PARTY_LEASH)의 가장 가까운 야생.
func _skill_target() -> Unit:
	if is_instance_valid(leader.target) and leader.target.is_alive() and leader.target.team == Team.WILD:
		return leader.target
	var best: Unit = null
	var best_distance := INF
	for wild in _wilds_within(leader.position, GameConfig.PARTY_LEASH):
		var d := Iso.ground_distance(position, wild.position)
		if d < best_distance:
			best = wild
			best_distance = d
	return best


func _cast_skill(target: Unit) -> void:
	skill.use()
	skill_casts += 1
	_skill_request_left = 0.0
	if target != self:
		face(target.position)
	var color: Color = Palette.SKILL_COLORS[skill.kind]
	field.show_number(position + Vector2(0, -overlay_height() - 26.0), UiText.SKILL_CAST % skill.title, color)
	var power := skill.value("power")
	var radius := skill.value("radius")
	match skill.kind:
		"strike":
			_skill_hit(target, stats.attack * power)
		"flurry":
			# 몇 번에 나눠 때린다. 트윈은 이 헨치에 묶여 있어서, 헨치가 사라지면 함께 멈춘다.
			var tween := create_tween()
			for i in int(skill.value("hits", 1.0)):
				tween.tween_callback(_skill_hit.bind(target, stats.attack * power))
				tween.tween_interval(skill.value("hit_gap"))
		"blast", "stun":
			field.show_burst(target.position, radius, color)
			for wild in _wilds_within(target.position, radius):
				wild.take_damage(stats.attack * power, self)
				if skill.kind == "stun":
					wild.stun(skill.value("stun"))
		"taunt":
			field.show_burst(position, radius, color)
			for wild in _wilds_within(position, radius):
				wild.taunt(self)
			add_shield(stats.max_hp * skill.value("shield"), skill.value("shield_seconds"))
		"heal":
			target.receive_heal(_heal_power() * power)
		"heal_all":
			field.show_burst(position, radius, color)
			for ally in _allies_within(position, radius):
				ally.receive_heal(_heal_power() * power)


## 스킬 한 대: 사거리가 길면 투사체, 짧으면 몸으로 부딪친다. 그 사이 쓰러진 상대는 건너뛴다.
func _skill_hit(target: Unit, damage: float) -> void:
	if not is_instance_valid(target) or not target.is_alive():
		return
	if stats.attack_range > GameConfig.MELEE_RANGE_MAX:
		field.shoot(self, target, damage)
	else:
		_lunge_left = LUNGE_SECONDS
		target.take_damage(damage, self)


## 회복 스킬의 바탕 값: 회복력(힐러), 없으면 공격력.
func _heal_power() -> float:
	return stats.heal if stats.heal > 0.0 else stats.attack


## 체력 비율이 threshold보다 낮은 동료 중 가장 낮은 것(radius = 나에게서 땅 위 거리). 없으면 null.
func _most_hurt_ally(threshold: float, radius: float) -> Unit:
	var allies := _allies_within(position, radius)
	var ratios: Array[float] = []
	for ally in allies:
		ratios.append(ally.hp / ally.stats.max_hp)
	var index := Combat.heal_target_index(ratios, threshold)
	return allies[index] if index >= 0 else null


## 살아 있는 동료(주인공 포함) 중 center에서 radius 안.
func _allies_within(center: Vector2, radius: float) -> Array[Unit]:
	var result: Array[Unit] = []
	for node in get_tree().get_nodes_in_group(Unit.group_name(Team.PARTY)):
		var ally := node as Unit
		if ally.is_alive() and Iso.ground_distance(center, ally.position) <= radius:
			result.append(ally)
	return result


## 살아 있는 야생 중 center에서 radius 안. fighting_only면 파티와 싸우는 중인 것만.
func _wilds_within(center: Vector2, radius: float, fighting_only := false) -> Array[Hench]:
	var result: Array[Hench] = []
	for node in get_tree().get_nodes_in_group(Unit.group_name(Team.WILD)):
		var wild := node as Hench
		if wild.is_alive() and (wild.is_fighting() or not fighting_only) and Iso.ground_distance(center, wild.position) <= radius:
			result.append(wild)
	return result


## 주인공 곁의 내 자리로 간다. 자리에서 조금 벗어난 정도면 가만히 있는다(덜 부산하게).
func _follow_leader() -> void:
	var spot := leader.position + slot
	if not _following and Iso.ground_distance(position, spot) > GameConfig.FOLLOW_SLACK:
		_following = true
	if _following:
		var far := Iso.ground_distance(position, leader.position) > GameConfig.FOLLOW_CATCHUP_DISTANCE
		if walk_to(spot, 6.0, GameConfig.FOLLOW_CATCHUP_SPEED_SCALE if far else 1.0):
			_following = false


# ─── 야생 ────────────────────────────────────────

## 파티와 싸우는 중인가.
func is_fighting() -> bool:
	return team == Team.WILD and is_instance_valid(_fight_target) and _fight_target.is_alive()


## 야생: 지금 노리는 상대(위협 점수가 가장 높은 상대). 싸우지 않으면 null.
func fight_target() -> Unit:
	return _fight_target if is_fighting() else null


## 아직 파티를 알아채지 못했나(싸우는 중도, 추격을 포기하고 돌아가는 중도 아님).
## 감지 게이지가 차는 중이어도 다 차기 전이면 알아채지 못한 것이다. 이때 수동으로 넣은 첫 타가 기습이다.
func is_unaware() -> bool:
	return team == Team.WILD and _threat.is_empty() and not _returning


func _think_wild(delta: float) -> void:
	var target := _strongest_threat()
	if target != null:
		if Iso.ground_distance(position, home) > GameConfig.WILD_LEASH:
			_give_up()
		elif in_reach(target, stats.attack_range):
			face(target.position)
			try_attack(target)
		else:
			walk_to(target.position, stats.attack_range * 0.9, GameConfig.WILD_CHASE_SPEED_SCALE)
		return
	if _returning:
		if walk_to(home, 8.0, GameConfig.WILD_CHASE_SPEED_SCALE):
			_returning = false
			hp = stats.max_hp
		return
	if species.aggressive and _watch(delta):
		return
	_wander(delta)


## 선공: 시야 안의 파티를 지켜보며 감지 게이지를 채운다. 다 차면 가장 잘 보이는 상대에게 덤빈다("!").
## 지켜보는 동안(게이지가 조금이라도 차 있는 동안)은 멈춰 서서 바라보는 방향을 바꾸지 않는다.
## 그래서 등 뒤나 옆으로 돌아 들어가면 알아채기 전에 기습할 수 있다. 지켜보는 중이면 true.
func _watch(delta: float) -> bool:
	var seen: Unit = null
	var best_rate := 0.0
	var best_distance := INF
	for node in get_tree().get_nodes_in_group(Unit.group_name(Team.PARTY)):
		var other := node as Unit
		if not other.is_alive():
			continue
		var rate := Detection.fill_rate(facing, other.position - position)
		var d := Iso.ground_distance(position, other.position)
		if rate > best_rate or (rate > 0.0 and rate == best_rate and d < best_distance):
			seen = other
			best_rate = rate
			best_distance = d
	detect_gauge = Detection.next_gauge(detect_gauge, best_rate, delta)
	if detect_gauge >= 1.0 and seen != null:
		detect_gauge = 0.0
		_threat[seen] = GameConfig.DETECT_THREAT
		_show_mark(Mark.ALERT, GameConfig.ALERT_MARK_SECONDS)
		return true
	if detect_gauge > 0.0:
		stop()
		return true
	return false


## 위협 점수가 가장 높은 상대. 사라졌거나 쓰러진 상대는 지운다. 상대가 다 없어지면 자리로 돌아간다.
func _strongest_threat() -> Unit:
	var best: Unit = null
	var best_threat := 0.0
	for key: Variant in _threat.keys():
		if not is_instance_valid(key) or not (key as Unit).is_alive():
			_threat.erase(key)
			continue
		if _threat[key] > best_threat:
			best = key
			best_threat = _threat[key]
	if best == null and _fight_target != null:
		_returning = true
	_fight_target = best
	return best


## 도발당함(스킬): 지금 가장 높은 위협 점수보다 높게 by를 노린다. 싸우지 않던 몹도 끌려온다("!").
func taunt(by: Unit) -> void:
	if team != Team.WILD or not is_alive():
		return
	if _threat.is_empty():
		_show_mark(Mark.ALERT, GameConfig.ALERT_MARK_SECONDS)
	var top := 0.0
	for value: float in _threat.values():
		top = maxf(top, value)
	_threat[by] = top + GameConfig.TAUNT_THREAT
	_returning = false
	detect_gauge = 0.0


func _give_up() -> void:
	_threat.clear()
	_fight_target = null
	_returning = true
	_show_mark(Mark.GIVE_UP, GameConfig.GIVE_UP_MARK_SECONDS)


func _wander(delta: float) -> void:
	if hold_still:
		return
	if _wander_goal != Vector2.INF:
		if walk_to(_wander_goal, 6.0, GameConfig.WILD_WANDER_SPEED_SCALE):
			_wander_goal = Vector2.INF
			_wander_wait = _rng.randf_range(GameConfig.WILD_WANDER_PAUSE.x, GameConfig.WILD_WANDER_PAUSE.y)
		return
	_wander_wait -= delta
	if _wander_wait > 0.0:
		return
	# 땅 위에서 원을 그리도록 화면 세로는 타일 비율만큼 줄인다.
	var offset := Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(20.0, GameConfig.WILD_WANDER_RADIUS)
	offset.y *= GameConfig.TILE_SIZE.y / GameConfig.TILE_SIZE.x
	var goal := home + offset
	if field.is_walkable(goal):
		_wander_goal = goal
	else:
		_wander_wait = 0.5


# ─── 맞았을 때·쓰러졌을 때 ─────────────────────────

func _on_damaged(amount: float, from: Unit) -> void:
	if team != Team.WILD or from == null or not is_instance_valid(from):
		return
	if _threat.is_empty():
		_show_mark(Mark.ALERT, GameConfig.ALERT_MARK_SECONDS)  # 싸우지 않던 중에 맞으면 "!" 하고 반격
	detect_gauge = 0.0
	var is_tank := from is Hench and (from as Hench).species.role == "tank"
	_threat[from] = float(_threat.get(from, 0.0)) + Combat.threat(amount, is_tank)
	_returning = false


func _on_died() -> void:
	if team == Team.PARTY:
		_revive_left = GameConfig.HENCH_REVIVE_SECONDS
		modulate.a = DOWNED_ALPHA
		return
	remove_from_group(Unit.group_name(Team.WILD))
	var fade := create_tween()
	fade.tween_property(self, "modulate:a", 0.0, DEATH_FADE_SECONDS)
	fade.tween_callback(queue_free)


## 기습: 아직 알아채지 못한 야생에게, 수동 조작 중인 파티가 넣은 첫 타.
func _is_ambushed_by(from: Unit) -> bool:
	return is_unaware() and from.team == Team.PARTY and from.is_manually_controlled()


func _dead_tick(delta: float) -> void:
	if team != Team.PARTY or not is_instance_valid(leader) or not leader.is_alive():
		return
	_revive_left -= delta
	if _revive_left <= 0.0:
		revive_at(leader.position + slot)


# ─── 그림 ────────────────────────────────────────

func body_center() -> Vector2:
	return BODY_CENTER


func overlay_height() -> float:
	return -BODY_CENTER.y + BODY_RADIUS + 6.0


## 쓰러뜨렸을 때 떨어질 코어의 바탕(종·나이·성별·변이·레벨). 접미사·빛남은 떨어질 때 정해진다.
func core_template() -> CoreItem:
	var item := CoreItem.new()
	item.species_id = species.id
	item.age = age
	item.gender = gender
	item.level = level
	item.variant = variant
	return item


## 대상 창 제목: 야생은 나이까지 보여 준다(외형이 없는 동안).
func title() -> String:
	if team == Team.WILD:
		return "%s · %s" % [display_name, UiText.AGE_NAMES[age]]
	return display_name


func name_color() -> Color:
	if team == Team.PARTY:
		return Palette.NAME_ALLY
	return Palette.NAME_AGGRESSIVE if species.aggressive else Palette.NAME_PASSIVE


func mark() -> Mark:
	if is_stunned():
		return Mark.STUNNED
	if _mark_left > 0.0:
		return _mark
	if detect_gauge > 0.0:
		return Mark.DETECTING
	return Mark.NONE


func detect_ratio() -> float:
	return detect_gauge


func _show_mark(kind: Mark, seconds: float) -> void:
	_mark = kind
	_mark_left = seconds


func shows_hp_bar() -> bool:
	return team == Team.PARTY or super()


## 몸 색(임시 도형). 변이체는 색상환을 반 바퀴 돌린 색.
func body_color() -> Color:
	if not variant:
		return species.color
	var c := species.color
	return Color.from_hsv(fposmod(c.h + 0.5, 1.0), maxf(c.s, 0.45), c.v)


func _draw() -> void:
	draw_colored_polygon(Shapes.ellipse(Vector2.ZERO, SHADOW_RADIUS), Palette.SHADOW)
	if team == Team.PARTY:
		Shapes.draw_outline(self, Shapes.ellipse(Vector2.ZERO, RING_RADIUS), Palette.ALLY_RING, 2.0)
	if targeted:
		var ring := Palette.TARGET_RING
		ring.a *= 0.75 + 0.25 * sin(Time.get_ticks_msec() * 0.001 * TARGET_RING_PULSE)
		Shapes.draw_outline(self, Shapes.ellipse(Vector2.ZERO, TARGET_RING_RADIUS), ring, TARGET_RING_WIDTH)
	var center := BODY_CENTER + _body_offset()
	draw_circle(center, BODY_RADIUS + OUTLINE_WIDTH, Palette.OUTLINE, true, -1.0, true)
	draw_circle(center, BODY_RADIUS, Palette.HIT_FLASH if _is_flashing() else body_color(), true, -1.0, true)
	# 눈: 바라보는 쪽을 알려 준다(선공 몬스터의 등 뒤로 돌아 들어갈 때 보는 곳).
	if facing.y > -0.5:
		var look := center + Vector2(facing.x * EYE_LOOK, -EYE_RAISE)
		draw_circle(look + Vector2(-EYE_GAP, 0), EYE_RADIUS, Palette.OUTLINE, true, -1.0, true)
		draw_circle(look + Vector2(EYE_GAP, 0), EYE_RADIUS, Palette.OUTLINE, true, -1.0, true)
	var letter: String = UiText.ROLE_SHORT.get(species.role, "")
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, LETTER_SIZE).x
	draw_string(font, center + Vector2(-width * 0.5, LETTER_SIZE * 0.35 + LETTER_DROP), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, LETTER_SIZE, Palette.OUTLINE)

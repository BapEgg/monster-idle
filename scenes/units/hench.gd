class_name Hench
extends Unit
## 헨치. 그림은 색 원 + 역할 글자 + 이름표로 대체한다.
## 내 파티(PARTY): 주인공을 따라다니다가, 주인공이 노리는 적이나 파티를 공격하는 적과 싸운다.
##   모든 헨치가 기본 공격을 한다. 힐러는 그와 함께(대기 시간이 따로) 다친 동료를 회복한다.
## 야생(WILD): 자기 자리 주변을 돌아다니다가, 맞으면 위협 점수가 가장 높은 상대에게 반격한다("!").
##   선공(빨간 이름표)은 시야로 파티를 지켜보다가(머리 위 전구가 차오름) 다 알아채면 먼저 덤빈다("!").
##   너무 멀리 쫓아가면 포기하고 돌아간다(파란 표시). 아직 알아채지 못했을 때 수동으로 넣은 첫 타는 기습이다.

# 임시 도형 치수(px)
const BODY_RADIUS := 15.0
const BODY_CENTER := Vector2(0, -17)
const SHADOW_RADIUS := Vector2(16, 7)
const RING_RADIUS := Vector2(20, 9)
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

# 내 파티일 때
var leader: Player
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


## 내 헨치: 주인공이 수동 조작 중이면 나도 그렇다고 본다(기습 보너스를 함께 받는다).
func is_manually_controlled() -> bool:
	return team == Team.PARTY and is_instance_valid(leader) and leader.control.is_manual()


# ─── 내 파티 ─────────────────────────────────────

func _think_party() -> void:
	if not is_instance_valid(leader) or not leader.is_alive():
		return
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
	var hunted := leader.hunt_target
	if is_instance_valid(hunted) and hunted.is_alive() and hunted not in candidates:
		candidates.append(hunted)
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


func name_color() -> Color:
	if team == Team.PARTY:
		return Palette.NAME_ALLY
	return Palette.NAME_AGGRESSIVE if species.aggressive else Palette.NAME_PASSIVE


func mark() -> Mark:
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


func _draw() -> void:
	draw_colored_polygon(Shapes.ellipse(Vector2.ZERO, SHADOW_RADIUS), Palette.SHADOW)
	if team == Team.PARTY:
		Shapes.draw_outline(self, Shapes.ellipse(Vector2.ZERO, RING_RADIUS), Palette.ALLY_RING, 2.0)
	var center := BODY_CENTER + _body_offset()
	draw_circle(center, BODY_RADIUS + OUTLINE_WIDTH, Palette.OUTLINE, true, -1.0, true)
	draw_circle(center, BODY_RADIUS, Palette.HIT_FLASH if _is_flashing() else species.color, true, -1.0, true)
	# 눈: 바라보는 쪽을 알려 준다(선공 몬스터의 등 뒤로 돌아 들어갈 때 보는 곳).
	if facing.y > -0.5:
		var look := center + Vector2(facing.x * EYE_LOOK, -EYE_RAISE)
		draw_circle(look + Vector2(-EYE_GAP, 0), EYE_RADIUS, Palette.OUTLINE, true, -1.0, true)
		draw_circle(look + Vector2(EYE_GAP, 0), EYE_RADIUS, Palette.OUTLINE, true, -1.0, true)
	var letter: String = UiText.ROLE_SHORT.get(species.role, "")
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, LETTER_SIZE).x
	draw_string(font, center + Vector2(-width * 0.5, LETTER_SIZE * 0.35 + LETTER_DROP), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, LETTER_SIZE, Palette.OUTLINE)

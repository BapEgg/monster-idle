class_name Hench
extends Unit
## 헨치. 그림은 색 원 + 역할 글자 + 이름표로 대체한다.
## 내 파티(PARTY): 주인공을 따라다니다가, 주인공이 노리는 적이나 파티를 공격하는 적과 싸운다. 힐러는 다친 동료부터 회복한다.
## 야생(WILD): 자기 자리 주변을 돌아다니다가, 맞으면 위협 점수가 가장 높은 상대에게 반격한다(먼저 덤비지는 않는다).

# 임시 도형 치수(px)
const BODY_RADIUS := 15.0
const BODY_CENTER := Vector2(0, -17)
const SHADOW_RADIUS := Vector2(16, 7)
const RING_RADIUS := Vector2(20, 9)
const OUTLINE_WIDTH := 2.0
const LETTER_SIZE := 13
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
var _threat := {}  # 공격해 온 상대(Unit) → 위협 점수
var _fight_target: Unit
var _returning := false
var _wander_goal := Vector2.INF
var _wander_wait := 0.0
var _rng := RandomNumberGenerator.new()


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


# ─── 내 파티 ─────────────────────────────────────

func _think_party() -> void:
	if not is_instance_valid(leader) or not leader.is_alive():
		return
	if species.role == "healer" and _heal_someone():
		return
	var enemy := _pick_enemy()
	if enemy != null:
		_following = false
		if in_reach(enemy, stats.attack_range):
			face(enemy.position)
			try_attack(enemy)
		else:
			walk_to(enemy.position, stats.attack_range * 0.9)
		return
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


## 체력이 낮은 동료가 있으면 다가가 회복한다. 회복할 동료가 있으면 true.
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
	_following = false
	if in_reach(patient, stats.attack_range):
		face(patient.position)
		try_heal(patient)
	else:
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
	_wander(delta)


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


func _wander(delta: float) -> void:
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
	return Palette.NAME_ALLY if team == Team.PARTY else Palette.NAME_PASSIVE


func shows_hp_bar() -> bool:
	return team == Team.PARTY or super()


func _draw() -> void:
	draw_colored_polygon(Shapes.ellipse(Vector2.ZERO, SHADOW_RADIUS), Palette.SHADOW)
	if team == Team.PARTY:
		Shapes.draw_outline(self, Shapes.ellipse(Vector2.ZERO, RING_RADIUS), Palette.ALLY_RING, 2.0)
	var center := BODY_CENTER + _body_offset()
	draw_circle(center, BODY_RADIUS + OUTLINE_WIDTH, Palette.OUTLINE, true, -1.0, true)
	draw_circle(center, BODY_RADIUS, Palette.HIT_FLASH if _is_flashing() else species.color, true, -1.0, true)
	var letter: String = UiText.ROLE_SHORT.get(species.role, "")
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, LETTER_SIZE).x
	draw_string(font, center + Vector2(-width * 0.5, LETTER_SIZE * 0.35), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, LETTER_SIZE, Palette.OUTLINE)

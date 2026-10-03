class_name JobCaster
extends RefCounted
## 주인공의 직업 스킬 쓰기(직업 1차, 기획서 3장). 장착한 액티브 3칸 + 궁극기 1칸(스킬 칸 4~6 + 궁극기 칸).
## 풀오토면 알아서 쓰고(헨치 스킬과 같다), 아니면 칸을 눌러 부탁받은 스킬만 쓴다. 부탁은 GameConfig.SKILL_REQUEST_SECONDS 뒤 없던 일로.
## 알아서 쓸 때: 때리는 스킬은 대상이 닿을 때, 회복은 체력이 기준 아래인 동료가 있을 때, 일으키기는 쓰러진 헨치가 있을 때,
## 그 밖(도발 · 보호막 · 강화 · 연막 · 휩쓸기 · 내 둘레 범위)은 싸우는 적이 곁에 있을 때. 눌러서 쓸 때는 조건이 느슨하다.
## 효과(JobSkill.effects, GameConfig.JOB_SKILLS)마다 필드에 직접 피해 · 기절 · 보호막 · 강화 …를 건다. 연출은 임시 도형.

## 칸 수: 액티브(GameConfig.JOB_ACTIVE_SLOTS) + 궁극기 1. 마지막 칸이 궁극기다.
const SLOT_COUNT := 4
## 내 곁에서 싸우는 적이 있다고 보는 거리(땅 위 px, 도발 · 강화 · 보호막을 알아서 쓸 때)
const COMBAT_RADIUS := 260.0
## 돌진하면 대상에게서 이만큼 떨어져 선다(땅 위 px) · 물러나는 데 걸리는 시간(초)
const DASH_GAP := 40.0
const RETREAT_SECONDS := 0.18

enum Result { NONE, CAST, APPROACH }

var player: Player
## 칸마다 스킬(빈 칸 = null)
var skills: Array[JobSkill] = []
## 지금까지 쓴 횟수(실행 검사용)
var casts := 0

var _requests := PackedFloat64Array()


func _init(of_player: Player = null) -> void:
	player = of_player
	for i in SLOT_COUNT:
		skills.append(null)
		_requests.append(0.0)


## 칸마다 스킬을 바꿔 끼운다. 같은 스킬이 남아 있으면 대기 시간을 이어 간다.
func set_skills(list: Array[JobSkill]) -> void:
	for i in SLOT_COUNT:
		var fresh: JobSkill = list[i] if i < list.size() else null
		if fresh != null:
			for old in skills:
				if old != null and old.id == fresh.id:
					fresh.left = old.left
		skills[i] = fresh
		if fresh == null:
			_requests[i] = 0.0


func tick(delta: float) -> void:
	for skill in skills:
		if skill != null:
			skill.tick(delta)
	for i in SLOT_COUNT:
		_requests[i] = maxf(_requests[i] - delta, 0.0)


## 칸을 눌러 부탁한다. 쓸 수 없으면(빈 칸 · 대기 중) false.
func request(index: int) -> bool:
	if index < 0 or index >= SLOT_COUNT or skills[index] == null or not skills[index].is_ready():
		return false
	_requests[index] = GameConfig.SKILL_REQUEST_SECONDS
	return true


func is_requested(index: int) -> bool:
	return index >= 0 and index < SLOT_COUNT and _requests[index] > 0.0


## 매 물리 프레임. auto = 알아서 쓰나(풀오토), may_move = 부탁받은 스킬의 대상에게 다가가도 되나(조이스틱을 쥐고 있지 않으면).
## 대상에게 다가가는 중이면 true(그동안 다른 이동을 하지 않는다). 한 프레임에 하나만 쓴다.
func update(auto: bool, may_move: bool) -> bool:
	for i in SLOT_COUNT:
		var skill := skills[i]
		if skill == null or not skill.is_ready():
			continue
		var asked := _requests[i] > 0.0
		if not asked and not auto:
			continue
		match _try(skill, asked, may_move):
			Result.CAST:
				_requests[i] = 0.0
				return false
			Result.APPROACH:
				return true
	return false


func _try(skill: JobSkill, asked: bool, may_move: bool) -> Result:
	if skill.needs_enemy():
		var foe := _foe(asked)
		if foe == null:
			return Result.NONE
		var reach := maxf(skill.reach(), player.stats.attack_range)
		if player.in_reach(foe, reach):
			_cast(skill, foe)
			return Result.CAST
		if asked and may_move:
			player.walk_to(foe.position, reach * 0.9)
			return Result.APPROACH
		return Result.NONE
	var first: Dictionary = skill.effects[0]
	var ready_now := asked
	match str(first.get("type", "")):
		"heal":
			ready_now = asked or _lowest_ally(GameConfig.JOB_AUTO_HEAL_THRESHOLD) != null
		"revive":
			ready_now = not _downed().is_empty() or (asked and skill.effects.size() > 1)
		_:
			ready_now = asked or not player.wilds_within(player.position, COMBAT_RADIUS, true).is_empty()
	if not ready_now:
		return Result.NONE
	_cast(skill, _foe(false))
	return Result.CAST


## 때릴 상대: 지금 싸우는 상대 → 대상 → (부탁받았으면) 곁의 가장 가까운 야생.
func _foe(wide: bool) -> Unit:
	for unit: Unit in [player.hunt_target, player.target]:
		if is_instance_valid(unit) and unit.is_alive() and unit.team == Unit.Team.WILD:
			return unit
	if not wide:
		return null
	var best: Unit = null
	var best_distance := INF
	for wild in player.wilds_within(player.position, GameConfig.TARGET_KEEP_RANGE):
		var d := Iso.ground_distance(player.position, wild.position)
		if d < best_distance:
			best = wild
			best_distance = d
	return best


func _cast(skill: JobSkill, foe: Unit) -> void:
	skill.use()
	casts += 1
	player.field.show_number(player.position + Vector2(0, -player.overlay_height() - 26.0), UiText.SKILL_CAST % skill.title, Palette.JOB_SKILL_CAST)
	if foe != null:
		player.face(foe.position)
	for effect in skill.effects:
		_apply(effect, foe)


# ─── 효과 ───────────────────────────────────────

func _apply(effect: Dictionary, foe: Unit) -> void:
	var coefs: Dictionary = effect.get("coefs", {})
	var damage := player.skill_amount(coefs)
	var radius := float(effect.get("radius", 0.0))
	var color: Color = Palette.JOB_EFFECT_COLORS.get(str(effect.get("type", "")), Palette.JOB_SKILL_CAST)
	match str(effect.get("type", "")):
		"hit":
			if foe == null:
				return
			var ranged := float(effect.get("range", 0.0)) > GameConfig.MELEE_RANGE_MAX or player.stats.attack_range > GameConfig.MELEE_RANGE_MAX
			_repeat(int(effect.get("hits", 1)), float(effect.get("gap", 0.0)), _hit.bind(foe, damage, ranged))
		"area":
			var center := foe.position if effect.get("at", "target") == "target" and foe != null else player.position
			player.field.show_burst(center, radius, color)
			for wild in player.wilds_within(center, radius):
				wild.take_damage(damage, player)
				if effect.has("stun"):
					wild.stun(float(effect["stun"]))
				if effect.has("vulnerable"):
					wild.add_boost("vulnerable", float(effect["vulnerable"]), float(effect.get("seconds", 0.0)))
		"taunt":
			player.field.show_burst(player.position, radius, color)
			for wild in player.wilds_within(player.position, radius):
				wild.taunt(player)
		"shield":
			var amount := player.stats.max_hp * float(effect.get("amount", 0.0))
			for unit in _receivers(str(effect.get("who", "self"))):
				unit.add_shield(amount, float(effect.get("seconds", 0.0)))
			player.field.show_burst(player.position, GameConfig.JOB_PARTY_RADIUS * 0.3 if effect.get("who") == "party" else 0.0, color)
		"dash":
			if foe == null:
				return
			var away := (player.position - foe.position).normalized()
			player.place_at(foe.position + Iso.from_ground(Iso.to_ground(away).normalized() * DASH_GAP))
			player.face(foe.position)
			if radius > 0.0:
				player.field.show_burst(foe.position, radius, color)
				for wild in player.wilds_within(foe.position, radius):
					wild.take_damage(damage, player)
			else:
				_hit(foe, damage, false)
		"retreat":
			if foe == null:
				return
			_hit(foe, damage, player.stats.attack_range > GameConfig.MELEE_RANGE_MAX)
			var back := Iso.to_ground(player.position - foe.position).normalized()
			var goal := player.position + Iso.from_ground(back * float(effect.get("distance", 0.0)))
			if player.field.is_walkable(goal):
				player.create_tween().tween_property(player, "position", goal, RETREAT_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		"pierce":
			if foe == null:
				return
			var along := Iso.to_ground(foe.position - player.position).normalized()
			var length := float(effect.get("length", 0.0))
			var width := float(effect.get("width", 0.0))
			player.field.show_beam(player.position, player.position + Iso.from_ground(along * length), width, color)
			for wild in player.wilds_within(player.position, length):
				var offset := Iso.to_ground(wild.position - player.position)
				var t := offset.dot(along)
				if t >= 0.0 and t <= length and absf(offset.cross(along)) <= width:
					wild.take_damage(damage, player)
		"smoke":
			player.field.show_burst(player.position, radius, color)
			for wild in player.wilds_within(player.position, radius):
				wild.stun(float(effect.get("seconds", 0.0)))
				wild.lose_track()
		"heal":
			var amount := player.skill_amount(coefs, true)
			if effect.get("who", "lowest") == "lowest":
				var patient := _lowest_ally(1.0)
				if patient != null:
					patient.receive_heal(amount)
			else:
				player.field.show_burst(player.position, radius, color)
				for ally in player.allies_within(player.position, radius):
					ally.receive_heal(amount)
					if effect.get("cleanse", false):
						ally.clear_stun()
		"revive":
			var count := int(effect.get("count", 1))
			for hench in _downed():
				if count <= 0:
					break
				hench.revive_at(hench.position)
				hench.hp = hench.stats.max_hp * float(effect.get("hp", 1.0))
				player.field.show_burst(hench.position, 40.0, color)
				count -= 1
		"buff":
			for unit in _receivers(str(effect.get("who", "self"))):
				for key: String in JobRules.BUFF_KEYS:
					if effect.has(key):
						unit.add_boost(key, float(effect[key]), float(effect.get("seconds", 0.0)))
			player.field.show_burst(player.position, GameConfig.JOB_PARTY_RADIUS * 0.3 if effect.get("who") == "party" else 0.0, color)
		"storm":
			_repeat(int(effect.get("hits", 1)), float(effect.get("gap", 0.0)), _sweep.bind(radius, damage, color))


## 효과를 몇 번 되풀이(gap초 간격). 트윈은 주인공에 묶여 있어 주인공이 사라지면 함께 멈춘다.
func _repeat(times: int, gap: float, action: Callable) -> void:
	if times <= 1:
		action.call()
		return
	var tween := player.create_tween()
	for i in times:
		tween.tween_callback(action)
		tween.tween_interval(gap)


## 한 대: 원거리면 투사체, 근접이면 몸으로 부딪친다. 그 사이 쓰러진 상대는 건너뛴다.
func _hit(foe: Unit, damage: float, ranged: bool) -> void:
	if not is_instance_valid(foe) or not foe.is_alive():
		return
	if ranged:
		player.field.shoot(player, foe, damage)
	else:
		player.lunge()
		foe.take_damage(damage, player)


## 휩쓸기 한 번: 내 둘레의 적 모두.
func _sweep(radius: float, damage: float, color: Color) -> void:
	if not player.is_alive():
		return
	player.field.show_burst(player.position, radius, color)
	for wild in player.wilds_within(player.position, radius):
		wild.take_damage(damage, player)


## 받는 쪽: self = 나, party = 곁의 내 편 모두(GameConfig.JOB_PARTY_RADIUS).
func _receivers(who: String) -> Array[Unit]:
	if who == "party":
		return player.allies_within(player.position, GameConfig.JOB_PARTY_RADIUS)
	var me: Array[Unit] = [player]
	return me


## 체력 비율이 threshold보다 낮은 내 편 중 가장 낮은 것(주인공 포함). 없으면 null.
func _lowest_ally(threshold: float) -> Unit:
	var best: Unit = null
	var best_ratio := threshold
	for ally in player.allies_within(player.position, GameConfig.JOB_PARTY_RADIUS):
		var ratio := ally.hp / ally.stats.max_hp
		if ratio < best_ratio:
			best = ally
			best_ratio = ratio
	return best


## 쓰러진 파티 헨치들.
func _downed() -> Array[Hench]:
	var list: Array[Hench] = []
	for node in player.get_tree().get_nodes_in_group(Unit.group_name(Unit.Team.PARTY)):
		var hench := node as Hench
		if hench != null and not hench.is_alive():
			list.append(hench)
	return list

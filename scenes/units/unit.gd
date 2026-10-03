class_name Unit
extends CharacterBody2D
## 필드 위에서 싸우는 모든 것(주인공·내 헨치·야생 헨치)의 바탕.
## 체력, 공격·회복, 길찾기 이동, 이름표·체력 바를 맡는다. 무엇을 할지는 하위 클래스의 _think()가 정한다.
## 원점 = 발밑(y정렬 기준).

signal died(unit: Unit)

enum Team { PARTY, WILD }
## 머리 위 표시: 없음 / 감지 중(전구가 차오름) / 알아채고 덤빔·맞고 반격("!") / 추격 포기(파란 표시) / 기절(별이 돈다)
enum Mark { NONE, DETECTING, ALERT, GIVE_UP, STUNNED }

## 충돌 층: 1 = 지형(나무·바위·가장자리), 2 = 유닛. 유닛끼리는 부딪치지 않고 지형에만 막힌다.
const LAYER_WORLD := 1
const LAYER_UNITS := 2
## 길찾기: 경유점에 이만큼 가까워지면 다음 경유점으로. 목표가 이만큼 움직였거나 일정 시간이 지나면 길을 다시 찾는다.
const WAYPOINT_REACHED := 10.0
const REPATH_GOAL_MOVED := 24.0
const REPATH_SECONDS := 0.5
# 연출(임시 도형): 공격할 때 앞으로 튀어나가는 거리·시간, 맞았을 때 하얗게 번쩍이는 시간
const LUNGE_DISTANCE := 8.0
const LUNGE_SECONDS := 0.12
const FLASH_SECONDS := 0.12
## 강화 · 약화 종류: attack = 공격 +, speed = 공격 속도 +, guard = 받는 피해 −, vulnerable = 받는 피해 +
const BOOST_KINDS := ["attack", "speed", "guard", "vulnerable"]

## 치명타 굴림 고정(실행 검사가 정확한 피해를 잴 때): -1 = 굴린다, 0 = 늘 아님, 1 = 늘 치명.
static var crit_override := -1
static var _crit_rng := _seeded_rng()

var team := Team.PARTY
## 머리 위 이름표. 비우면 이름표를 안 그린다.
var display_name := ""
var stats: UnitStats
var hp := 0.0
var field: Field
## 바라보는 화면 방향(길이 1).
var facing := Vector2.DOWN
## 주인공의 대상으로 지정됐나(발밑 고리, 체력 바를 늘 보임).
var targeted := false
## 보호막(스킬): 피해를 먼저 받아 준다. 정해진 시간이 지나면 사라진다. 체력 바 위에 막대로 보인다.
var shield := 0.0
## 늘 받는 피해 배율(직업 패시브: 철벽 자세 · 전우애). 1 = 그대로.
var damage_taken_scale := 1.0
## 기습 배율에 더하는 값(직업 패시브: 기습의 달인). 이 유닛이 넣은 기습이 이만큼 더 세다.
var ambush_bonus := 0.0

var _delta := 0.0
var _cooldown := 0.0
var _heal_cooldown := 0.0
var _desired := Vector2.ZERO  # 이번 프레임 이동(화면 방향, 길이 0~1)
var _speed_scale := 1.0
var _path := PackedVector2Array()
var _path_goal := Vector2.INF
var _repath_left := 0.0
var _lunge_left := 0.0
var _flash_left := 0.0
var _shield_left := 0.0
var _stun_left := 0.0
var _dodge_to := Vector2.INF  # 장판을 피해 가는(간) 자리. 장판이 다 터질 때까지 그 자리에 머문다
var _boosts := {}  # 강화 · 약화(직업 스킬): 종류 → [양, 남은 초]. 종류는 BOOST_KINDS


static func group_name(of_team: Team) -> StringName:
	return &"party" if of_team == Team.PARTY else &"wild"


func is_alive() -> bool:
	return hp > 0.0


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = LAYER_UNITS
	collision_mask = LAYER_WORLD
	add_to_group(group_name(team))
	hp = stats.max_hp
	var overlay := UnitOverlay.new()
	overlay.unit = self
	add_child(overlay)


func _physics_process(delta: float) -> void:
	_delta = delta
	_cooldown = maxf(_cooldown - delta, 0.0)
	_heal_cooldown = maxf(_heal_cooldown - delta, 0.0)
	_shield_left = maxf(_shield_left - delta, 0.0)
	if _shield_left <= 0.0:
		shield = 0.0
	_stun_left = maxf(_stun_left - delta, 0.0)
	for kind: String in _boosts.keys():
		_boosts[kind][1] -= delta
		if _boosts[kind][1] <= 0.0:
			_boosts.erase(kind)
	_desired = Vector2.ZERO
	_speed_scale = 1.0
	if is_alive():
		if not is_stunned():  # 기절하면 아무것도 못 한다(움직이기 · 공격 · 회복)
			_think(delta)
	else:
		_dead_tick(delta)
	# 바라보는 방향은 가려던 방향으로만 정한다(밀려나는 건 몸만 움직인다).
	if _desired.length() > 0.1:
		facing = _desired.normalized()
	if is_alive() and _uses_personal_space():
		_desired = (_desired + _personal_space_push()).limit_length(1.0)
	velocity = Iso.move_velocity(_desired, stats.speed * _speed_scale, GameConfig.MOVE_VERTICAL_RATIO)
	move_and_slide()


func _process(delta: float) -> void:
	_lunge_left = maxf(_lunge_left - delta, 0.0)
	_flash_left = maxf(_flash_left - delta, 0.0)
	queue_redraw()


## 하위 클래스: 살아 있을 때 매 물리 프레임 할 일(어디로 갈지, 누구를 칠지).
func _think(_delta_time: float) -> void:
	pass


## 하위 클래스: 쓰러져 있을 때 매 물리 프레임 할 일(다시 일어나기 대기 등).
func _dead_tick(_delta_time: float) -> void:
	pass


## 하위 클래스: 맞았을 때(위협 점수 쌓기 등).
func _on_damaged(_amount: float, _from: Unit) -> void:
	pass


## 하위 클래스: 쓰러졌을 때.
func _on_died() -> void:
	pass


## 하위 클래스: 지금 수동 조작 중인가(주인공이 직접 움직이는 중). 기습 보너스는 이때만 준다.
func is_manually_controlled() -> bool:
	return false


## 하위 클래스: from의 이번 공격이 기습인가(아직 파티를 알아채지 못했고, 수동 조작 중).
func _is_ambushed_by(_from: Unit) -> bool:
	return false


# ─── 이동 ────────────────────────────────────────

## 그 자리로 순간이동한다.
func place_at(point: Vector2) -> void:
	position = point
	reset_physics_interpolation()
	stop()


## 이번 프레임은 입력 방향(화면 방향, 길이 0~1)대로 움직인다.
func move_by_input(input: Vector2) -> void:
	_desired = input


## 그 지점으로 길을 찾아 걸어간다. arrive(땅 위 px) 안에 들어오면 멈추고 true.
func walk_to(point: Vector2, arrive := 6.0, speed_scale := 1.0) -> bool:
	if Iso.ground_distance(position, point) <= arrive:
		stop()
		return true
	_repath_left -= _delta
	if _path_goal == Vector2.INF or Iso.ground_distance(_path_goal, point) > REPATH_GOAL_MOVED or _repath_left <= 0.0:
		_path = field.find_path(position, point)
		_path_goal = point
		_repath_left = REPATH_SECONDS
	while not _path.is_empty() and Iso.ground_distance(position, _path[0]) <= WAYPOINT_REACHED:
		_path.remove_at(0)
	var next := point if _path.is_empty() else _path[0]
	# 한 걸음에 지나쳐 버리지 않게, 남은 거리가 한 걸음보다 짧으면 그만큼만 간다.
	var step := stats.speed * speed_scale * _delta
	var remaining := Iso.ground_distance(position, next)
	_desired = (next - position).normalized() * minf(1.0, remaining / maxf(step, 0.001))
	_speed_scale = speed_scale
	return false


func stop() -> void:
	_path.clear()
	_path_goal = Vector2.INF


## 하위 클래스: 개인 공간(겹치지 않게 서로 밀어내기)을 쓰나. 직접 조작 중인 주인공은 끈다.
func _uses_personal_space() -> bool:
	return true


## 가까이 붙은 다른 유닛들에게서 멀어지는 방향(화면 방향, 길이 0~GameConfig.PERSONAL_SPACE_PUSH).
## 유닛끼리는 부딪치지 않으므로, 이게 없으면 싸움이 붙은 곳에서 한 점에 겹쳐 이름표를 읽을 수 없다.
func _personal_space_push() -> Vector2:
	var radius := GameConfig.PERSONAL_SPACE
	var push := Vector2.ZERO
	for group: StringName in [group_name(Team.PARTY), group_name(Team.WILD)]:
		for node in get_tree().get_nodes_in_group(group):
			var other := node as Unit
			if other == self or not other.is_alive():
				continue
			var d := Iso.ground_distance(position, other.position)
			if d >= radius:
				continue
			var away := position - other.position
			if away.length() < 0.01:
				# 완전히 같은 자리면 번호로 방향을 정해 둘이 서로 반대로 비킨다.
				away = Vector2.RIGHT if get_instance_id() > other.get_instance_id() else Vector2.LEFT
			push += away.normalized() * (1.0 - d / radius)
	return push.limit_length(GameConfig.PERSONAL_SPACE_PUSH)


# ─── 전투 ────────────────────────────────────────

func in_reach(target: Node2D, reach: float) -> bool:
	return Iso.ground_distance(position, target.position) <= reach


func face(point: Vector2) -> void:
	var d := point - position
	if d.length() > 0.5:
		facing = d.normalized()


## 보스 장판 자동 회피: 장판이 GameConfig.BOSS_AUTO_DODGE_PROGRESS만큼 차오른 뒤 가장 가까운 안전한 곳으로 걸어 나가고,
## 깔린 장판이 다 터질 때까지 그 자리에 머문다(빠져나오자마자 대상에게 걸어가다 다시 들어가지 않게).
## 피하는 중이면 true(그동안 다른 일은 하지 않는다). 수동으로 움직이는 주인공은 이걸 쓰지 않는다(직접 피하면 더 빨리 피한다).
func _auto_dodge() -> bool:
	if field == null:
		return false
	var safe := field.escape_point(position, GameConfig.BOSS_AUTO_DODGE_PROGRESS)
	if safe != Vector2.INF:
		_dodge_to = safe
	elif not field.has_danger():
		_dodge_to = Vector2.INF
	if _dodge_to == Vector2.INF:
		return false
	walk_to(_dodge_to, 4.0)
	return true


## 그 무리(Team)에서 살아 있는 것 중 가장 가까운 것. 없으면 null.
func nearest_alive(of_team: Team) -> Unit:
	var best: Unit = null
	var best_distance := INF
	for node in get_tree().get_nodes_in_group(group_name(of_team)):
		var other := node as Unit
		if other == self or not other.is_alive():
			continue
		var d := Iso.ground_distance(position, other.position)
		if d < best_distance:
			best = other
			best_distance = d
	return best


## 공격 대기가 끝났으면 공격한다. 사거리가 길면 투사체, 짧으면 몸으로 부딪친다. 강화(공격 · 공격 속도)를 받는다.
func try_attack(target: Unit) -> bool:
	if _cooldown > 0.0 or not target.is_alive():
		return false
	_cooldown = stats.attack_interval / (1.0 + boost("speed"))
	face(target.position)
	if stats.attack_range > GameConfig.MELEE_RANGE_MAX:
		field.shoot(self, target, attack_power())
	else:
		_lunge_left = LUNGE_SECONDS
		target.take_damage(attack_power(), self)
	return true


## 이번 타격이 치명타인가(확률 chance). 씨앗을 고정한 굴림이라 측정(tools/measure_hunt.gd)이 늘 같은 결과를 낸다.
static func roll_crit(chance: float) -> bool:
	if crit_override >= 0:
		return crit_override == 1
	return Combat.is_crit(chance, _crit_rng.randf())


static func _seeded_rng() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = GameConfig.FIELD_SEED + 3
	return rng


## 몸으로 부딪치는 연출(근접 공격 · 스킬).
func lunge() -> void:
	_lunge_left = LUNGE_SECONDS


## 지금 공격력(강화 포함). 기본 공격의 바탕.
func attack_power() -> float:
	return stats.attack * (1.0 + boost("attack"))


## 스킬 피해(heal이면 회복) 양: 계수(능력치 → 배율)마다 능력치 × 계수를 더한 값(UnitStats.skill_amount). 피해는 공격 강화를 받는다.
func skill_amount(coefs: Dictionary, heal := false) -> float:
	var amount := stats.skill_amount(coefs, heal)
	return amount if heal else amount * (1.0 + boost("attack"))


## 강화 · 약화를 건다(종류는 BOOST_KINDS). 이미 걸려 있으면 더 큰 양 · 더 긴 시간으로.
func add_boost(kind: String, amount: float, seconds: float) -> void:
	if not is_alive() or amount <= 0.0 or seconds <= 0.0:
		return
	var now: Array = _boosts.get(kind, [0.0, 0.0])
	_boosts[kind] = [maxf(float(now[0]), amount), maxf(float(now[1]), seconds)]


## 지금 걸린 강화 · 약화의 양(없으면 0).
func boost(kind: String) -> float:
	return float(_boosts[kind][0]) if _boosts.has(kind) else 0.0


## 받는 피해 배율: 늘 받는 배율 × (1 − 막기 강화) × (1 + 약화).
func damage_taken_factor() -> float:
	return damage_taken_scale * (1.0 - minf(boost("guard"), JobRules.GUARD_CAP)) * (1.0 + boost("vulnerable"))


## 살아 있는 야생 중 center에서 radius 안. fighting_only면 파티와 싸우는 중인 것만.
func wilds_within(center: Vector2, radius: float, fighting_only := false) -> Array[Hench]:
	var result: Array[Hench] = []
	for node in get_tree().get_nodes_in_group(Unit.group_name(Team.WILD)):
		var wild := node as Hench
		if wild.is_alive() and (wild.is_fighting() or not fighting_only) and Iso.ground_distance(center, wild.position) <= radius:
			result.append(wild)
	return result


## 살아 있는 내 편(주인공 · 파티 헨치) 중 center에서 radius 안.
func allies_within(center: Vector2, radius: float) -> Array[Unit]:
	var result: Array[Unit] = []
	for node in get_tree().get_nodes_in_group(Unit.group_name(Team.PARTY)):
		var ally := node as Unit
		if ally.is_alive() and Iso.ground_distance(center, ally.position) <= radius:
			result.append(ally)
	return result


## 회복 대기가 끝났으면 회복한다. 기본 공격과 대기 시간을 따로 쓰므로 같은 때에 공격도 할 수 있다.
func try_heal(target: Unit) -> bool:
	if _heal_cooldown > 0.0 or not target.is_alive():
		return false
	_heal_cooldown = stats.heal_interval
	face(target.position)
	target.receive_heal(stats.heal)
	return true


## from은 이미 사라졌으면 null일 수 있다. 기습이면 피해가 세지고 숫자가 "기습!"으로 뜬다.
## 보호막이 있으면 보호막이 먼저 받는다(다 막으면 숫자 대신 "막음").
## 피해를 받는다. from = 때린 쪽(치명타 · 기습 · 종족 상성을 본다).
## ratio = true면 체력 비율 피해(섬의 왕 장판)라 치명타 · 상성을 보지 않는다.
func take_damage(amount: float, from: Unit, ratio := false) -> void:
	if not is_alive():
		return
	var ambush := is_instance_valid(from) and _is_ambushed_by(from)
	var bonus := from.ambush_bonus if ambush else 0.0
	var crit := not ratio and is_instance_valid(from) and roll_crit(from.stats.crit_chance)
	var hit := Combat.crit_hit(Combat.hit_damage(amount, ambush, bonus), crit, from.stats.crit_damage if crit else 1.0)
	if not ratio and is_instance_valid(from):
		hit *= Affinity.damage_scale(from.tribe(), tribe())
	var after := Combat.absorb(shield, hit * damage_taken_factor())
	var blocked := shield - after.y
	amount = after.x
	shield = after.y
	hp = maxf(hp - amount, 0.0)
	_flash_left = FLASH_SECONDS
	if amount <= 0.0 and blocked > 0.0:
		field.show_number(_number_point(), UiText.SHIELD_BLOCK, Palette.SHIELD_BAR)
	elif ambush:
		field.show_number(_number_point(), (UiText.AMBUSH_CRIT_NUMBER if crit else UiText.AMBUSH_NUMBER) % roundi(amount), Palette.NUMBER_AMBUSH)
	elif crit:
		field.show_number(_number_point(), UiText.CRIT_NUMBER % roundi(amount), Palette.NUMBER_CRIT)
	else:
		var color := Palette.NUMBER_DEALT if team == Team.WILD else Palette.NUMBER_TAKEN
		field.show_number(_number_point(), str(roundi(amount)), color)
	_on_damaged(amount, from)
	if hp <= 0.0:
		stop()
		_on_died()
		died.emit(self)


func receive_heal(amount: float) -> void:
	if not is_alive():
		return
	var before := hp
	hp = minf(hp + amount, stats.max_hp)
	if hp > before:
		field.show_number(_number_point(), "+%d" % roundi(hp - before), Palette.NUMBER_HEAL)


## 기절(스킬): seconds초 동안 아무것도 못 한다. 이미 기절 중이면 더 긴 쪽으로.
func stun(seconds: float) -> void:
	if not is_alive():
		return
	_stun_left = maxf(_stun_left, seconds)
	stop()


func is_stunned() -> bool:
	return _stun_left > 0.0


## 기절을 푼다(직업 스킬: 정화).
func clear_stun() -> void:
	_stun_left = 0.0


## 보호막(스킬)을 씌운다. 겹치지 않고 더 큰 쪽이 남으며, 남는 시간은 새로 센다.
func add_shield(amount: float, seconds: float) -> void:
	shield = maxf(shield, amount)
	_shield_left = seconds


## 체력을 채워 그 자리에서 다시 일어난다.
func revive_at(point: Vector2) -> void:
	hp = stats.max_hp
	_stun_left = 0.0
	_boosts.clear()
	_dodge_to = Vector2.INF
	modulate.a = 1.0
	place_at(point)


# ─── 그림·이름표 (하위 클래스가 덮어써서 고친다) ───────────

## 몸 한가운데(투사체가 날아가는 곳). 원점(발밑)에서 위로.
func body_center() -> Vector2:
	return Vector2(0, -20)


## 이름표·체력 바를 그릴 높이(발밑에서 위로 px).
func overlay_height() -> float:
	return 40.0


func name_color() -> Color:
	return Palette.NAME_PASSIVE


## 화면 위 대상 창에 보일 제목.
func title() -> String:
	return display_name


## 종족(상성을 본다). 주인공처럼 종족이 없으면 ""(중립).
func tribe() -> String:
	return ""


## 지금 머리 위에 띄울 표시.
func mark() -> Mark:
	return Mark.NONE


## 감지 게이지(0~1). Mark.DETECTING일 때 전구가 이만큼 차오른다.
func detect_ratio() -> float:
	return 0.0


## 체력 바 눈금(비율들). 섬의 왕만 패턴 구간 경계를 돌려준다.
func hp_bar_marks() -> Array[float]:
	return []


func shows_hp_bar() -> bool:
	return hp < stats.max_hp or targeted or shield > 0.0


func hp_bar_color() -> Color:
	return Palette.HP_BAR_PARTY if team == Team.PARTY else Palette.HP_BAR_WILD


## 몸을 그릴 때 더할 위치(공격할 때 바라보는 쪽으로 살짝 튀어나간다).
func _body_offset() -> Vector2:
	return facing * LUNGE_DISTANCE * (_lunge_left / LUNGE_SECONDS)


func _is_flashing() -> bool:
	return _flash_left > 0.0


func _number_point() -> Vector2:
	return position + Vector2(0, -overlay_height() - 8)

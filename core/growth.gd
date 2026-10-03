class_name Growth
extends RefCounted
## 성장 계산(순수 함수, 기획서 8장 "레벨: MVP 최고 60, 약 1개월 — 첫날 15 · 1주 30 · 2주 40 · 3주 50 · 4주 60").
## 레벨 곡선은 [레벨, 그 레벨에 닿는 날]로 적고(GameConfig.LEVEL_CURVE), 하루 처치 수(GameConfig.MEASURED_DAILY_KILLS)를 곱해
## "그 레벨까지 쌓인 처치 수"로 바꾼다. 사이 레벨은 단조 3차 보간(Fritsch–Carlson)으로 부드럽게 잇는다(레벨이 오를수록 늘 더 걸린다).
## 다음 레벨까지 경험치 = 그 레벨 동안 잡을 처치 수 × 그 레벨 몹 한 마리 경험치. 보간이 만든 작은 굴곡 때문에 처치 수가
## 앞 레벨보다 줄어들면 앞 레벨 값을 쓴다(다음 레벨이 늘 같거나 더 오래 걸리게).
## 처치 보상(경험치 · 골드)은 몹 레벨에 따라 오르고, 레벨이 오르면 체력 · 공격 · 회복이 오른다(주인공 · 야생 · 코어 없는 헨치).
## 헨치(코어)도 경험치로 오른다(사용자 결정 2026-10-03): 파티에 있으면 처치 경험치를 주인공과 똑같이 받고, 파티 밖 헨치는
## 사냥에서 떨어지는 경험치 조각을 먹인다. 상한은 주인공 레벨(기획서 4장 확정) — 상한에서는 다음 레벨 직전까지만 쌓인다.
## 수치는 모두 GameConfig(곡선만 확정, 나머지는 임시).


## 그 레벨에 닿는 날(0 = 처음). 곡선 밖이면 양 끝 값.
static func days_to_reach(level: float) -> float:
	var points: Array = GameConfig.LEVEL_CURVE
	var n := points.size()
	if level <= float(points[0][0]):
		return float(points[0][1])
	if level >= float(points[n - 1][0]):
		return float(points[n - 1][1])
	var tangents := _tangents(points)
	for k in n - 1:
		var x0 := float(points[k][0])
		var x1 := float(points[k + 1][0])
		if level <= x1:
			var h := x1 - x0
			var t := (level - x0) / h
			var y0 := float(points[k][1])
			var y1 := float(points[k + 1][1])
			var t2 := t * t
			var t3 := t2 * t
			return (2.0 * t3 - 3.0 * t2 + 1.0) * y0 + (t3 - 2.0 * t2 + t) * h * tangents[k] + (-2.0 * t3 + 3.0 * t2) * y1 + (t3 - t2) * h * tangents[k + 1]
	return float(points[n - 1][1])


## 단조 3차 보간의 점마다 기울기(Fritsch–Carlson: 넘치지 않게 줄여 늘 오르기만 하게).
static func _tangents(points: Array) -> PackedFloat64Array:
	var n := points.size()
	var secants := PackedFloat64Array()
	for k in n - 1:
		secants.append((float(points[k + 1][1]) - float(points[k][1])) / (float(points[k + 1][0]) - float(points[k][0])))
	var m := PackedFloat64Array()
	m.resize(n)
	m[0] = secants[0]
	m[n - 1] = secants[n - 2]
	for k in range(1, n - 1):
		m[k] = 0.0 if secants[k - 1] * secants[k] <= 0.0 else (secants[k - 1] + secants[k]) * 0.5
	for k in n - 1:
		if secants[k] == 0.0:
			m[k] = 0.0
			m[k + 1] = 0.0
			continue
		var a := m[k] / secants[k]
		var b := m[k + 1] / secants[k]
		var length := a * a + b * b
		if length > 9.0:
			var scale := 3.0 / sqrt(length)
			m[k] = scale * a * secants[k]
			m[k + 1] = scale * b * secants[k]
	return m


## 그 레벨까지 쌓인 처치 수(하루 처치 수 기준).
static func kills_to_reach(level: float) -> float:
	return days_to_reach(level) * GameConfig.MEASURED_DAILY_KILLS


## 그 레벨 몹 한 마리를 잡으면 얻는 경험치 · 골드.
static func exp_per_kill(mob_level: int) -> int:
	return GameConfig.EXP_PER_KILL_BASE + GameConfig.EXP_PER_KILL_PER_LEVEL * maxi(mob_level - 1, 0)


static func gold_per_kill(mob_level: int) -> int:
	return GameConfig.GOLD_PER_KILL_BASE + GameConfig.GOLD_PER_KILL_PER_LEVEL * maxi(mob_level - 1, 0)


## 그 레벨에서 다음 레벨까지 필요한 경험치(최고 레벨이면 0) = 그 레벨 동안 잡을 처치 수 × 그 레벨 몹 경험치.
static func exp_to_next(level: int) -> int:
	if level >= GameConfig.MAX_LEVEL:
		return 0
	return maxi(roundi(kills_for_level(level) * exp_per_kill(level)), 1)


## 그 레벨에서 다음 레벨까지 잡을 처치 수(앞 레벨보다 줄지 않게).
static func kills_for_level(level: int) -> float:
	var most := 0.0
	for lv in range(1, level + 1):
		most = maxf(most, kills_to_reach(lv + 1) - kills_to_reach(lv))
	return most


## 경험치를 더한 결과 Vector2i(레벨, 그 레벨에서 모은 경험치). 여러 번 오를 수 있고, 최고 레벨이면 경험치는 0.
static func add_exp(level: int, exp_points: int, gained: int) -> Vector2i:
	var lv := clampi(level, 1, GameConfig.MAX_LEVEL)
	var points := exp_points + maxi(gained, 0)
	while lv < GameConfig.MAX_LEVEL and points >= exp_to_next(lv):
		points -= exp_to_next(lv)
		lv += 1
	if lv >= GameConfig.MAX_LEVEL:
		points = 0
	return Vector2i(lv, points)


## 레벨에 따른 능력치 배율(체력 · 공격 · 회복): 1 + 성장 × (레벨 - 1). 주인공 · 야생 · 코어 없는 헨치.
static func stat_scale(level: int) -> float:
	return 1.0 + GameConfig.LEVEL_STAT_GROWTH * maxi(level - 1, 0)


## 상한(cap, 주인공 레벨)까지만 오르는 경험치 더하기(헨치). 상한에서는 다음 레벨 직전(필요 경험치 - 1)까지만 쌓인다.
static func add_exp_capped(level: int, exp_points: int, gained: int, cap: int) -> Vector2i:
	var top := clampi(cap, 1, GameConfig.MAX_LEVEL)
	var lv := clampi(level, 1, GameConfig.MAX_LEVEL)
	var points := exp_points + maxi(gained, 0)
	while lv < top and points >= exp_to_next(lv):
		points -= exp_to_next(lv)
		lv += 1
	if lv >= GameConfig.MAX_LEVEL:
		points = 0
	elif lv >= top:
		points = mini(points, exp_to_next(lv) - 1)
	return Vector2i(lv, points)


## 경험치 조각 하나가 그 레벨 헨치에게 주는 경험치 = 그 레벨 몹 GameConfig.EXP_SHARD_KILLS마리만큼.
static func shard_exp(level: int) -> int:
	return GameConfig.EXP_SHARD_KILLS * exp_per_kill(level)


## 그 헨치(레벨 · 모은 경험치)가 다음 레벨까지 먹어야 할 경험치 조각 수.
static func shards_to_next(level: int, exp_points: int) -> int:
	var need := exp_to_next(level) - exp_points
	if need <= 0:
		return 0
	return ceili(float(need) / shard_exp(level))

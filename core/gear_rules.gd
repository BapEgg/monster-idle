class_name GearRules
extends RefCounted
## 장비 규칙(순수 계산, 기획서 3장 장비 확정 + 수치는 임시 GameConfig.GEAR_*):
## 칸 7개 · 주 능력치 값(레벨 · 등급 · 품질) · 옵션 굴림 · 낄 수 있나 · 정렬 · 합계 · 비교 · 글자.

## 장비 칸(인형 차례). 장신구는 두 칸.
const SLOTS := ["weapon", "helmet", "armor", "gloves", "boots", "accessory_1", "accessory_2"]
## 퍼센트로 붙는 옵션(나머지는 능력치 정수)
const PERCENT_STATS := ["crit_chance", "crit_damage", "party_hp"]
## 장신구에만 붙는 옵션(헨치 간접 강화, 기획서 3장 "옵션으로 헨치 간접 강화")
const ACCESSORY_ONLY := ["party_hp"]

enum Problem { OK, WRONG_JOB, LEVEL }
## 아이템 칸 정렬(UiText.GEAR_SORTS 차례)
enum Sort { GRADE, LEVEL, KIND, NEWEST }


## 칸 → 부위 종류(accessory_1 · accessory_2 → accessory).
static func slot_kind(slot: String) -> String:
	return "accessory" if slot.begins_with("accessory") else slot


## 그 부위가 들어갈 수 있는 칸들.
static func slots_for(kind: String) -> PackedStringArray:
	var list := PackedStringArray()
	for slot: String in SLOTS:
		if slot_kind(slot) == kind:
			list.append(slot)
	return list


static func is_percent(stat: String) -> bool:
	return stat in PERCENT_STATS


## 주 능력치 값 = 부위 기본값 × 레벨 배율 × 등급 배율 × 품질 배율(최소 1).
static func main_value(kind: String, level: int, grade: int, quality: int) -> int:
	var base := float(GameConfig.GEAR_MAIN_BASE.get(kind, 5.0))
	return maxi(roundi(base * Growth.stat_scale(level) * float(GameConfig.GEAR_GRADE_SCALE[grade]) * float(GameConfig.GEAR_QUALITY_SCALE[quality])), 1)


## 옵션 값: 능력치 = 기본값 × 레벨 배율 × (반 ~ 전부, roll 0~1), 퍼센트 = [최소, 최대] 사이(0.5% 단위).
static func option_value(stat: String, level: int, roll_value: float) -> Variant:
	if is_percent(stat):
		var span: Array = GameConfig.GEAR_OPTION_PERCENT[stat]
		return snappedf(lerpf(float(span[0]), float(span[1]), roll_value), 0.005)
	return maxi(roundi(GameConfig.GEAR_OPTION_STAT_BASE * Growth.stat_scale(level) * lerpf(0.5, 1.0, roll_value)), 1)


## 그 등급에 붙는 옵션 수.
static func option_count(grade: int) -> int:
	return int(GameConfig.GEAR_OPTION_COUNT[grade])


## 장비 하나를 만든다(같은 rng 상태면 늘 같은 장비): 이름 · 주 능력치 · 옵션(주 능력치와 겹치지 않게, 서로 다르게).
static func roll(rng: RandomNumberGenerator, kind: String, job_id: String, level: int, grade: int, quality: int) -> GearItem:
	var item := GearItem.new()
	item.kind = kind
	item.job_id = job_id if kind == "weapon" else ""
	item.level = maxi(level, 1)
	item.grade = clampi(grade, 0, GameConfig.GEAR_GRADE_SCALE.size() - 1)
	item.quality = clampi(quality, 0, GameConfig.GEAR_QUALITY_SCALE.size() - 1)
	var names := GearDb.names(kind, job_id)
	item.base_name = names[rng.randi_range(0, names.size() - 1)]
	item.main_stat = GearDb.main_stat(kind, job_id)
	item.main_value = main_value(kind, item.level, item.grade, item.quality)
	var pool: Array = []
	for stat: String in GameConfig.GEAR_OPTIONS:
		if stat != item.main_stat and (kind == "accessory" or not stat in ACCESSORY_ONLY):
			pool.append(stat)
	for i in mini(option_count(item.grade), pool.size()):
		var stat: String = pool.pop_at(rng.randi_range(0, pool.size() - 1))
		item.options.append({"stat": stat, "value": option_value(stat, item.level, rng.randf())})
	return item


## 개발용 무작위 장비: 부위는 고르게, 등급 · 품질은 비중대로, 레벨은 주인공 레벨 근처(GameConfig.GEAR_DEV_LEVEL_SPREAD).
static func roll_random(rng: RandomNumberGenerator, job_id: String, player_level: int) -> GearItem:
	var kinds := GearDb.kinds()
	var kind := kinds[rng.randi_range(0, kinds.size() - 1)]
	var spread: Vector2i = GameConfig.GEAR_DEV_LEVEL_SPREAD
	var level := clampi(player_level + rng.randi_range(spread.x, spread.y), 1, GameConfig.MAX_LEVEL)
	return roll(rng, kind, job_id, level, pick_weighted(GameConfig.GEAR_GRADE_WEIGHTS, rng.randf()), pick_weighted(GameConfig.GEAR_QUALITY_WEIGHTS, rng.randf()))


## 비중 목록에서 roll(0~1)이 떨어지는 번호.
static func pick_weighted(weights: Array, roll_value: float) -> int:
	var sum := 0.0
	for weight: float in weights:
		sum += weight
	var at := roll_value * sum
	for i in weights.size():
		at -= float(weights[i])
		if at < 0.0:
			return i
	return weights.size() - 1


## 낄 수 있나: 다른 직업의 무기 = WRONG_JOB, 장비 레벨이 주인공 레벨보다 높으면 LEVEL.
static func problem(item: GearItem, job_id: String, player_level: int) -> Problem:
	if item.kind == "weapon" and item.job_id != job_id:
		return Problem.WRONG_JOB
	if item.level > player_level:
		return Problem.LEVEL
	return Problem.OK


## 여러 장비가 올려 주는 것의 합 {능력치: 값}.
static func total(items: Array[GearItem]) -> Dictionary:
	var sum := {}
	for item in items:
		var bonus := item.bonus()
		for stat: String in bonus:
			sum[stat] = sum.get(stat, 0) + bonus[stat]
	return sum


## a − b(바꾸면 달라지는 것). 0인 것은 뺀다. 차례 = 능력치 9종 → 치명 → 파티.
static func diff(after: Dictionary, before: Dictionary) -> Dictionary:
	var result := {}
	for stat in stat_order():
		var change: float = float(after.get(stat, 0)) - float(before.get(stat, 0))
		if is_zero_approx(change):
			continue
		if is_percent(stat):
			result[stat] = change
		else:
			result[stat] = roundi(change)
	return result


## 보여 주는 차례: 능력치 9종 → 치명 확률 · 치명 피해 → 파티 헨치 체력.
static func stat_order() -> PackedStringArray:
	var order := SuffixDb.ids()
	order.append_array(PERCENT_STATS)
	return order


## 장비의 대략 점수(아이템 칸의 "더 좋음" 화살표): 주 능력치 + 옵션(퍼센트는 1% = 1점).
static func score(item: GearItem) -> float:
	var points := float(item.main_value)
	for option in item.options:
		var stat := str(option["stat"])
		points += float(option["value"]) * (100.0 if is_percent(stat) else 1.0)
	return points


## 지금 낀 것보다 좋은가: 같은 부위 칸에 빈 칸이 있거나, 낀 것 중 가장 낮은 점수보다 높으면.
static func is_upgrade(item: GearItem, worn_same_kind: Array[GearItem], slot_count: int) -> bool:
	if worn_same_kind.size() < slot_count:
		return true
	var lowest := INF
	for worn in worn_same_kind:
		lowest = minf(lowest, score(worn))
	return score(item) > lowest


## 아이템 칸 차례. GRADE = 등급 → 품질 → 레벨, LEVEL = 레벨 → 등급, KIND = 부위 차례 → 등급 → 레벨, NEWEST = 얻은 차례(최근 먼저).
static func sorted(items: Array[GearItem], by: Sort) -> Array[GearItem]:
	var list: Array[GearItem] = items.duplicate()
	var kinds := GearDb.kinds()
	list.sort_custom(func(a: GearItem, b: GearItem) -> bool:
		var keys_a: Array = _sort_keys(a, by, kinds)
		var keys_b: Array = _sort_keys(b, by, kinds)
		for i in keys_a.size():
			if keys_a[i] != keys_b[i]:
				return keys_a[i] > keys_b[i]
		return false)
	return list


static func _sort_keys(item: GearItem, by: Sort, kinds: PackedStringArray) -> Array:
	match by:
		Sort.LEVEL:
			return [item.level, item.grade, item.quality, item.uid]
		Sort.KIND:
			return [-kinds.find(item.kind), item.grade, item.level, item.uid]
		Sort.NEWEST:
			return [item.uid]
	return [item.grade, item.quality, item.level, item.uid]


## 능력치 이름(9종 · 치명 확률 · 치명 피해 · 파티 헨치 체력).
static func stat_name(stat: String) -> String:
	if UiText.STAT_CRIT_NAMES.has(stat):
		return UiText.STAT_CRIT_NAMES[stat]
	if UiText.GEAR_EXTRA_NAMES.has(stat):
		return UiText.GEAR_EXTRA_NAMES[stat]
	return SuffixDb.stat_name(stat)


## 값 글자: 능력치 "+12", 퍼센트 "+3%"(0.5% 단위면 "+2.5%"). 음수면 "−".
static func value_text(stat: String, value: float) -> String:
	var mark := "+" if value >= 0.0 else "−"
	if is_percent(stat):
		return mark + ("%.1f" % absf(value * 100.0)).trim_suffix(".0") + "%"
	return mark + str(absi(roundi(value)))

class_name CoreStats
extends RefCounted
## 코어(헨치)의 능력치 9종과 HP·MP(순수 함수). 능력치 9종은 접미사 9종과 짝이다(data/suffixes.json의 stat).
## 계산: 역할 기본값 × (1 + 성장 × (레벨 - 1)) × 등급 보정 × 나이 보정 × 접미사 보정
##   × 주 코어 성별 보정(믹스로 태어났을 때) × 변이 보정(변이 코어일 때).
## 수치는 모두 임시(GameConfig). 파티에 넣으면 이 값으로 싸운다(UnitStats.from_core).


## { 능력치 id: 값, "hp": HP, "mp": MP }
static func compute(item: CoreItem) -> Dictionary:
	var species := item.species()
	var base: Dictionary = GameConfig.CORE_BASE_STATS.get(species.role, GameConfig.CORE_BASE_STATS["tank"])
	var growth := 1.0 + GameConfig.CORE_STAT_GROWTH * (item.level - 1)
	var grade: float = GameConfig.CORE_GRADE_BONUS.get(species.grade, 1.0)
	var shift: float = GameConfig.AGE_STAT_SHIFT[item.age]
	var suffix_bonus := GameConfig.SHINING_SUFFIX_BONUS if item.shining else GameConfig.SUFFIX_BONUS
	var gender_stats := main_gender_stats(item)
	var mutant_stats := variant_stats(item)
	var result := {}
	for stat: String in base:
		var value := float(base[stat]) * growth * grade
		if stat in GameConfig.AGE_BODY_STATS:
			value *= 1.0 + shift
		elif stat in GameConfig.AGE_SKILL_STATS:
			value *= 1.0 - shift
		if stat == item.suffix_id:
			value *= 1.0 + suffix_bonus
		if stat in gender_stats:
			value *= 1.0 + GameConfig.MIX_MAIN_GENDER_BONUS
		if stat in mutant_stats:
			value *= 1.0 + GameConfig.VARIANT_STAT_BONUS
		result[stat] = roundi(value)
	result["hp"] = int(result.get("tough", 0)) * GameConfig.HP_PER_TOUGH
	result["mp"] = int(result.get("abundant", 0)) * GameConfig.MP_PER_ABUNDANT
	return result


## 주 코어 성별 때문에 오른 능력치 id들. 야생에서 얻은 코어는 비어 있다.
static func main_gender_stats(item: CoreItem) -> Array:
	if item.main_parent_gender < 0:
		return []
	return GameConfig.MIX_MAIN_GENDER_STATS[item.main_parent_gender]


## 변이 코어라서 오른 능력치 id들(역할마다 다르다). 변이가 아니면 비어 있다.
static func variant_stats(item: CoreItem) -> Array:
	if not item.variant:
		return []
	return GameConfig.VARIANT_STATS.get(item.species().role, [])

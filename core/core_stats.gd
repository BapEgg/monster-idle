class_name CoreStats
extends RefCounted
## 코어(헨치)의 능력치 9종과 HP·MP(순수 함수). 능력치 9종은 접미사 9종과 짝이다(data/suffixes.json의 stat).
## 계산: 역할 기본값 × (1 + 성장 × (레벨 - 1)) × 등급 보정 × 나이 보정 × 접미사 보정. 수치는 모두 임시(GameConfig).
## 아직 필드 전투에는 쓰지 않는다(밸런스 단계에서 이어 붙인다).


## { 능력치 id: 값, "hp": HP, "mp": MP }
static func compute(item: CoreItem) -> Dictionary:
	var species := item.species()
	var base: Dictionary = GameConfig.CORE_BASE_STATS.get(species.role, GameConfig.CORE_BASE_STATS["tank"])
	var growth := 1.0 + GameConfig.CORE_STAT_GROWTH * (item.level - 1)
	var grade: float = GameConfig.CORE_GRADE_BONUS.get(species.grade, 1.0)
	var shift: float = GameConfig.AGE_STAT_SHIFT[item.age]
	var suffix_bonus := GameConfig.SHINING_SUFFIX_BONUS if item.shining else GameConfig.SUFFIX_BONUS
	var result := {}
	for stat: String in base:
		var value := float(base[stat]) * growth * grade
		if stat in GameConfig.AGE_BODY_STATS:
			value *= 1.0 + shift
		elif stat in GameConfig.AGE_SKILL_STATS:
			value *= 1.0 - shift
		if stat == item.suffix_id:
			value *= 1.0 + suffix_bonus
		result[stat] = roundi(value)
	result["hp"] = int(result.get("tough", 0)) * GameConfig.HP_PER_TOUGH
	result["mp"] = int(result.get("abundant", 0)) * GameConfig.MP_PER_ABUNDANT
	return result

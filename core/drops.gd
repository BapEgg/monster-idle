class_name Drops
extends RefCounted
## 야생 헨치의 나이·성별·변이·레벨과, 처치했을 때 떨어지는 코어(순수 함수: 난수 생성기를 받으므로 같은 씨앗이면 늘 같은 결과).
## 확률은 임시값(GameConfig). 실제 값은 하루 처치 수를 잰 뒤 기획서 8장 공식으로 정한다.


## 쓰러뜨린 헨치(wild = 종·나이·성별·변이·레벨이 담긴 본)에게서 코어가 떨어지면 그 코어, 아니면 null.
## 변이체는 반드시 떨어진다(기획서 4장). 접미사와 빛나는 코어는 여기서 정한다.
static func roll_core(rng: RandomNumberGenerator, wild: CoreItem) -> CoreItem:
	if not wild.variant and rng.randf() >= GameConfig.CORE_DROP_CHANCE:
		return null
	var item := wild.duplicate_item()
	var suffixes := SuffixDb.ids()
	item.suffix_id = suffixes[rng.randi() % suffixes.size()] if not suffixes.is_empty() else ""
	item.shining = rng.randf() < GameConfig.SHINING_CORE_CHANCE
	return item


## 야생 헨치의 나이(GameConfig.AGE_WEIGHTS 비율대로).
static func roll_age(rng: RandomNumberGenerator) -> CoreItem.Age:
	return weighted_index(GameConfig.AGE_WEIGHTS, rng.randf()) as CoreItem.Age


static func roll_gender(rng: RandomNumberGenerator) -> CoreItem.Gender:
	return CoreItem.Gender.FEMALE if rng.randf() < GameConfig.FEMALE_CHANCE else CoreItem.Gender.MALE


static func roll_variant(rng: RandomNumberGenerator) -> bool:
	return rng.randf() < GameConfig.VARIANT_CHANCE


## 야생 헨치의 레벨: 종의 레벨대 가운데(지역 평균 대신) + 나이 보정(기획서 4장: 어린 -2, 늙은 +2).
static func wild_level(species: HenchSpecies, age: CoreItem.Age) -> int:
	@warning_ignore("integer_division")
	var middle := (species.level_min + species.level_max) / 2
	return maxi(middle + int(GameConfig.AGE_LEVEL_OFFSETS[age]), 1)


## 비율 목록에서 roll(0~1)이 떨어지는 칸의 번호. 예) [0.25, 0.5, 0.25]에서 0.3 → 1.
static func weighted_index(weights: Array, roll: float) -> int:
	var total := 0.0
	for weight: float in weights:
		total += weight
	var at := roll * total
	for i in weights.size():
		at -= float(weights[i])
		if at < 0.0:
			return i
	return weights.size() - 1

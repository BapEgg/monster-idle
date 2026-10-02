class_name Drops
extends RefCounted
## 처치했을 때 떨어지는 것(순수 함수: 난수 생성기를 받으므로 같은 씨앗이면 늘 같은 결과).
## 확률은 임시값(GameConfig.CORE_DROP_CHANCE 등). 실제 값은 하루 처치 수를 잰 뒤 기획서 8장 공식으로 정한다.


## 코어가 떨어지면 그 코어, 아니면 null.
static func roll_core(rng: RandomNumberGenerator, species_id: String, age: CoreItem.Age) -> CoreItem:
	if rng.randf() >= GameConfig.CORE_DROP_CHANCE:
		return null
	var suffixes := SuffixDb.ids()
	var item := CoreItem.new()
	item.species_id = species_id
	item.age = age
	item.suffix_id = suffixes[rng.randi() % suffixes.size()] if not suffixes.is_empty() else ""
	item.shining = rng.randf() < GameConfig.SHINING_CORE_CHANCE
	return item


## 야생 헨치의 나이(GameConfig.AGE_WEIGHTS 비율대로).
static func roll_age(rng: RandomNumberGenerator) -> CoreItem.Age:
	return weighted_index(GameConfig.AGE_WEIGHTS, rng.randf()) as CoreItem.Age


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

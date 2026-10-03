class_name Wallet
extends RefCounted
## 재화 지갑: 골드(사냥 · 믹스 비용, 기획서 9장), 코어 조각(종마다 따로: 그 종 코어를 분해하면 쌓이고,
## GameConfig.CORE_SHARDS_PER_CORE개를 모으면 그 종 코어 하나 — 사용자 결정 2026-10-03, 모았을 때 쓰는 곳은 임시),
## 경험치 조각(사냥에서 떨어짐 → 파티 밖 헨치에게 먹여 키운다, 사용자 결정 2026-10-03).

signal changed

var gold := 0
## 종 id → 코어 조각 수(0이면 빠진다)
var core_shards := {}
var exp_shards := 0


func add_gold(amount: int) -> void:
	gold += amount
	changed.emit()


## 골드를 낸다. 모자라면 내지 않고 false.
func spend_gold(amount: int) -> bool:
	if amount > gold:
		return false
	gold -= amount
	changed.emit()
	return true


## 그 종의 코어 조각을 더한다.
func add_core_shards(species_id: String, amount: int) -> void:
	if amount <= 0:
		return
	core_shards[species_id] = core_shards_of(species_id) + amount
	changed.emit()


## 그 종의 코어 조각 수.
func core_shards_of(species_id: String) -> int:
	return int(core_shards.get(species_id, 0))


## 그 종의 코어 조각을 쓴다. 모자라면 쓰지 않고 false. 다 쓰면 목록에서 뺀다.
func spend_core_shards(species_id: String, amount: int) -> bool:
	var have := core_shards_of(species_id)
	if amount > have:
		return false
	if have - amount <= 0:
		core_shards.erase(species_id)
	else:
		core_shards[species_id] = have - amount
	changed.emit()
	return true


## 코어 조각 모두(종 상관없이).
func total_core_shards() -> int:
	var total := 0
	for count: int in core_shards.values():
		total += count
	return total


func add_exp_shards(amount: int) -> void:
	exp_shards += amount
	changed.emit()


## 경험치 조각을 쓴다. 모자라면 쓰지 않고 false.
func spend_exp_shards(amount: int) -> bool:
	if amount > exp_shards:
		return false
	exp_shards -= amount
	changed.emit()
	return true

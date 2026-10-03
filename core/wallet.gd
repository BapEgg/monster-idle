class_name Wallet
extends RefCounted
## 재화 지갑: 골드(사냥 · 믹스 비용, 기획서 9장), 코어 조각(코어 분해 → 레시피 단서),
## 경험치 조각(사냥에서 떨어짐 → 파티 밖 헨치에게 먹여 키운다, 사용자 결정 2026-10-03).

signal changed

var gold := 0
var shards := 0
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


func add_shards(amount: int) -> void:
	shards += amount
	changed.emit()


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

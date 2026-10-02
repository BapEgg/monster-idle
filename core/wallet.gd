class_name Wallet
extends RefCounted
## 재화 지갑: 골드(사냥 · 믹스 비용, 기획서 9장)와 코어 조각(코어 분해 → 레시피 단서).

signal changed

var gold := 0
var shards := 0


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

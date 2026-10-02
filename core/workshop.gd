class_name Workshop
extends RefCounted
## 코어 다루기: 믹스 · 분해 · 잠금. 가방과 지갑에 바로 반영하고, 화면은 가방·지갑의 changed 신호로 따라 바뀐다.
## 규칙(확률·비용·공식)은 Mix가 정하고, 여기서는 재료를 없애고 골드를 내는 일까지 한다.
## 사용자 결정(2026-10-02): 믹스는 성공 확률이 있고, 실패하면 두 재료 코어가 모두 사라진다.

var bag: Bag
var wallet: Wallet
var rng := RandomNumberGenerator.new()


func _init(of_bag: Bag, of_wallet: Wallet) -> void:
	bag = of_bag
	wallet = of_wallet
	rng.randomize()


## 지금 이 두 코어로 믹스할 수 있나(Mix.Problem.NONE이면 가능).
func mix_problem(main: CoreItem, secondary: CoreItem) -> Mix.Problem:
	var problem := Mix.problem(main, secondary, wallet.gold)
	if problem == Mix.Problem.NONE and not (bag.has(main) and bag.has(secondary)):
		return Mix.Problem.MISSING
	return problem


## 믹스한다. 골드를 내고 두 재료를 가방에서 없앤 뒤, 성공하면 새 코어를 가방에 넣고 돌려준다. 실패하면 null.
## 믹스할 수 없는 상태면 아무것도 바꾸지 않고 null.
func mix(main: CoreItem, secondary: CoreItem, keep_legacy: bool) -> CoreItem:
	if mix_problem(main, secondary) != Mix.Problem.NONE:
		return null
	wallet.spend_gold(Mix.gold_cost(Mix.result_id(main, secondary)))
	var born := Mix.roll(rng, main, secondary, keep_legacy)
	bag.remove(main)
	bag.remove(secondary)
	if born != null:
		bag.add(born)
	return born


## 분해할 수 있나(잠금·파티 코어는 안 됨).
func can_dismantle(item: CoreItem) -> bool:
	return bag.has(item) and not item.locked and not item.in_party()


## 분해한다. 얻은 코어 조각 수(못 하면 0).
func dismantle(item: CoreItem) -> int:
	if not can_dismantle(item):
		return 0
	var shards := Mix.dismantle_shards(item)
	bag.remove(item)
	wallet.add_shards(shards)
	return shards


func toggle_lock(item: CoreItem) -> void:
	item.locked = not item.locked
	bag.changed.emit()

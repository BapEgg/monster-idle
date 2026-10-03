class_name Workshop
extends RefCounted
## 코어 다루기: 믹스 · 분해 · 잠금 · 경험치(파티 처치 경험치 · 경험치 조각 먹이기, 상한 = 주인공 레벨, 기획서 4장). 가방과 지갑에 바로 반영하고, 화면은 가방·지갑의 changed 신호로 따라 바뀐다.
## 규칙(확률·비용·공식)은 Mix가 정하고, 여기서는 재료를 없애고 골드를 내는 일까지 한다.
## 믹스 숙련도(성공 확률 보너스)와 도감(처음 얻은 종 = NEW)도 여기서 함께 올린다.
## 사용자 결정(2026-10-02): 믹스는 성공 확률이 있고, 실패하면 두 재료 코어가 모두 사라진다.

## 믹스 · 분해 · 잠금 · 경험치 조각 먹이기를 실제로 했을 때(저장을 앞당기는 데 쓴다).
signal acted
## 코어 레벨이 올랐을 때(파티에 있으면 main이 능력치를 다시 정한다).
signal core_leveled(item: CoreItem)

## 경험치 조각을 먹일 수 없는 까닭
enum FeedProblem { NONE, AT_CAP, NO_SHARDS }

var bag: Bag
var wallet: Wallet
var mastery := MixMastery.new()
var codex := Codex.new()
var rng := RandomNumberGenerator.new()
## 주인공 레벨(코어 레벨업 상한)
var progress := PlayerProgress.new()
## 마지막 믹스 결과: 태어난 종이 도감에 처음 등록됐나 / 얻은 숙련 경험치 / 숙련도 단계가 올랐나(결과 카드에 보인다)
var last_mix_new := false
var last_mix_exp := 0
var last_mix_level_up := false


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
	var born := Mix.roll(rng, main, secondary, keep_legacy, mastery.level)
	bag.remove(main)
	bag.remove(secondary)
	last_mix_new = false
	if born != null:
		last_mix_new = codex.register(born.species_id)
		bag.add(born)
	last_mix_exp = mastery.exp_for(born != null)
	last_mix_level_up = mastery.gain(born != null)
	acted.emit()
	return born


## 그 코어가 다음 레벨까지 먹어야 할 경험치 조각 수(상한이면 0).
func shards_to_next(item: CoreItem) -> int:
	if item.level >= _cap():
		return 0
	return Growth.shards_to_next(item.level, item.exp_points)


## 경험치 조각을 먹일 수 없는 까닭(NONE이면 가능). 상한 = 주인공 레벨.
func feed_problem(item: CoreItem) -> FeedProblem:
	if item.level >= _cap():
		return FeedProblem.AT_CAP
	if wallet.exp_shards <= 0:
		return FeedProblem.NO_SHARDS
	return FeedProblem.NONE


## 경험치 조각을 먹인다: 다음 레벨까지 필요한 만큼(모자라면 가진 만큼). 쓴 조각 수를 돌려준다(못 하면 0).
func feed_shards(item: CoreItem) -> int:
	if not bag.has(item) or feed_problem(item) != FeedProblem.NONE:
		return 0
	var use := mini(shards_to_next(item), wallet.exp_shards)
	wallet.spend_exp_shards(use)
	_add_exp(item, use * Growth.shard_exp(item.level))
	acted.emit()
	return use


## 파티 헨치가 처치 경험치를 받는다(상한 = 주인공 레벨). 레벨이 올랐으면 true.
func gain_kill_exp(item: CoreItem, amount: int) -> bool:
	return _add_exp(item, amount)


func _add_exp(item: CoreItem, amount: int) -> bool:
	var before := item.level
	var result := Growth.add_exp_capped(item.level, item.exp_points, amount, _cap())
	item.level = result.x
	item.exp_points = result.y
	bag.changed.emit()
	if item.level > before:
		core_leveled.emit(item)
		return true
	return false


func _cap() -> int:
	return mini(progress.level, GameConfig.MAX_LEVEL)


## 태어난 코어의 패시브를 고른다(믹스창 성공 카드): legacy_owner = 유산으로 받을 종 id, "" = 자기 패시브.
func choose_passive(born: CoreItem, legacy_owner: String) -> void:
	if not bag.has(born) or born.passive_species_id == legacy_owner:
		return
	born.passive_species_id = legacy_owner
	bag.changed.emit()
	acted.emit()


## 지금 이 두 코어의 성공 확률 내역(Mix.success_parts, 숙련도 반영).
func mix_chance(main: CoreItem, secondary: CoreItem) -> Dictionary:
	return Mix.success_parts(Mix.result_id(main, secondary), mastery.level)


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
	acted.emit()
	return shards


func toggle_lock(item: CoreItem) -> void:
	item.locked = not item.locked
	bag.changed.emit()
	acted.emit()

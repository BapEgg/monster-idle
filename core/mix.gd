class_name Mix
extends RefCounted
## 믹스 계산(순수 함수). 암수 한 쌍이 필요하다(기획서 4장).
## 사용자 결정(2026-10-03): 태어날 종은 어느 쪽이 주 코어냐로 정해진다(공식 [A, B] = 주 A · 보조 B, 반대는 다른 공식).
## 성별은 종을 바꾸지 않고, 주 코어가 암컷이냐 수컷이냐에 따라 태어난 코어의 능력치 경향이 달라진다.
## 주 코어의 패시브를 "유산"으로 받아 자기 패시브 대신 쓸 수 있다(1칸).
## 사용자 결정(2026-10-02): 성공 확률이 있고, 실패하면 두 재료 코어가 모두 사라진다.
## 공식에 없는 조합은 "?"(비밀)로 보이고, 믹스하면 실패한다.

## 결과 미리보기(기획서 4장 초안): 공개 = 이름, 힌트 = 실루엣, 비밀 = ?
enum Reveal { OPEN, HINT, SECRET }
## 믹스할 수 없는 까닭
enum Problem { NONE, MISSING, SAME_CORE, SAME_GENDER, LOCKED, IN_PARTY, VARIANT, NO_GOLD }


## 주 코어 + 보조 코어로 태어날 종 id. 공식이 없으면 "". (암수가 맞는지는 problem()이 본다.)
static func result_id(main: CoreItem, secondary: CoreItem) -> String:
	return HenchDb.recipe_result(main.species_id, secondary.species_id)


## 그 공식이 기획서에 없는 초안(임시)인가.
static func is_draft(main: CoreItem, secondary: CoreItem) -> bool:
	return HenchDb.is_draft_recipe(main.species_id, secondary.species_id)


static func reveal_of(result: String) -> Reveal:
	if result == "":
		return Reveal.SECRET
	match str(GameConfig.MIX_REVEAL_BY_GRADE.get(HenchDb.get_species(result).grade, "secret")):
		"open":
			return Reveal.OPEN
		"hint":
			return Reveal.HINT
	return Reveal.SECRET


## 성공 확률(0~1). 공식이 없는 조합은 0.
static func success_chance(result: String) -> float:
	if result == "":
		return 0.0
	return float(GameConfig.MIX_SUCCESS_BY_GRADE.get(HenchDb.get_species(result).grade, 0.0))


## 골드 비용. 공식이 없는 조합도 값을 받는다(비밀과 구별되지 않게).
static func gold_cost(result: String) -> int:
	if result == "":
		return GameConfig.MIX_GOLD_COST_UNKNOWN
	return int(GameConfig.MIX_GOLD_COST_BY_GRADE.get(HenchDb.get_species(result).grade, GameConfig.MIX_GOLD_COST_UNKNOWN))


## 믹스할 수 있나. 첫 번째로 걸리는 까닭을 돌려준다(없으면 NONE).
static func problem(main: CoreItem, secondary: CoreItem, gold: int) -> Problem:
	if main == null or secondary == null:
		return Problem.MISSING
	if main == secondary:
		return Problem.SAME_CORE
	if main.locked or secondary.locked:
		return Problem.LOCKED
	if main.in_party() or secondary.in_party():
		return Problem.IN_PARTY
	if main.variant or secondary.variant:
		return Problem.VARIANT  # 사용자 결정(2026-10-03): 변이(돌연변이)는 드롭 전용이고 믹스 재료로 못 쓴다
	if main.gender == secondary.gender:
		return Problem.SAME_GENDER
	if gold < gold_cost(result_id(main, secondary)):
		return Problem.NO_GOLD
	return Problem.NONE


## 믹스를 굴린다. 성공이면 새 코어, 실패면 null. 재료를 없애고 골드를 내는 것은 부르는 쪽(가방·지갑)이 한다.
## 새 코어: 태어난 종, 성별 무작위, 나이·레벨은 GameConfig.MIX_BORN_*, 접미사는 주 코어의 것,
## 주 코어의 성별을 기억해 능력치 경향을 받고, keep_legacy면 패시브를 주 코어의 패시브로(유산).
static func roll(rng: RandomNumberGenerator, main: CoreItem, secondary: CoreItem, keep_legacy: bool) -> CoreItem:
	var result := result_id(main, secondary)
	if result == "" or rng.randf() >= success_chance(result):
		return null
	var born := CoreItem.new()
	born.species_id = result
	born.gender = Drops.roll_gender(rng)
	born.age = GameConfig.MIX_BORN_AGE
	born.level = GameConfig.MIX_BORN_LEVEL
	born.suffix_id = main.suffix_id
	born.main_parent_gender = main.gender
	born.passive_species_id = main.passive_owner_id() if keep_legacy else ""
	return born


## 분해하면 얻는 코어 조각(기획서 9장: 코어 조각 → 레시피 단서).
static func dismantle_shards(item: CoreItem) -> int:
	var shards := GameConfig.DISMANTLE_SHARDS
	if item.shining:
		shards += GameConfig.DISMANTLE_SHARDS_SHINING_BONUS
	if item.variant:
		shards += GameConfig.DISMANTLE_SHARDS_VARIANT_BONUS
	return shards

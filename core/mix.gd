class_name Mix
extends RefCounted
## 믹스 계산(순수 함수). 기획서 4장: 암수 한 쌍이 필요하고, 어느 쪽이 암컷이냐에 따라 다른 종이 태어난다.
## 주 코어의 패시브를 "유산"으로 받아 자기 패시브 대신 쓸 수 있다(1칸).
## 사용자 결정(2026-10-02): 성공 확률이 있고, 실패하면 두 재료 코어가 모두 사라진다.
## 공식 [A, B]는 A = 암컷, B = 수컷으로 읽는다(임시). 반대 방향과 공식에 없는 조합은 "?"(비밀)로 보이고, 믹스하면 실패한다.

## 결과 미리보기(기획서 4장 초안): 공개 = 이름, 힌트 = 실루엣, 비밀 = ?
enum Reveal { OPEN, HINT, SECRET }
## 믹스할 수 없는 까닭
enum Problem { NONE, MISSING, SAME_CORE, SAME_GENDER, LOCKED, IN_PARTY, NO_GOLD }


## 두 코어에서 암컷을 고른다(둘 다 같은 성별이면 null).
static func female_of(a: CoreItem, b: CoreItem) -> CoreItem:
	if a.gender == b.gender:
		return null
	return a if a.gender == CoreItem.Gender.FEMALE else b


## 두 코어로 태어날 종 id. 공식이 없거나 같은 성별이면 "".
static func result_id(a: CoreItem, b: CoreItem) -> String:
	var female := female_of(a, b)
	if female == null:
		return ""
	var male := b if female == a else a
	return HenchDb.recipe_result(female.species_id, male.species_id)


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
	if main.gender == secondary.gender:
		return Problem.SAME_GENDER
	if gold < gold_cost(result_id(main, secondary)):
		return Problem.NO_GOLD
	return Problem.NONE


## 믹스를 굴린다. 성공이면 새 코어, 실패면 null. 재료를 없애고 골드를 내는 것은 부르는 쪽(가방·지갑)이 한다.
## 새 코어: 태어난 종, 성별 무작위, 나이·레벨은 GameConfig.MIX_BORN_*, 접미사는 주 코어의 것,
## keep_legacy면 패시브를 주 코어의 패시브로(유산).
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

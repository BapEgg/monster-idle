class_name Mix
extends RefCounted
## 믹스 계산(순수 함수). 기획서 4장 "믹스 세부 규칙"(사용자 정리 2026-10-03):
## - 재료: 암수 한 쌍. 주 코어가 종을 정한다(공식 [A, B] = 주 A · 보조 B, 주·보조를 바꾸면 다른 종).
## - 추가 스탯: 보조 코어 접미사의 능력치를 그 값의 15~20%만큼 물려받는다.
## - 성별은 종을 바꾸지 않는다(성장 성향은 CoreStats). 유산 패시브는 주 코어에서 받아 자기 패시브 대신 쓸 수 있다(1칸).
## - 성공 확률 = 기본(결과 등급) + 숙련 + 마크. 실패하면 재료 둘 다 사라진다.
## - 태어난 코어: 레벨 = 재료 중 높은 레벨의 절반(최소 = 출현 레벨), 접미사 = 주 코어 것 50% · 나머지 무작위, 어린 · 성별 50:50.
## - 공식이 없는 조합은 믹스할 수 없다("알려진 공식이 없어요").

## 결과 미리보기: 공개 = 이름, 힌트 = 실루엣 + 종족, 비밀 = ?
enum Reveal { OPEN, HINT, SECRET }
## 믹스할 수 없는 까닭
enum Problem { NONE, MISSING, SAME_CORE, SAME_GENDER, LOCKED, IN_PARTY, VARIANT, NO_RECIPE, NO_GOLD }


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


## 성공 확률 내역: { "base": 기본(결과 등급), "mastery": 숙련, "mark": 마크, "total": 합(상한까지) }. 공식이 없으면 모두 0.
static func success_parts(result: String, mastery_level := 1) -> Dictionary:
	if result == "":
		return {"base": 0.0, "mastery": 0.0, "mark": 0.0, "total": 0.0}
	var base := float(GameConfig.MIX_SUCCESS_BY_GRADE.get(HenchDb.get_species(result).grade, 0.0))
	var mastery := (mastery_level - 1) * GameConfig.MIX_MASTERY_BONUS_PER_LEVEL
	var mark := GameConfig.MIX_MARK_BONUS
	return {"base": base, "mastery": mastery, "mark": mark, "total": minf(base + mastery + mark, GameConfig.MIX_SUCCESS_CAP)}


## 성공 확률(0~1).
static func success_chance(result: String, mastery_level := 1) -> float:
	return success_parts(result, mastery_level)["total"]


## 골드 비용(결과 등급별). 공식이 없으면 0(믹스할 수 없다).
static func gold_cost(result: String) -> int:
	if result == "":
		return 0
	return int(GameConfig.MIX_GOLD_COST_BY_GRADE.get(HenchDb.get_species(result).grade, 0))


## 태어날 코어의 레벨: 재료 중 높은 레벨의 절반, 최소 = 그 종의 출현 레벨.
static func born_level(main: CoreItem, secondary: CoreItem, result: String) -> int:
	var half := floori(maxi(main.level, secondary.level) * GameConfig.MIX_BORN_LEVEL_RATIO)
	return maxi(half, maxi(HenchDb.get_species(result).level_min, 1))


## 물려받을 추가 스탯 고정치의 범위(보조 코어 접미사 능력치 × 15~20%). x = 최소, y = 최대(1 이상).
static func inherit_range(secondary: CoreItem) -> Vector2i:
	var value := float(CoreStats.compute(secondary).get(secondary.suffix_id, 0))
	return Vector2i(maxi(roundi(value * GameConfig.MIX_INHERIT_RATE.x), 1), maxi(roundi(value * GameConfig.MIX_INHERIT_RATE.y), 1))


## 이 재료를 쓰기 전에 한 번 더 물어야 하나(빛나는 코어 · 높은 레벨).
static func needs_confirm(item: CoreItem) -> bool:
	return item.shining or item.level >= GameConfig.MIX_CONFIRM_LEVEL


## 믹스할 수 있나. 첫 번째로 걸리는 까닭을 돌려준다(없으면 NONE).
static func problem(main: CoreItem, secondary: CoreItem, gold: int) -> Problem:
	if main == null or secondary == null:
		return Problem.MISSING
	var own := material_problem(secondary, main)
	if own != Problem.NONE:
		return own
	own = material_problem(main, secondary)
	if own != Problem.NONE:
		return own
	var result := result_id(main, secondary)
	if result == "":
		return Problem.NO_RECIPE
	if gold < gold_cost(result):
		return Problem.NO_GOLD
	return Problem.NONE


## 이 코어를 (other와 짝지어) 재료로 쓸 수 없는 까닭. other가 null이면 짝은 보지 않는다.
## 재료 목록에서 흐리게 보이며 까닭을 붙이는 데 쓴다.
static func material_problem(item: CoreItem, other: CoreItem) -> Problem:
	if other != null and item == other:
		return Problem.SAME_CORE
	if item.locked:
		return Problem.LOCKED
	if item.in_party():
		return Problem.IN_PARTY
	if item.variant:
		return Problem.VARIANT  # 사용자 결정(2026-10-03): 변이(돌연변이)는 드롭 전용이고 믹스 재료로 못 쓴다
	if other != null and item.gender == other.gender:
		return Problem.SAME_GENDER
	return Problem.NONE


## 가방에서 그 공식(주 main_id + 보조 sub_id)에 쓸 수 있는 한 쌍을 찾는다(레벨 높은 것부터). 없으면 [].
## 쓸 수 있는 = 잠금 · 파티 · 변이가 아니고 암수가 맞는 코어(레시피 창에서 눌러 바로 채운다).
static func find_pair(cores: Array[CoreItem], main_id: String, sub_id: String) -> Array[CoreItem]:
	var mains: Array[CoreItem] = []
	var subs: Array[CoreItem] = []
	for item in cores:
		if material_problem(item, null) != Problem.NONE:
			continue
		if item.species_id == main_id:
			mains.append(item)
		if item.species_id == sub_id:
			subs.append(item)
	var by_level := func(a: CoreItem, b: CoreItem) -> bool: return a.level > b.level
	mains.sort_custom(by_level)
	subs.sort_custom(by_level)
	for main in mains:
		for sub in subs:
			if sub != main and sub.gender != main.gender:
				return [main, sub]
	return []


## 믹스를 굴린다. 성공이면 새 코어, 실패면 null. 재료를 없애고 골드를 내는 것은 부르는 쪽(Workshop)이 한다.
## keep_legacy면 패시브를 주 코어의 패시브로(유산).
static func roll(rng: RandomNumberGenerator, main: CoreItem, secondary: CoreItem, keep_legacy: bool, mastery_level := 1) -> CoreItem:
	var result := result_id(main, secondary)
	if result == "" or rng.randf() >= success_chance(result, mastery_level):
		return null
	var born := CoreItem.new()
	born.species_id = result
	born.gender = Drops.roll_gender(rng)
	born.age = GameConfig.MIX_BORN_AGE
	born.level = born_level(main, secondary, result)
	if rng.randf() < GameConfig.MIX_SUFFIX_KEEP_CHANCE:
		born.suffix_id = main.suffix_id
	else:
		var ids := SuffixDb.ids()
		born.suffix_id = ids[rng.randi() % ids.size()]
	var span := inherit_range(secondary)
	born.inherit_stat = secondary.suffix_id
	born.inherit_value = rng.randi_range(span.x, span.y)
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

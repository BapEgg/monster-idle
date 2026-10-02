class_name HenchDb
extends RefCounted
## 헨치 도감 데이터(data/henches.json)를 읽어 id로 찾아 준다. 처음 찾을 때 한 번만 읽는다.
## 주의: 안드로이드로 내보낼 때 내보내기 설정의 "리소스가 아닌 파일" 필터에 *.json 을 넣어야 함께 들어간다.

const PATH := "res://data/henches.json"

static var _cache := {}
static var _recipe_index := {}  # "암컷 id|수컷 id" → 결과 id


## id로 종을 찾는다. 없으면 null.
static func get_species(id: String) -> HenchSpecies:
	return all().get(id)


## 모든 종 { id: HenchSpecies }.
static func all() -> Dictionary:
	if _cache.is_empty():
		_cache = parse(FileAccess.get_file_as_string(PATH))
	return _cache


## 믹스 공식으로 태어날 종 id(암컷 종, 수컷 종). 공식이 없으면 "".
static func recipe_result(female_id: String, male_id: String) -> String:
	if _recipe_index.is_empty():
		for species: HenchSpecies in all().values():
			for pair in species.recipes:
				_recipe_index[pair[0] + "|" + pair[1]] = species.id
	return _recipe_index.get(female_id + "|" + male_id, "")


## JSON 글자 → { id: HenchSpecies }. 잘못된 칸은 오류를 알리고 건너뛴다.
static func parse(text: String) -> Dictionary:
	var result := {}
	var root: Variant = JSON.parse_string(text)
	if not root is Dictionary or not root.get("henches") is Array:
		push_error("헨치 데이터를 읽지 못함: henches 배열이 없음")
		return result
	for row: Variant in root["henches"]:
		if not row is Dictionary:
			continue
		var species := HenchSpecies.from_dict(row)
		var problems := species.problems()
		if not problems.is_empty():
			push_error("헨치 데이터 오류: " + ", ".join(problems))
			continue
		result[species.id] = species
	return result

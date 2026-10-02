class_name HenchDb
extends RefCounted
## 헨치 도감 데이터(data/henches.json)를 읽어 id로 찾아 준다. 처음 찾을 때 한 번만 읽는다.
## 주의: 안드로이드로 내보낼 때 내보내기 설정의 "리소스가 아닌 파일" 필터에 *.json 을 넣어야 함께 들어간다.

const PATH := "res://data/henches.json"

static var _cache := {}


## id로 종을 찾는다. 없으면 null.
static func get_species(id: String) -> HenchSpecies:
	if _cache.is_empty():
		_cache = parse(FileAccess.get_file_as_string(PATH))
	return _cache.get(id)


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

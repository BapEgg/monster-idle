class_name HenchDb
extends RefCounted
## 헨치 도감 데이터(data/henches.json)를 읽어 id로 찾아 준다. 처음 찾을 때 한 번만 읽는다.
## 주의: 안드로이드로 내보낼 때 내보내기 설정의 "리소스가 아닌 파일" 필터에 *.json 을 넣어야 함께 들어간다.

const PATH := "res://data/henches.json"

static var _cache := {}
static var _recipe_index := {}  # "주 코어 id|보조 코어 id" → 결과 id
static var _draft_keys := {}  # 초안 공식의 열쇠
static var _icon_template := ""  # 고유 스킬 그림 경로 틀(henches.json의 skill_icon_path)
static var _skill_icons := {}


## id로 종을 찾는다. 없으면 null.
static func get_species(id: String) -> HenchSpecies:
	return all().get(id)


## 모든 종 { id: HenchSpecies }.
static func all() -> Dictionary:
	if _cache.is_empty():
		var text := FileAccess.get_file_as_string(PATH)
		_cache = parse(text)
		var root: Variant = JSON.parse_string(text)
		_icon_template = str(root.get("skill_icon_path", "")) if root is Dictionary else ""
	return _cache


## 그 종의 고유 스킬 그림 경로(henches.json의 skill_icon_path 틀, 종마다 하나). 틀이 없으면 "".
static func skill_icon_path(species_id: String) -> String:
	all()
	return _icon_template.format({"species": species_id}) if _icon_template != "" else ""


## 그 종의 고유 스킬 그림(메인 화면 스킬 칸 바탕). 지금은 tools/make_skill_icons.gd가 만든 임시 그림이고, 같은 이름으로 덮어쓰면 바뀐다. 없으면 null.
static func skill_icon(species_id: String) -> Texture2D:
	var path := skill_icon_path(species_id)
	if path == "":
		return null
	if not _skill_icons.has(path):
		_skill_icons[path] = load(path) as Texture2D if ResourceLoader.exists(path) else null
	return _skill_icons[path]


## 믹스 공식으로 태어날 종 id(주 코어 종, 보조 코어 종). 기획서 공식과 초안 공식을 함께 찾는다. 없으면 "".
static func recipe_result(main_id: String, sub_id: String) -> String:
	_build_recipe_index()
	return _recipe_index.get(main_id + "|" + sub_id, "")


## 모든 공식: [{ "main": 주 코어 종, "sub": 보조 코어 종, "result": 태어날 종, "draft": 초안인가 }] (믹스창 레시피 창).
static func recipes() -> Array[Dictionary]:
	_build_recipe_index()
	var list: Array[Dictionary] = []
	for key: String in _recipe_index:
		var pair := key.split("|")
		list.append({"main": pair[0], "sub": pair[1], "result": _recipe_index[key], "draft": _draft_keys.has(key)})
	return list


## 그 공식이 기획서에 없는 초안(임시)인가.
static func is_draft_recipe(main_id: String, sub_id: String) -> bool:
	_build_recipe_index()
	return _draft_keys.has(main_id + "|" + sub_id)


static func _build_recipe_index() -> void:
	if not _recipe_index.is_empty():
		return
	for species: HenchSpecies in all().values():
		for pair in species.recipes:
			_recipe_index[pair[0] + "|" + pair[1]] = species.id
		for pair in species.draft_recipes:
			_recipe_index[pair[0] + "|" + pair[1]] = species.id
			_draft_keys[pair[0] + "|" + pair[1]] = true


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

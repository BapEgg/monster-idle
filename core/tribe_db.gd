class_name TribeDb
extends RefCounted
## 종족 데이터(data/tribes.json): 이름·주제·색과 아이콘·초상화 이미지 경로.
## 그림을 바꾸려면 경로의 PNG를 같은 이름으로 덮어쓰거나 json의 경로를 바꾸면 된다(코드는 고칠 필요 없음).
## 주의: 안드로이드로 내보낼 때 내보내기 설정의 "리소스가 아닌 파일" 필터에 *.json 을 넣어야 함께 들어간다.

const PATH := "res://data/tribes.json"


## 종족 하나.
class Tribe:
	var id := ""
	var name := ""
	var theme := ""
	var color := Color.WHITE
	var icon_path := ""
	var portrait_path := ""


static var _cache := {}
static var _textures := {}


## id로 종족을 찾는다. 없으면 null.
static func get_tribe(id: String) -> Tribe:
	if _cache.is_empty():
		_cache = parse(FileAccess.get_file_as_string(PATH))
	return _cache.get(id)


## 종족 아이콘(가방 칸·떨어진 코어). 그림 파일이 없으면 null(부르는 쪽이 도형으로 대신 그린다).
static func icon(id: String) -> Texture2D:
	var tribe := get_tribe(id)
	return _texture(tribe.icon_path) if tribe != null else null


## 종족 초상화(코어 정보창·믹스창). 그림 파일이 없으면 null.
static func portrait(id: String) -> Texture2D:
	var tribe := get_tribe(id)
	return _texture(tribe.portrait_path) if tribe != null else null


static func _texture(path: String) -> Texture2D:
	if not _textures.has(path):
		_textures[path] = load(path) as Texture2D if path != "" and ResourceLoader.exists(path) else null
	return _textures[path]


## JSON 글자 → { id: Tribe }.
static func parse(text: String) -> Dictionary:
	var result := {}
	var root: Variant = JSON.parse_string(text)
	if not root is Dictionary or not root.get("tribes") is Array:
		push_error("종족 데이터를 읽지 못함: tribes 배열이 없음")
		return result
	for row: Variant in root["tribes"]:
		if not row is Dictionary:
			continue
		var tribe := Tribe.new()
		tribe.id = str(row.get("id", ""))
		tribe.name = str(row.get("name", tribe.id))
		tribe.theme = str(row.get("theme", ""))
		tribe.color = Color.from_string(str(row.get("color", "")), Color.WHITE)
		tribe.icon_path = str(row.get("icon", ""))
		tribe.portrait_path = str(row.get("portrait", ""))
		result[tribe.id] = tribe
	return result

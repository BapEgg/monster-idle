class_name SuffixDb
extends RefCounted
## 코어 접미사 데이터(data/suffixes.json)를 읽는다. 처음 찾을 때 한 번만 읽는다.
## 주의: 안드로이드로 내보낼 때 내보내기 설정의 "리소스가 아닌 파일" 필터에 *.json 을 넣어야 함께 들어간다.

const PATH := "res://data/suffixes.json"

static var _ids := PackedStringArray()
static var _names := {}
static var _stats := {}


## 접미사 id 전부(데이터 파일 순서).
static func ids() -> PackedStringArray:
	_load()
	return _ids.duplicate()  # 복사본(받은 쪽이 늘려도 이 목록은 그대로)


## 짝이 되는 능력치 이름(예: 강력 → 공격). 모르는 id면 id 그대로.
static func stat_name(id: String) -> String:
	_load()
	return _stats.get(id, id)


## 여러 능력치 이름을 한 줄로(예: "공격, 체력, 드랍·코어 확률").
static func stat_list(stat_ids: Array) -> String:
	var names := PackedStringArray()
	for id: String in stat_ids:
		names.append(stat_name(id))
	return UiText.LIST_SEPARATOR.join(names)


## 화면에 보일 이름(가칭). 모르는 id면 id 그대로.
static func display_name(id: String) -> String:
	_load()
	return _names.get(id, id)


static func _load() -> void:
	if not _ids.is_empty():
		return
	var root: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not root is Dictionary or not root.get("suffixes") is Array:
		push_error("접미사 데이터를 읽지 못함: suffixes 배열이 없음")
		return
	for row: Variant in root["suffixes"]:
		if row is Dictionary and str(row.get("id", "")) != "":
			_ids.append(str(row["id"]))
			_names[str(row["id"])] = str(row.get("name", row["id"]))
			_stats[str(row["id"])] = str(row.get("stat", row["id"]))

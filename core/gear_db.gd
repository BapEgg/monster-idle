class_name GearDb
extends RefCounted
## 장비 부위 데이터(data/gear.json)를 읽는다: 부위 종류 차례 · 주 능력치 · 이름. 처음 찾을 때 한 번만 읽는다.

const PATH := "res://data/gear.json"

static var _kinds := PackedStringArray()
static var _main := {}  # 부위 → 주 능력치
static var _names := {}  # 부위 → 이름들
static var _weapon_main := {}  # 직업 → 무기 주 능력치
static var _weapon_names := {}  # 직업 → 무기 이름들


## 부위 종류(weapon · helmet · armor · gloves · boots · accessory, 데이터 차례).
static func kinds() -> PackedStringArray:
	_load()
	return _kinds.duplicate()


## 그 부위의 주 능력치(무기는 직업마다). 모르면 "mighty".
static func main_stat(kind: String, job_id: String) -> String:
	_load()
	if kind == "weapon":
		return str(_weapon_main.get(job_id, "mighty"))
	return str(_main.get(kind, "mighty"))


## 그 부위의 이름들(무기는 직업마다). 없으면 부위 이름 하나.
static func names(kind: String, job_id: String) -> PackedStringArray:
	_load()
	var list: Variant = _weapon_names.get(job_id) if kind == "weapon" else _names.get(kind)
	if list is Array and not (list as Array).is_empty():
		return PackedStringArray(list)
	return PackedStringArray([UiText.GEAR_SLOT_NAMES.get(kind, kind)])


static func _load() -> void:
	if not _kinds.is_empty():
		return
	var root: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not root is Dictionary:
		push_error("장비 데이터를 읽지 못함")
		return
	for row: Variant in root.get("kinds", []):
		if not row is Dictionary:
			continue
		var id := str(row.get("id", ""))
		if id == "":
			continue
		_kinds.append(id)
		if row.has("main"):
			_main[id] = str(row["main"])
		if row.get("names") is Array:
			_names[id] = row["names"]
	_weapon_main = root.get("weapon_main", {})
	_weapon_names = root.get("weapon_names", {})

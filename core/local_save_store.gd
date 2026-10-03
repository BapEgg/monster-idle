class_name LocalSaveStore
extends SaveStore
## 기기 안 파일에 JSON으로 저장한다(GameConfig.SAVE_PATH).
## 쓰다가 꺼져도 망가지지 않게: 새 파일(.tmp)을 다 쓴 뒤 이전 파일을 .bak으로 돌리고 새 파일로 바꿔 끼운다.
## 저장 파일이 없거나 망가졌으면 .bak(바로 전 저장)을 읽는다.

const TEMP_SUFFIX := ".tmp"
const BACKUP_SUFFIX := ".bak"

var path: String


func _init(file_path: String) -> void:
	path = file_path


func load_data() -> Dictionary:
	last_error = ""
	for candidate: String in [path, path + BACKUP_SUFFIX]:
		if not FileAccess.file_exists(candidate):
			continue
		var json := JSON.new()  # JSON.parse_string은 망가진 글자에서 오류를 찍으므로 직접 읽어 last_error로 알린다
		if json.parse(FileAccess.get_file_as_string(candidate)) == OK and json.data is Dictionary:
			return json.data
		last_error = "저장 파일을 읽지 못함: %s (%s)" % [candidate, json.get_error_message()]
	return {}


func save_data(data: Dictionary) -> bool:
	last_error = ""
	var temp := path + TEMP_SUFFIX
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		last_error = "저장 파일을 열지 못함: %s (%s)" % [temp, error_string(FileAccess.get_open_error())]
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	if FileAccess.file_exists(path):
		_remove(path + BACKUP_SUFFIX)
		DirAccess.rename_absolute(path, path + BACKUP_SUFFIX)
	var result := DirAccess.rename_absolute(temp, path)
	if result != OK:
		last_error = "저장 파일을 바꿔 끼우지 못함: %s (%s)" % [path, error_string(result)]
		return false
	return true


func erase() -> void:
	for suffix: String in ["", TEMP_SUFFIX, BACKUP_SUFFIX]:
		_remove(path + suffix)


static func _remove(file_path: String) -> void:
	if FileAccess.file_exists(file_path):
		DirAccess.remove_absolute(file_path)

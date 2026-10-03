class_name Codex
extends RefCounted
## 도감(지금은 얻은 적 있는 종 목록만). 코어를 줍거나 믹스로 얻으면 등록된다.
## 믹스 결과의 "NEW · 도감 등록" 표시에 쓴다(기획서 4장 믹스 세부 규칙). 저장된다(GameSave).

var _seen := {}


## 등록한다. 처음 보는 종이면 true.
func register(species_id: String) -> bool:
	if species_id == "" or _seen.has(species_id):
		return false
	_seen[species_id] = true
	return true


func has(species_id: String) -> bool:
	return _seen.has(species_id)


func count() -> int:
	return _seen.size()


func ids() -> PackedStringArray:
	return PackedStringArray(_seen.keys())

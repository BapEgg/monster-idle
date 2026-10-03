class_name SaveStore
extends RefCounted
## 세이브 저장소(틀). 저장할 내용(Dictionary)을 어디에 두느냐만 맡는다. 내용은 GameSave가 만들고 읽는다.
## 지금은 기기 안 파일(LocalSaveStore)을 쓰고, 나중에 같은 함수를 가진 Firebase(Firestore) 저장소로 갈아 끼운다(코드 규칙 9).

## 마지막으로 불러오기·저장하다 생긴 문제(없으면 ""). 부르는 쪽이 보고 알린다.
var last_error := ""


## 저장된 내용. 저장된 것이 없거나 읽지 못하면 빈 Dictionary.
func load_data() -> Dictionary:
	return {}


## 저장한다. 성공하면 true.
func save_data(_data: Dictionary) -> bool:
	return false


## 저장된 것을 모두 지운다(처음부터 시작).
func erase() -> void:
	pass

class_name Bag
extends RefCounted
## 코어 가방. 지금은 칸 수 제한이 없다(사용자 결정 2026-10-02).
## 나중에 가방 확장(무료 몇 칸 · 이벤트 · 유료)을 붙일 때 여기에 칸 수를 둔다.

## 넣거나 뺄 때.
signal changed

var cores: Array[CoreItem] = []


func add(item: CoreItem) -> void:
	cores.append(item)
	changed.emit()


func remove(item: CoreItem) -> void:
	cores.erase(item)
	changed.emit()


func has(item: CoreItem) -> bool:
	return item in cores


func count() -> int:
	return cores.size()

class_name CoreItem
extends RefCounted
## 코어 하나(가방에 들어가는 것). 헨치의 본체(기획서 2장): 어느 종인지, 접미사, 빛나는 코어인지, 나이.
## 나이는 쓰러뜨린 야생 헨치의 나이를 그대로 받는다. 나이에 따른 외형(부품·크기)은 그림이 들어오면 붙인다.

## 나이(기획서 4장): 어린(몸↑ 스킬↓ 성장 빠름) · 성체(평균) · 늙은(몸↓ 스킬↑ 성장 느림).
## 능력치·성장 효과는 레벨·스킬이 생기면 붙인다. 지금은 기록만 한다.
enum Age { YOUNG, ADULT, OLD }

var species_id := ""
var suffix_id := ""
var age := Age.ADULT
## 빛나는 코어(기획서 8장: 좋은 접미사 확률↑). 무엇이 좋아지는지는 접미사 수치를 정할 때 붙인다.
var shining := false


## 저장용 사전. 나중에 로컬 저장·Firebase에 그대로 쓴다.
func to_dict() -> Dictionary:
	return {"species": species_id, "suffix": suffix_id, "age": age, "shining": shining}


static func from_dict(row: Dictionary) -> CoreItem:
	var item := CoreItem.new()
	item.species_id = str(row.get("species", ""))
	item.suffix_id = str(row.get("suffix", ""))
	item.age = clampi(int(row.get("age", Age.ADULT)), 0, Age.size() - 1) as Age
	item.shining = bool(row.get("shining", false))
	return item

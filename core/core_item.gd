class_name CoreItem
extends RefCounted
## 코어 하나(가방에 들어가는 것). 헨치의 본체(기획서 2장).
## 쓰러뜨린 야생 헨치의 종·나이·성별·변이·레벨을 그대로 받고, 접미사와 빛나는 코어는 떨어질 때 정해진다.
## 나이·변이에 따른 외형(부품·크기·색)은 그림이 들어오면 붙인다.

## 나이(기획서 4장): 어린(몸↑ 스킬↓ 성장 빠름) · 성체(평균) · 늙은(몸↓ 스킬↑ 성장 느림).
enum Age { YOUNG, ADULT, OLD }
## 성별(기획서 4장: 믹스는 암수 한 쌍, 어느 쪽이 암컷이냐에 따라 다른 종).
enum Gender { FEMALE, MALE }

var species_id := ""
var suffix_id := ""
var age := Age.ADULT
var gender := Gender.FEMALE
var level := 1
## 빛나는 코어(기획서 8장: 좋은 접미사 확률↑). 지금은 접미사 보너스가 더 크다(GameConfig.SHINING_SUFFIX_BONUS).
var shining := false
## 변이체의 코어(기획서 4장: 필드 헨치만, 처치하면 코어 확정).
var variant := false
## 잠금: 믹스 재료로 쓰거나 분해하지 못하게 막는다.
var locked := false
## 파티 자리(0부터). -1 = 파티에 없음.
var party_slot := -1
## 지금 패시브의 주인 종. 비어 있으면 자기 종의 고유 패시브, 믹스에서 유산을 고르면 주 코어의 패시브.
var passive_species_id := ""


func species() -> HenchSpecies:
	return HenchDb.get_species(species_id)


## 화면 제목 "접미사 + 이름"(예: 강력 고추룡).
func title() -> String:
	return "%s %s" % [SuffixDb.display_name(suffix_id), species().name]


## 지금 패시브가 어느 종의 것인가(유산이면 그 종, 아니면 자기 종).
func passive_owner_id() -> String:
	return passive_species_id if passive_species_id != "" else species_id


func in_party() -> bool:
	return party_slot >= 0


## 저장용 사전. 나중에 로컬 저장·Firebase에 그대로 쓴다.
func to_dict() -> Dictionary:
	return {
		"species": species_id, "suffix": suffix_id, "age": age, "gender": gender, "level": level,
		"shining": shining, "variant": variant, "locked": locked, "party_slot": party_slot, "passive": passive_species_id,
	}


static func from_dict(row: Dictionary) -> CoreItem:
	var item := CoreItem.new()
	item.species_id = str(row.get("species", ""))
	item.suffix_id = str(row.get("suffix", ""))
	item.age = clampi(int(row.get("age", Age.ADULT)), 0, Age.size() - 1) as Age
	item.gender = clampi(int(row.get("gender", Gender.FEMALE)), 0, Gender.size() - 1) as Gender
	item.level = maxi(int(row.get("level", 1)), 1)
	item.shining = bool(row.get("shining", false))
	item.variant = bool(row.get("variant", false))
	item.locked = bool(row.get("locked", false))
	item.party_slot = int(row.get("party_slot", -1))
	item.passive_species_id = str(row.get("passive", ""))
	return item


func duplicate_item() -> CoreItem:
	return CoreItem.from_dict(to_dict())

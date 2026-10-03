class_name GearItem
extends RefCounted
## 장비 하나(기획서 3장): 부위 · (무기면) 직업 · 이름 · 등급 · 품질 · 레벨 · 주 능력치 · 옵션 · 잠금.
## 값은 만들 때(GearRules.roll) 정해져서 그대로 저장된다. 착용 여부는 GearBag이 칸 → uid로 따로 기억한다.

## 가방 안에서 하나뿐인 번호(GearBag.add가 붙인다)
var uid := 0
## 부위 종류(GearDb.kinds: weapon · helmet · armor · gloves · boots · accessory)
var kind := ""
## 무기의 직업(그 직업만 낀다). 무기가 아니면 "".
var job_id := ""
var base_name := ""
## 등급(0 일반 · 1 마법 · 2 희귀 · 3 전설 · 4 세트, UiText.GEAR_GRADES)
var grade := 0
## 품질(0 하급 · 1 중급 · 2 상급 · 3 최상급, UiText.GEAR_QUALITIES)
var quality := 1
## 장비 레벨(주인공 레벨이 이보다 낮으면 못 낀다)
var level := 1
var main_stat := ""
var main_value := 0
## 옵션 [{"stat": 능력치 id(9종 · crit_chance · crit_damage · party_hp), "value": 값}] — 등급이 높을수록 많다
var options: Array[Dictionary] = []
var locked := false


## 이 장비가 올려 주는 것 {능력치: 값}(주 능력치 + 옵션).
func bonus() -> Dictionary:
	var total := {}
	if main_stat != "":
		total[main_stat] = main_value
	for option in options:
		var stat := str(option.get("stat", ""))
		total[stat] = total.get(stat, 0) + option.get("value", 0)
	return total


func to_dict() -> Dictionary:
	return {
		"uid": uid, "kind": kind, "job": job_id, "name": base_name, "grade": grade, "quality": quality, "level": level,
		"main": main_stat, "main_value": main_value, "options": options.duplicate(true), "locked": locked,
	}


static func from_dict(row: Dictionary) -> GearItem:
	var item := GearItem.new()
	item.uid = int(row.get("uid", 0))
	item.kind = str(row.get("kind", ""))
	item.job_id = str(row.get("job", ""))
	item.base_name = str(row.get("name", ""))
	item.grade = clampi(int(row.get("grade", 0)), 0, UiText.GEAR_GRADES.size() - 1)
	item.quality = clampi(int(row.get("quality", 1)), 0, UiText.GEAR_QUALITIES.size() - 1)
	item.level = maxi(int(row.get("level", 1)), 1)
	item.main_stat = str(row.get("main", ""))
	item.main_value = int(row.get("main_value", 0))
	for option: Variant in row.get("options", []):
		if option is Dictionary and option.has("stat"):
			var value: Variant = option.get("value", 0)
			item.options.append({"stat": str(option["stat"]), "value": value if GearRules.is_percent(str(option["stat"])) else int(value)})
	item.locked = bool(row.get("locked", false))
	return item

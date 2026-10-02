class_name HenchSpecies
extends RefCounted
## 헨치 한 종의 도감 정보(data/henches.json 한 칸).

const TRIBES := ["dragon", "plant", "demon", "beast", "machine", "spirit", "insect", "flying"]
const ROLES := ["tank", "melee", "ranged", "healer"]
const GRADES := ["low", "mid", "high", "king"]

var id := ""
var name := ""
var tribe := ""
var grade := ""
var role := ""
## 선공: 파티를 알아채면 먼저 덤빈다(빨간 이름표). 아니면 맞아야 반격한다(흰 이름표).
var aggressive := false
var design := ""
var active := ""
var passive := ""
var level_min := 1
var level_max := 1
var habitats := PackedStringArray()
## 그림이 들어오기 전까지 쓰는 임시 도형 색.
var color := Color.WHITE


static func from_dict(row: Dictionary) -> HenchSpecies:
	var s := HenchSpecies.new()
	s.id = str(row.get("id", ""))
	s.name = str(row.get("name", ""))
	s.tribe = str(row.get("tribe", ""))
	s.grade = str(row.get("grade", ""))
	s.role = str(row.get("role", ""))
	s.aggressive = bool(row.get("aggressive", false))
	s.design = str(row.get("design", ""))
	s.active = str(row.get("active", ""))
	s.passive = str(row.get("passive", ""))
	var level: Array = row.get("level", [1, 1])
	s.level_min = int(level[0])
	s.level_max = int(level[1])
	s.habitats = PackedStringArray(row.get("habitats", []))
	s.color = Color.from_string(str(row.get("color", "")), Color.WHITE)
	return s


## 잘못된 값 목록. 비어 있으면 정상.
func problems() -> PackedStringArray:
	var result := PackedStringArray()
	if id == "":
		result.append("id가 비어 있음")
	if name == "":
		result.append("%s: name이 비어 있음" % id)
	if tribe not in TRIBES:
		result.append("%s: 모르는 종족 '%s'" % [id, tribe])
	if role not in ROLES:
		result.append("%s: 모르는 역할 '%s'" % [id, role])
	if grade not in GRADES:
		result.append("%s: 모르는 등급 '%s'" % [id, grade])
	if level_min > level_max:
		result.append("%s: 레벨 범위가 거꾸로 됨" % id)
	return result

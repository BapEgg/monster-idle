class_name HenchSpecies
extends RefCounted
## 헨치 한 종의 도감 정보(data/henches.json 한 칸).

const TRIBES := ["dragon", "plant", "demon", "beast", "machine", "spirit", "insect", "flying"]
## 싸우는 역할 4개(필드 능력치가 있는 것). 섬의 왕은 따로 "boss".
const ROLES := ["tank", "melee", "ranged", "healer"]
const KING_ROLE := "boss"
const GRADES := ["low", "mid", "high", "king"]

var id := ""
var name := ""
var tribe := ""
var grade := ""
var role := ""
## 선공: 파티를 알아채면 먼저 덤빈다(빨간 이름표). 아니면 맞아야 반격한다(흰 이름표).
var aggressive := false
var design := ""
## 고유 액티브 설명(도감 글). 화면에 보이는 스킬 이름은 괄호 앞 부분(HenchSkill.skill_title).
var active := ""
## 고유 액티브의 효과 종류(GameConfig.SKILL_KINDS의 열쇠, 임시 분류). 왕은 미정이라 "".
var skill := ""
var passive := ""
var level_min := 1
var level_max := 1
var habitats := PackedStringArray()
## 믹스 공식(기획서 표): [주 코어 종 id, 보조 코어 종 id] 쌍 목록. 하급(드랍)은 비어 있고, 왕은 비밀이라 비어 있다.
## 같은 두 종이라도 어느 쪽이 주 코어냐에 따라 다른 공식이다(사용자 결정 2026-10-03).
var recipes: Array[PackedStringArray] = []
## 기획서에 없는 반대 방향 공식의 초안(임시, 데이터의 draft_recipes).
var draft_recipes: Array[PackedStringArray] = []
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
	s.skill = str(row.get("skill", ""))
	s.passive = str(row.get("passive", ""))
	var level: Array = row.get("level", [1, 1])
	s.level_min = int(level[0])
	s.level_max = int(level[1])
	s.habitats = PackedStringArray(row.get("habitats", []))
	for pair: Variant in row.get("recipes", []):
		s.recipes.append(PackedStringArray(pair))
	for pair: Variant in row.get("draft_recipes", []):
		s.draft_recipes.append(PackedStringArray(pair))
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
	if role not in ROLES and not (grade == "king" and role == KING_ROLE):
		result.append("%s: 모르는 역할 '%s'" % [id, role])
	if grade not in GRADES:
		result.append("%s: 모르는 등급 '%s'" % [id, grade])
	if skill != "" and not GameConfig.SKILL_KINDS.has(skill):
		result.append("%s: 모르는 스킬 종류 '%s'" % [id, skill])
	if level_min > level_max:
		result.append("%s: 레벨 범위가 거꾸로 됨" % id)
	for pair in recipes + draft_recipes:
		if pair.size() != 2:
			result.append("%s: 믹스 공식은 [주 코어, 보조 코어] 두 종이어야 함" % id)
	return result

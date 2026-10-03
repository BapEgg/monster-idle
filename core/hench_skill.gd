class_name HenchSkill
extends SkillTimer
## 헨치 고유 액티브 하나: 효과 종류(도감의 skill)와 다시 쓰기까지의 대기 시간. 순수 계산이라 테스트로 확인한다.
## 이름은 도감의 active 글("매운 박치기 (공격 + 화상)")의 괄호 앞, 효과와 수치는 종류별 설정(GameConfig.SKILL_KINDS)을 따른다.
## 피해 · 회복 계수(coefs, 기획서 4장 "스킬별 다중 스탯 계수")는 종류의 계수 + 괄호 안 "○○ 비례"의 능력치에 둘째 계수(GameConfig.SKILL_SECONDARY_COEF).
## 실제로 쓰는 일(대상 고르기 · 피해 · 기절 · 도발 · 회복)은 필드의 헨치(Hench)가 한다.

const OFFENSIVE := ["strike", "flurry", "blast", "stun"]
const HEALS := ["heal", "heal_all"]
## 도감 설명의 능력치 낱말 → 능력치(data/suffixes.json의 stat). 앞에서부터 찾는다("공속"이 "공격"보다 먼저).
const STAT_WORDS := [
	["공속", "swift"], ["공격 속도", "swift"], ["공격", "mighty"], ["명중", "precise"], ["회피", "nimble"],
	["방어", "sturdy"], ["체력", "tough"], ["마나", "abundant"], ["저항", "steadfast"], ["행운", "lucky"],
]

var kind := ""
## 피해(회복) 계수 {능력치: 계수}. 피해 · 회복이 없는 종류(도발)는 {}.
var coefs := {}


## 그 종의 고유 액티브. 효과 종류가 없으면(왕 · 미정) null.
static func for_species(species: HenchSpecies) -> HenchSkill:
	if species == null or not GameConfig.SKILL_KINDS.has(species.skill):
		return null
	var s := HenchSkill.new()
	s.kind = species.skill
	s.title = skill_title(species.active)
	s.icon = HenchDb.skill_icon(species.id)
	s.cooldown = s.value("cooldown")
	s.coefs = skill_coefs(species.skill, species.active)
	return s


## 효과 종류의 계수 + 설명 괄호 안 "○○ 비례"의 능력치(이미 있으면 그대로). 피해 · 회복이 없는 종류는 {}.
static func skill_coefs(of_kind: String, active: String) -> Dictionary:
	var base: Dictionary = GameConfig.SKILL_KINDS.get(of_kind, {}).get("coefs", {})
	var result := base.duplicate()
	if result.is_empty():
		return result
	var extra := proportional_stat(active)
	if extra != "" and not result.has(extra):
		result[extra] = GameConfig.SKILL_SECONDARY_COEF
	return result


## "물대포 (명중 비례)" → "precise". 없으면 "".
static func proportional_stat(active: String) -> String:
	for pair: Array in STAT_WORDS:
		if active.contains(str(pair[0]) + " 비례"):
			return str(pair[1])
	return ""


## "매운 박치기 (공격 + 화상)" → "매운 박치기"
static func skill_title(active: String) -> String:
	var cut := active.find(" (")
	return active.substr(0, cut) if cut >= 0 else active


## 그 점(center)에서 radius(땅 위 px) 안에 있는 점들의 번호.
static func indices_within(center: Vector2, points: Array[Vector2], radius: float) -> Array[int]:
	var result: Array[int] = []
	for i in points.size():
		if Iso.ground_distance(center, points[i]) <= radius:
			result.append(i)
	return result


## 종류별 설정 값 하나(없으면 fallback).
func value(key: String, fallback := 0.0) -> float:
	return float(GameConfig.SKILL_KINDS[kind].get(key, fallback))


func is_offensive() -> bool:
	return kind in OFFENSIVE


func is_heal() -> bool:
	return kind in HEALS

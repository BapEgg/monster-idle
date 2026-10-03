class_name HenchSkill
extends SkillTimer
## 헨치 고유 액티브 하나: 효과 종류(도감의 skill)와 다시 쓰기까지의 대기 시간. 순수 계산이라 테스트로 확인한다.
## 이름은 도감의 active 글("매운 박치기 (공격 + 화상)")의 괄호 앞, 효과와 수치는 종류별 설정(GameConfig.SKILL_KINDS)을 따른다.
## 실제로 쓰는 일(대상 고르기 · 피해 · 기절 · 도발 · 회복)은 필드의 헨치(Hench)가 한다.

const OFFENSIVE := ["strike", "flurry", "blast", "stun"]
const HEALS := ["heal", "heal_all"]

var kind := ""


## 그 종의 고유 액티브. 효과 종류가 없으면(왕 · 미정) null.
static func for_species(species: HenchSpecies) -> HenchSkill:
	if species == null or not GameConfig.SKILL_KINDS.has(species.skill):
		return null
	var s := HenchSkill.new()
	s.kind = species.skill
	s.title = skill_title(species.active)
	s.cooldown = s.value("cooldown")
	return s


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

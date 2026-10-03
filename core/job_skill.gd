class_name JobSkill
extends SkillTimer
## 장착한 직업 스킬 하나(필드에서 쓰는 것): 대기 시간 + 스킬 레벨 · 패시브 보정을 반영한 효과들.
## 효과를 실제로 쓰는 일(대상 고르기 · 피해 · 보호막 · 버프 …)은 주인공(Player)이 한다.

var id := ""
## active · ultimate
var type := ""
var level := 1
## 스킬 레벨 · 패시브 보정으로 키운 효과들(JobRules.scaled_effect)
var effects: Array[Dictionary] = []


## 그 스킬을 그 레벨로. 액티브 · 궁극기가 아니거나 수치가 없으면 null.
static func create(skill: JobDb.Skill, skill_level: int, mods: Dictionary = {}) -> JobSkill:
	if skill == null or skill.is_passive():
		return null
	var config := skill.config()
	if not config.has("effects"):
		return null
	var s := JobSkill.new()
	s.id = skill.id
	s.type = skill.type
	s.title = skill.name
	s.level = skill_level
	s.cooldown = float(config.get("cooldown", 0.0))
	for effect: Dictionary in config["effects"]:
		s.effects.append(JobRules.scaled_effect(effect, skill_level, mods))
	return s


## 효과 종류들(type).
func types() -> PackedStringArray:
	var list := PackedStringArray()
	for effect in effects:
		list.append(str(effect.get("type", "")))
	return list


## 적을 때리는 스킬인가(대상이 사거리 안일 때 쓴다).
func needs_enemy() -> bool:
	for type_name in types():
		if type_name in ["hit", "dash", "retreat", "pierce"] or (type_name == "area" and _area_at_target()):
			return true
	return false


func _area_at_target() -> bool:
	for effect in effects:
		if effect.get("type") == "area" and effect.get("at", "target") == "target":
			return true
	return false


## 대상까지 닿아야 하는 거리(땅 위 px): hit은 range(없으면 기본 사거리), dash · pierce는 그 길이. 0이면 기본 사거리.
func reach() -> float:
	var most := 0.0
	for effect in effects:
		match str(effect.get("type", "")):
			"hit", "dash":
				most = maxf(most, float(effect.get("range", 0.0)))
			"pierce":
				most = maxf(most, float(effect.get("length", 0.0)))
	return most

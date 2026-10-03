class_name JobRules
extends RefCounted
## 직업 스킬 규칙(순수 함수, 기획서 3장 스킬 시스템). 수치는 GameConfig의 JOB_* 에서 읽는다.
## - 해금: 주인공 레벨이 스킬의 해금 레벨에 닿으면 스킬 레벨 1로 배운다.
## - 스킬 포인트: 주인공 레벨이 오를 때마다 JOB_SKILL_POINTS_PER_LEVEL. 스킬 레벨을 1 올리는 데 1점(상한 JOB_SKILL_MAX_LEVEL).
## - 스킬 레벨 1당 효과(배율 · 보호막 · 버프 · 회복 · 패시브 보정)가 JOB_SKILL_LEVEL_BONUS만큼 커진다. 범위 · 시간 · 대기 시간은 그대로.
## - 패시브 칸은 JOB_PASSIVE_SLOT_LEVELS에 닿을 때마다 하나씩 열린다.

## 스킬 레벨만큼 커지는 효과 값들
const SCALED_KEYS := ["power", "amount", "attack", "speed", "guard", "vulnerable", "hp"]
const BUFF_KEYS := ["attack", "speed", "guard"]
## 받는 피해 줄이기(guard · damage_taken)의 상한(아무리 쌓여도 이 비율까지만 준다)
const GUARD_CAP := 0.8


## 스킬 레벨 배율: 1 + 보너스 × (레벨 − 1).
static func level_scale(skill_level: int) -> float:
	return 1.0 + GameConfig.JOB_SKILL_LEVEL_BONUS * maxi(skill_level - 1, 0)


static func is_unlocked(skill: JobDb.Skill, player_level: int) -> bool:
	return skill != null and player_level >= skill.unlock


## 그 레벨까지 받은 스킬 포인트.
static func points_earned(player_level: int) -> int:
	return GameConfig.JOB_SKILL_POINTS_PER_LEVEL * maxi(player_level - 1, 0)


## 스킬 레벨들(id → 레벨)에 쓴 포인트(배울 때의 레벨 1은 공짜).
static func points_spent(levels: Dictionary) -> int:
	var spent := 0
	for level: int in levels.values():
		spent += maxi(level - 1, 0)
	return spent


## 열린 패시브 칸 수.
static func passive_slot_count(player_level: int) -> int:
	var count := 0
	for at: int in GameConfig.JOB_PASSIVE_SLOT_LEVELS:
		if player_level >= at:
			count += 1
	return count


## 효과 하나를 스킬 레벨과 패시브 보정(mods)으로 키운 복사본.
## 버프는 buff_power · buff_seconds, 회복은 heal_power 보정을 더 받는다.
static func scaled_effect(effect: Dictionary, skill_level: int, mods: Dictionary = {}) -> Dictionary:
	var result := effect.duplicate()
	var scale := level_scale(skill_level)
	for key: String in SCALED_KEYS:
		if result.has(key):
			result[key] = float(result[key]) * scale
	match str(result.get("type", "")):
		"buff":
			for key: String in BUFF_KEYS:
				if result.has(key):
					result[key] = float(result[key]) * (1.0 + float(mods.get("buff_power", 0.0)))
			if result.has("guard"):
				result["guard"] = minf(float(result["guard"]), GUARD_CAP)
			result["seconds"] = float(result.get("seconds", 0.0)) * (1.0 + float(mods.get("buff_seconds", 0.0)))
		"heal":
			result["power"] = float(result.get("power", 0.0)) * (1.0 + float(mods.get("heal_power", 0.0)))
	return result


## 장착한 패시브들의 보정 합(스킬 레벨만큼 키움). levels = 스킬 id → 레벨.
static func sum_mods(passive_ids: Array, levels: Dictionary) -> Dictionary:
	var total := {}
	for id: String in passive_ids:
		var skill := JobDb.get_skill(id)
		if skill == null or not skill.is_passive():
			continue
		var scale := level_scale(int(levels.get(id, 1)))
		var mods: Dictionary = skill.config().get("mods", {})
		for key: String in mods:
			total[key] = float(total.get(key, 0.0)) + float(mods[key]) * scale
	if total.has("damage_taken"):
		total["damage_taken"] = minf(float(total["damage_taken"]), GUARD_CAP)
	if total.has("tank_damage_taken"):
		total["tank_damage_taken"] = minf(float(total["tank_damage_taken"]), GUARD_CAP)
	return total


## 직업 기본 능력치 × 레벨 배율 + 패시브 보정(체력 · 공격 · 공격 속도 · 이동 속도 · 사거리).
static func player_stats(job_id: String, player_level: int, mods: Dictionary = {}) -> UnitStats:
	var row: Dictionary = GameConfig.JOB_STATS.get(job_id, GameConfig.PLAYER_STATS)
	var scale := Growth.stat_scale(player_level)
	var s := UnitStats.from_table(row, GameConfig.PLAYER_SPEED, scale, scale)
	s.max_hp *= 1.0 + float(mods.get("hp", 0.0))
	s.attack *= 1.0 + float(mods.get("attack", 0.0))
	s.heal *= 1.0 + float(mods.get("heal_power", 0.0))
	s.attack_interval /= 1.0 + float(mods.get("attack_speed", 0.0))
	s.speed *= 1.0 + float(mods.get("move_speed", 0.0))
	s.attack_range *= 1.0 + float(mods.get("range", 0.0))
	return s

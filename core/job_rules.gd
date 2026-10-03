class_name JobRules
extends RefCounted
## 직업 스킬 규칙(순수 함수, 기획서 3장 스킬 시스템). 수치는 GameConfig의 JOB_* 에서 읽는다.
## - 해금: 주인공 레벨이 스킬의 해금 레벨에 닿으면 스킬 레벨 1로 배운다.
## - 스킬 포인트: 주인공 레벨이 오를 때마다 JOB_SKILL_POINTS_PER_LEVEL. 스킬 레벨을 1 올리는 데 1점(상한 JOB_SKILL_MAX_LEVEL).
## - 스킬 레벨 1당 효과(계수 · 보호막 · 버프 · 패시브 보정)가 JOB_SKILL_LEVEL_BONUS만큼 커지고, 재사용 대기가 JOB_SKILL_COOLDOWN_CUT만큼 준다. 범위 · 시간은 그대로.
## - 패시브 칸은 JOB_PASSIVE_SLOT_LEVELS에 닿을 때마다 하나씩 열린다.

## 스킬 레벨만큼 커지는 효과 값들(피해 · 회복 계수 coefs 안의 값들도 함께)
const SCALED_KEYS := ["amount", "attack", "speed", "guard", "vulnerable", "hp"]
## 능력치를 올리는 패시브 보정 → 그 능력치(체력 · 강력 · 충만). 나머지 보정은 전투 값(공격 간격 · 사거리 · 이동 속도 …)에 붙는다.
const MOD_STATS := {"hp": "tough", "attack": "mighty", "heal_power": "abundant"}
const BUFF_KEYS := ["attack", "speed", "guard"]
## 받는 피해 줄이기(guard · damage_taken)의 상한(아무리 쌓여도 이 비율까지만 준다)
const GUARD_CAP := 0.8


## 스킬 레벨 배율: 1 + 보너스 × (레벨 − 1).
static func level_scale(skill_level: int) -> float:
	return 1.0 + GameConfig.JOB_SKILL_LEVEL_BONUS * maxi(skill_level - 1, 0)


## 그 스킬 레벨의 재사용 대기: 처음 값 × (1 − 줄이기 × (레벨 − 1)).
static func cooldown_at(base: float, skill_level: int) -> float:
	return base * maxf(1.0 - GameConfig.JOB_SKILL_COOLDOWN_CUT * maxi(skill_level - 1, 0), 0.0)


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
## 버프는 buff_power · buff_seconds 보정을 더 받는다(회복은 heal_power가 충만을 올려서 계수로 커진다).
static func scaled_effect(effect: Dictionary, skill_level: int, mods: Dictionary = {}) -> Dictionary:
	var result := effect.duplicate(true)
	var scale := level_scale(skill_level)
	for key: String in SCALED_KEYS:
		if result.has(key):
			result[key] = float(result[key]) * scale
	if result.has("coefs"):
		var coefs := {}
		for stat: String in result["coefs"]:
			coefs[stat] = float(result["coefs"][stat]) * scale
		result["coefs"] = coefs
	match str(result.get("type", "")):
		"buff":
			for key: String in BUFF_KEYS:
				if result.has(key):
					result[key] = float(result[key]) * (1.0 + float(mods.get("buff_power", 0.0)))
			if result.has("guard"):
				result["guard"] = minf(float(result["guard"]), GUARD_CAP)
			result["seconds"] = float(result.get("seconds", 0.0)) * (1.0 + float(mods.get("buff_seconds", 0.0)))
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


## 주인공 능력치 9종(코어와 같은 능력치, 사용자 결정 2026-10-03) + HP · MP: 직업 Lv 1 값 × 레벨 배율 × 패시브 보정(체력 · 강력 · 충만).
## 나중에 장비가 여기에 더해진다.
static func player_sheet(job_id: String, player_level: int, mods: Dictionary = {}) -> Dictionary:
	var base: Dictionary = GameConfig.JOB_BASE_STATS.get(job_id, GameConfig.JOB_BASE_STATS[GameConfig.START_JOB])
	var scale := Growth.stat_scale(player_level)
	var boosted := {}
	for key: String in MOD_STATS:
		boosted[MOD_STATS[key]] = float(mods.get(key, 0.0))
	var sheet := {}
	for stat: String in base:
		sheet[stat] = roundi(float(base[stat]) * scale * (1.0 + float(boosted.get(stat, 0.0))))
	sheet["hp"] = int(sheet.get("tough", 0)) * GameConfig.HP_PER_TOUGH
	sheet["mp"] = int(sheet.get("abundant", 0)) * GameConfig.MP_PER_ABUNDANT
	return sheet


## 주인공 전투 능력치: 능력치 9종을 코어와 같은 환산으로(체력 → HP, 강력 → 공격력, 충만 → 회복력, 신속 → 공격 간격) +
## 무기(공격 간격 · 사거리) + 전투 값 패시브(공격 속도 · 이동 속도 · 사거리).
static func player_stats(job_id: String, player_level: int, mods: Dictionary = {}) -> UnitStats:
	var sheet := player_sheet(job_id, player_level, mods)
	var weapon: Dictionary = GameConfig.JOB_WEAPONS.get(job_id, GameConfig.JOB_WEAPONS[GameConfig.START_JOB])
	var s := UnitStats.new()
	s.sheet = sheet
	s.max_hp = maxf(float(sheet["hp"]), 1.0)
	s.attack = float(sheet["mighty"]) * GameConfig.CORE_COMBAT_ATTACK_PER_MIGHTY
	s.heal = float(sheet["abundant"]) * GameConfig.CORE_COMBAT_HEAL_PER_ABUNDANT
	var half := GameConfig.CORE_COMBAT_SWIFT_HALF
	s.attack_interval = float(weapon["attack_interval"]) * half / (half + float(sheet["swift"])) / (1.0 + float(mods.get("attack_speed", 0.0)))
	s.heal_interval = s.attack_interval
	s.attack_range = float(weapon["attack_range"]) * (1.0 + float(mods.get("range", 0.0)))
	s.speed = GameConfig.PLAYER_SPEED * (1.0 + float(mods.get("move_speed", 0.0)))
	return s

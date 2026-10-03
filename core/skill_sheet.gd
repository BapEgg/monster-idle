class_name SkillSheet
extends RefCounted
## 스킬 상세 창의 내용(순수 함수, 사용자 결정 2026-10-03: 롤처럼 스킬을 누르면 모션 미리보기 · 설명 · 계수).
## 헨치 고유 스킬은 종마다 액티브 1 + 패시브 1로 정해져 있다(기획서 4장 확정). 패시브는 믹스할 때 유산으로만 바뀐다.
## 주인공 직업 스킬(job_skill)도 같은 모양으로 만든다. 이 창은 보기 전용이다(장착 · 레벨 올리기는 직업 창 아래 줄, 사용자 결정 2026-10-03).
## 돌려주는 내용(Dictionary): title(이름) · tag(꼬리표) · description(설명) · rows([이름표, 값] 줄들) · motion(미리보기 종류) · note(작은 안내),
## 액티브는 미리보기에 쓰는 radius(범위, 땅 위 px) · hits(때리는 횟수) · amount(지금 한 번 값, 모르면 0)도.
## 피해 · 회복은 능력치마다 계수("공격 × 180% + 명중 × 80%", 기획서 4장 다중 스탯 계수 — 주인공도 같다).
## stats(그 코어 · 주인공의 능력치, UnitStats.sheet)를 주면 "지금 n"도 붙인다.

## 미리보기 종류: 액티브는 효과 종류 이름 그대로(strike · flurry …), 그 밖에는 아래 셋.
const MOTION_PASSIVE := "passive"
const MOTION_VARIANT := "variant"
const MOTION_INHERIT := "inherit"


## 고유 액티브. stats가 null이면(믹스 결과 미리보기 등) 지금 값은 빼고 계수만.
static func active(species: HenchSpecies, stats: UnitStats = null) -> Dictionary:
	var kind := species.skill
	var config: Dictionary = GameConfig.SKILL_KINDS.get(kind, {})
	var coefs := HenchSkill.skill_coefs(kind, species.active)
	var heal := kind in HenchSkill.HEALS
	var hits := int(config.get("hits", 1))
	var rows := [[UiText.SKILL_ROW_TARGET, UiText.SKILL_TARGETS.get(kind, "")]]
	if not coefs.is_empty():
		rows.append(amount_row(coefs, stats, heal, hits))
	if kind == "taunt":
		var share := float(config.get("shield", 0.0))
		var shield := UiText.SKILL_SHIELD_POWER % [roundi(share * 100.0), seconds(float(config.get("shield_seconds", 0.0)))]
		rows.append([UiText.SKILL_ROW_SHIELD, shield + _now(stats, stats.max_hp * share if stats != null else 0.0)])
	if config.has("radius"):
		rows.append([UiText.SKILL_ROW_RADIUS, UiText.SKILL_RADIUS_VALUE % roundi(float(config["radius"]))])
	if config.has("stun"):
		rows.append([UiText.SKILL_ROW_STUN, UiText.SKILL_SECONDS % seconds(float(config["stun"]))])
	rows.append([UiText.SKILL_ROW_COOLDOWN, UiText.SKILL_SECONDS % seconds(float(config.get("cooldown", 0.0)))])
	var amount := 0
	if stats != null:
		if kind == "taunt":
			amount = roundi(stats.max_hp * float(config.get("shield", 0.0)))
		elif not coefs.is_empty():
			amount = roundi(stats.skill_amount(coefs, heal))
	var design := design_note(species.active)
	if design != "":
		rows.append([UiText.SKILL_ROW_DESIGN, design])
	return {
		"title": HenchSkill.skill_title(species.active),
		"tag": UiText.SKILL_TAG_ACTIVE % UiText.SKILL_KIND_NAMES.get(kind, kind),
		"description": UiText.SKILL_DESCRIPTIONS.get(kind, ""),
		"rows": rows,
		"motion": kind,
		"radius": float(config.get("radius", 0.0)),
		"hits": hits,
		"amount": amount,
		"note": UiText.SKILL_NOTE_ACTIVE,
	}


## 패시브. holder = 패시브의 원래 주인 종(유산이면 주 코어의 종, 아니면 자기 종).
static func passive(species: HenchSpecies, holder: HenchSpecies) -> Dictionary:
	var legacy := holder != null and holder != species
	var source := holder if legacy else species
	var rows := [[UiText.SKILL_ROW_EFFECT, source.passive]]
	if legacy:
		rows.append([UiText.SKILL_ROW_FROM, source.name])
	return {
		"title": source.passive,
		"tag": UiText.SKILL_TAG_LEGACY % source.name if legacy else UiText.SKILL_TAG_PASSIVE,
		"description": UiText.SKILL_PASSIVE_DESC,
		"rows": rows,
		"motion": MOTION_PASSIVE,
		"note": UiText.SKILL_NOTE_PASSIVE,
	}


## 변이(돌연변이) 보정. 변이가 아니면 빈 내용.
static func variant(item: CoreItem) -> Dictionary:
	if not item.variant:
		return {}
	var bonus := roundi(GameConfig.VARIANT_STAT_BONUS * 100.0)
	return {
		"title": UiText.CHIP_VARIANT_TITLE % bonus,
		"tag": UiText.SKILL_TAG_VARIANT,
		"description": UiText.SKILL_VARIANT_DESC,
		"rows": [
			[UiText.SKILL_ROW_STATS, SuffixDb.stat_list(CoreStats.variant_stats(item))],
			[UiText.SKILL_ROW_BONUS, "+%d%%" % bonus],
			[UiText.SKILL_ROW_MIX, UiText.SKILL_VARIANT_MIX],
		],
		"motion": MOTION_VARIANT,
		"note": "",
	}


## 믹스 계승 스탯(보조 코어에게서). 믹스로 태어나지 않았으면 빈 내용.
static func inherit(item: CoreItem) -> Dictionary:
	if not item.is_mix_born():
		return {}
	var value := UiText.SKILL_INHERIT_VALUE % [SuffixDb.stat_name(item.inherit_stat), item.inherit_value]
	return {
		"title": value,
		"tag": UiText.SKILL_TAG_INHERIT,
		"description": UiText.SKILL_INHERIT_DESC,
		"rows": [[UiText.SKILL_ROW_INHERIT, value]],
		"motion": MOTION_INHERIT,
		"note": "",
	}


## 직업 스킬(기획서 3장). level = 스킬 레벨(0 = 아직 안 배움 → 1레벨 값으로 보여 줌), stats = 주인공 능력치(없으면 지금 값 없이),
## mods = 장착 패시브 보정(버프가 커진다), player_level = 주인공 레벨(안 배운 스킬이 "배울 수 있음"인지 "Lv n에 배움"인지).
## 액티브 · 궁극기는 효과마다 계수 줄, 패시브는 보정 줄.
static func job_skill(skill: JobDb.Skill, level: int, stats: UnitStats = null, mods: Dictionary = {}, player_level := 0) -> Dictionary:
	var job := JobDb.get_job(skill.job_id)
	var shown_level := maxi(level, 1)
	var rows := []
	var level_text := UiText.JOB_LEVEL_VALUE % [level, GameConfig.JOB_SKILL_MAX_LEVEL]
	if level <= 0:
		level_text = UiText.JOB_LEVEL_LEARNABLE % skill.unlock if player_level >= skill.unlock else UiText.JOB_LEVEL_LOCKED % skill.unlock
	rows.append([UiText.JOB_ROW_LEVEL, level_text])
	var config := skill.config()
	var motion := MOTION_PASSIVE
	var amount := 0
	var radius := 0.0
	var hits := 1
	if skill.is_passive():
		var mods_of: Dictionary = JobRules.sum_mods([skill.id], {skill.id: shown_level})
		for key: String in mods_of:
			rows.append([UiText.JOB_ROW_MOD, UiText.JOB_MOD_NAMES.get(key, key + " %d%%") % roundi(float(mods_of[key]) * 100.0)])
	else:
		var first := true
		for raw: Dictionary in config.get("effects", []):
			var effect := JobRules.scaled_effect(raw, shown_level, mods)
			rows.append_array(_effect_rows(effect, stats))
			if first:
				motion = job_motion(effect)
				radius = float(effect.get("radius", 0.0))
				hits = int(effect.get("hits", 1))
				amount = _effect_amount(effect, stats)
				first = false
		rows.append([UiText.SKILL_ROW_COOLDOWN, UiText.SKILL_SECONDS % seconds(float(config.get("cooldown", 0.0)))])
	rows.append([UiText.JOB_ROW_LEVEL_BONUS, UiText.JOB_LEVEL_BONUS_VALUE % roundi(GameConfig.JOB_SKILL_LEVEL_BONUS * 100.0)])
	return {
		"title": skill.name,
		"tag": UiText.JOB_SKILL_TAG % [job.name if job != null else "", UiText.JOB_TYPE_NAMES.get(skill.type, skill.type)],
		"description": skill.desc,
		"rows": rows,
		"motion": motion,
		"radius": radius,
		"hits": hits,
		"amount": amount,
		"note": UiText.JOB_PASSIVE_NOTE if skill.is_passive() else UiText.JOB_ACTIVE_NOTE,
	}


## 직업 스킬 효과 하나의 계수 줄들.
static func _effect_rows(effect: Dictionary, stats: UnitStats) -> Array:
	var rows := []
	var coefs: Dictionary = effect.get("coefs", {})
	match str(effect.get("type", "")):
		"hit":
			var hits := int(effect.get("hits", 1))
			rows.append([UiText.JOB_ROW_TARGET, UiText.JOB_TARGETS["one"]])
			rows.append(amount_row(coefs, stats, false, hits))
		"area":
			rows.append([UiText.JOB_ROW_TARGET, UiText.JOB_TARGETS["target" if effect.get("at", "target") == "target" else "around"]])
			rows.append(amount_row(coefs, stats))
			rows.append([UiText.SKILL_ROW_RADIUS, UiText.SKILL_RADIUS_VALUE % roundi(float(effect.get("radius", 0.0)))])
			if effect.has("stun"):
				rows.append([UiText.SKILL_ROW_STUN, UiText.SKILL_SECONDS % seconds(float(effect["stun"]))])
			if effect.has("vulnerable"):
				rows.append([UiText.JOB_ROW_DEBUFF, UiText.JOB_VULNERABLE_VALUE % [roundi(float(effect["vulnerable"]) * 100.0), seconds(float(effect.get("seconds", 0.0)))]])
		"taunt":
			rows.append([UiText.JOB_ROW_TARGET, UiText.JOB_TAUNT_VALUE % roundi(float(effect.get("radius", 0.0)))])
		"shield":
			var share := float(effect.get("amount", 0.0))
			var shield := UiText.SKILL_SHIELD_POWER % [roundi(share * 100.0), seconds(float(effect.get("seconds", 0.0)))]
			rows.append([UiText.SKILL_ROW_SHIELD, shield + _now(stats, stats.max_hp * share if stats != null else 0.0) + " · " + UiText.JOB_TARGETS[str(effect.get("who", "self"))]])
		"dash":
			rows.append([UiText.JOB_ROW_MOVE, UiText.JOB_DASH_VALUE % roundi(float(effect.get("range", 0.0)))])
			rows.append(amount_row(coefs, stats))
			if float(effect.get("radius", 0.0)) > 0.0:
				rows.append([UiText.SKILL_ROW_RADIUS, UiText.SKILL_RADIUS_VALUE % roundi(float(effect["radius"]))])
		"retreat":
			rows.append(amount_row(coefs, stats))
			rows.append([UiText.JOB_ROW_MOVE, UiText.JOB_RETREAT_VALUE % roundi(float(effect.get("distance", 0.0)))])
		"pierce":
			rows.append([UiText.JOB_ROW_TARGET, UiText.JOB_TARGETS["line"]])
			rows.append(amount_row(coefs, stats))
			rows.append([UiText.JOB_ROW_LENGTH, UiText.JOB_LENGTH_VALUE % [roundi(float(effect.get("length", 0.0))), roundi(float(effect.get("width", 0.0)))]])
		"smoke":
			rows.append([UiText.JOB_ROW_TARGET, UiText.JOB_TARGETS["around"]])
			rows.append([UiText.SKILL_ROW_RADIUS, UiText.SKILL_RADIUS_VALUE % roundi(float(effect.get("radius", 0.0)))])
			rows.append([UiText.JOB_ROW_SMOKE, UiText.JOB_SMOKE_VALUE % seconds(float(effect.get("seconds", 0.0)))])
		"heal":
			rows.append([UiText.JOB_ROW_TARGET, UiText.JOB_TARGETS[str(effect.get("who", "lowest"))]])
			rows.append(amount_row(coefs, stats, true))
			if float(effect.get("radius", 0.0)) > 0.0:
				rows.append([UiText.SKILL_ROW_RADIUS, UiText.SKILL_RADIUS_VALUE % roundi(float(effect["radius"]))])
			if effect.get("cleanse", false):
				rows.append([UiText.JOB_ROW_CLEANSE, UiText.JOB_CLEANSE_VALUE])
		"revive":
			var count := int(effect.get("count", 1))
			var hp := roundi(float(effect.get("hp", 0.5)) * 100.0)
			rows.append([UiText.JOB_ROW_REVIVE, UiText.JOB_REVIVE_VALUE % [count, hp] if count < GameConfig.PARTY_HENCHES.size() else UiText.JOB_REVIVE_ALL % hp])
		"buff":
			var parts := PackedStringArray()
			for key: String in JobRules.BUFF_KEYS:
				if effect.has(key):
					parts.append(UiText.JOB_BUFF_PARTS[key] % roundi(float(effect[key]) * 100.0))
			rows.append([UiText.JOB_ROW_TARGET, UiText.JOB_TARGETS[str(effect.get("who", "self"))]])
			rows.append([UiText.JOB_ROW_BUFF, UiText.LIST_SEPARATOR.join(parts) + UiText.JOB_SECONDS_SUFFIX % seconds(float(effect.get("seconds", 0.0)))])
		"storm":
			var hits := int(effect.get("hits", 1))
			rows.append([UiText.JOB_ROW_TARGET, UiText.JOB_TARGETS["around"]])
			rows.append(amount_row(coefs, stats, false, hits))
			rows.append([UiText.SKILL_ROW_RADIUS, UiText.SKILL_RADIUS_VALUE % roundi(float(effect.get("radius", 0.0)))])
	return rows


## 직업 스킬 효과의 미리보기 종류(헨치 스킬과 같은 것은 같은 모션을 쓴다).
static func job_motion(effect: Dictionary) -> String:
	match str(effect.get("type", "")):
		"hit":
			return "flurry" if int(effect.get("hits", 1)) > 1 else "strike"
		"area":
			return "stun" if effect.has("stun") else "blast"
		"shield":
			return "shield_all" if effect.get("who", "self") == "party" else "shield"
		"heal":
			return "heal_all" if effect.get("who", "lowest") == "area" else "heal"
	return str(effect.get("type", "strike"))


## 미리보기에 띄울 숫자(지금 한 번 값, 모르면 0).
static func _effect_amount(effect: Dictionary, stats: UnitStats) -> int:
	if stats == null:
		return 0
	match str(effect.get("type", "")):
		"heal":
			return roundi(stats.skill_amount(effect.get("coefs", {}), true))
		"shield":
			return roundi(stats.max_hp * float(effect.get("amount", 0.0)))
	return roundi(stats.skill_amount(effect.get("coefs", {})))


## 피해 · 회복 줄 하나: [이름표(물리 피해 · 마법 피해 · 회복), "계수( × n번)  (지금 n)"].
static func amount_row(coefs: Dictionary, stats: UnitStats, heal := false, hits := 1) -> Array:
	var label := UiText.SKILL_ROW_HEAL if heal else (UiText.SKILL_ROW_MAGIC if is_magic(coefs) else UiText.SKILL_ROW_PHYSICAL)
	var text := coef_text(coefs)
	if hits > 1:
		text += UiText.SKILL_HITS_SUFFIX % hits
	if stats != null:
		text += (UiText.SKILL_NOW_EACH if hits > 1 else UiText.SKILL_NOW) % roundi(stats.skill_amount(coefs, heal))
	return [label, text]


## 계수 글: {mighty: 1.8, precise: 0.8} → "공격 × 180% + 명중 × 80%"(능력치 이름은 SuffixDb.stat_name).
static func coef_text(coefs: Dictionary) -> String:
	var parts := PackedStringArray()
	for stat: String in coefs:
		parts.append(UiText.SKILL_COEF_TERM % [SuffixDb.stat_name(stat), roundi(float(coefs[stat]) * 100.0)])
	return UiText.SKILL_COEF_JOIN.join(parts)


## 마법 피해인가: 가장 큰 계수가 마나(충만)면 마법, 아니면 물리(임시 구분 — 방어 · 저항 계산은 아직 없다).
static func is_magic(coefs: Dictionary) -> bool:
	var top := ""
	var best := -1.0
	for stat: String in coefs:
		if float(coefs[stat]) > best:
			best = float(coefs[stat])
			top = stat
	return top == "abundant"


## 도감 액티브 글의 괄호 안("매운 박치기 (공격 + 화상)" → "공격 + 화상"). 없으면 "".
static func design_note(active_text: String) -> String:
	var open := active_text.find(" (")
	if open < 0 or not active_text.ends_with(")"):
		return ""
	return active_text.substr(open + 2, active_text.length() - open - 3)


## 초를 짧게(8.0 → "8", 0.5 → "0.5").
static func seconds(value: float) -> String:
	return String.num(value, 1)


static func _now(stats: UnitStats, value: float) -> String:
	return UiText.SKILL_NOW % roundi(value) if stats != null else ""

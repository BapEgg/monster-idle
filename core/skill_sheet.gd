class_name SkillSheet
extends RefCounted
## 스킬 상세 창의 내용(순수 함수, 사용자 결정 2026-10-03: 롤처럼 스킬을 누르면 모션 미리보기 · 설명 · 계수).
## 헨치 고유 스킬은 종마다 액티브 1 + 패시브 1로 정해져 있다(기획서 4장 확정). 패시브는 믹스할 때 유산으로만 바뀐다.
## 고르는 스킬 창(장착)은 주인공 직업 스킬(액티브 3 · 패시브 1 · 궁극기 1) 단계에서 이 창을 다시 쓴다.
## 돌려주는 내용(Dictionary): title(이름) · tag(꼬리표) · description(설명) · rows([이름표, 값] 줄들) · motion(미리보기 종류) · note(작은 안내),
## 액티브는 미리보기에 쓰는 radius(범위, 땅 위 px) · hits(때리는 횟수) · amount(지금 한 번 값, 모르면 0)도.
## 액티브 계수는 효과 종류(GameConfig.SKILL_KINDS) 값 그대로이고, stats(그 코어의 전투 능력치)를 주면 "지금 n"도 붙인다.

## 미리보기 종류: 액티브는 효과 종류 이름 그대로(strike · flurry …), 그 밖에는 아래 셋.
const MOTION_PASSIVE := "passive"
const MOTION_VARIANT := "variant"
const MOTION_INHERIT := "inherit"


## 고유 액티브. stats가 null이면(믹스 결과 미리보기 등) 지금 값은 빼고 배율만.
static func active(species: HenchSpecies, stats: UnitStats = null) -> Dictionary:
	var kind := species.skill
	var config: Dictionary = GameConfig.SKILL_KINDS.get(kind, {})
	var rows := [[UiText.SKILL_ROW_TARGET, UiText.SKILL_TARGETS.get(kind, "")]]
	var power := float(config.get("power", 0.0))
	var percent := roundi(power * 100.0)
	match kind:
		"strike", "blast", "stun":
			rows.append([UiText.SKILL_ROW_DAMAGE, UiText.SKILL_POWER % percent + _now(stats, stats.attack * power if stats != null else 0.0)])
		"flurry":
			var hits := int(config.get("hits", 1))
			var each := UiText.SKILL_NOW_EACH % roundi(stats.attack * power) if stats != null else ""
			rows.append([UiText.SKILL_ROW_DAMAGE, UiText.SKILL_POWER_HITS % [percent, hits] + each])
		"heal", "heal_all":
			rows.append([UiText.SKILL_ROW_HEAL, UiText.SKILL_HEAL_POWER % percent + _now(stats, heal_power(stats) * power if stats != null else 0.0)])
		"taunt":
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
		match kind:
			"strike", "blast", "stun", "flurry":
				amount = roundi(stats.attack * power)
			"heal", "heal_all":
				amount = roundi(heal_power(stats) * power)
			"taunt":
				amount = roundi(stats.max_hp * float(config.get("shield", 0.0)))
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
		"hits": int(config.get("hits", 1)),
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


## 도감 액티브 글의 괄호 안("매운 박치기 (공격 + 화상)" → "공격 + 화상"). 없으면 "".
static func design_note(active_text: String) -> String:
	var open := active_text.find(" (")
	if open < 0 or not active_text.ends_with(")"):
		return ""
	return active_text.substr(open + 2, active_text.length() - open - 3)


## 회복 스킬의 바탕 값: 회복력이 없으면 공격력(필드의 헨치와 같다).
static func heal_power(stats: UnitStats) -> float:
	return stats.heal if stats.heal > 0.0 else stats.attack


## 초를 짧게(8.0 → "8", 0.5 → "0.5").
static func seconds(value: float) -> String:
	return String.num(value, 1)


static func _now(stats: UnitStats, value: float) -> String:
	return UiText.SKILL_NOW % roundi(value) if stats != null else ""

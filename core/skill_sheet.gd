class_name SkillSheet
extends RefCounted
## 스킬 상세 창(툴팁)의 내용(순수 함수, 사용자 결정 2026-10-03: 롤 툴팁처럼). 헨치 고유 스킬과 주인공 직업 스킬이 같은 모양이다.
## 돌려주는 내용(Dictionary):
##   title(이름) · tags(꼬리표: 액티브/패시브/궁극기 · 근접/원거리 · 단일/범위/자신) · level("Lv 2/10" 등, 없으면 "") · level_state(learned · learnable · locked · "")
##   line(마나 소모 · 재사용 대기 · 사거리 한 줄, 패시브는 "") · body(설명 문장: 계산된 숫자 + 스탯 색 계수 + 상태이상)
##   next(다음 레벨 비교, 없으면 "") · dev(개발 문구 — 임시 안내 · 기획 효과. dev_notes일 때만 창에 보인다)
##   motion(미리보기 종류) · radius · hits · amount(미리보기에 띄울 지금 값, 모르면 0)
## line · body · next · dev는 RichTextLabel용 BBCode다(plain()으로 글자만 뽑는다). 상태이상(기절 · 화상 · 도발 …)은 [url=id]로 감싸 굵게 —
## 창에서 누르면 뜻(UiText.STATUS_TERMS)이 뜬다. stats(그 코어 · 주인공의 능력치)를 주면 계산된 숫자를, 없으면(믹스 결과 미리보기) 계수만.

## 미리보기 종류: 액티브는 효과 종류 이름 그대로(strike · flurry …), 그 밖에는 아래 셋.
const MOTION_PASSIVE := "passive"
const MOTION_VARIANT := "variant"
const MOTION_INHERIT := "inherit"
## 적을 겨누는 효과(근접 · 원거리 꼬리표 · 사거리가 붙는다)
const AIMED := ["hit", "dash", "retreat", "pierce"]
## 다음 레벨 비교에 보이는 효과 값(계수 말고)
const NEXT_KEYS := ["amount", "attack", "speed", "guard", "vulnerable", "hp"]

## 개발 문구("수치는 임시" · "기획 효과")를 보이나(사용자 결정 2026-10-03: 개발 모드에서만). 디버그 화면에서 켠다.
static var dev_notes := GameConfig.DEV_SKILL_NOTES


# ─── 헨치 ────────────────────────────────────────

## 고유 액티브. stats가 null이면(믹스 결과 미리보기 등) 계산된 숫자 없이 계수만.
static func active(species: HenchSpecies, stats: UnitStats = null) -> Dictionary:
	var kind := species.skill
	var config: Dictionary = GameConfig.SKILL_KINDS.get(kind, {})
	var effects := hench_effects(kind, HenchSkill.skill_coefs(kind, species.active))
	var row: Dictionary = GameConfig.ROLE_STATS.get(species.role, GameConfig.ROLE_STATS["tank"])
	var reach := stats.attack_range if stats != null else float(row["attack_range"])
	var dev := UiText.SKILL_NOTE_ACTIVE
	var design := design_note(species.active)
	if design != "":
		dev += " " + UiText.TIP_DESIGN % link_terms(design)
	var sheet := _active_sheet(effects, stats, reach, reach, float(config.get("cooldown", 0.0)))
	sheet["title"] = HenchSkill.skill_title(species.active)
	sheet["tags"] = _with_first(sheet["tags"], UiText.TIP_TAG_HENCH_ACTIVE)
	sheet["dev"] = dev
	sheet["motion"] = kind
	return sheet


## 헨치 효과 종류(GameConfig.SKILL_KINDS) → 직업 스킬과 같은 효과 모양(문장 · 꼬리표를 함께 만든다).
static func hench_effects(kind: String, coefs: Dictionary) -> Array[Dictionary]:
	var c: Dictionary = GameConfig.SKILL_KINDS.get(kind, {})
	var list: Array[Dictionary] = []
	match kind:
		"strike":
			list.append({"type": "hit", "coefs": coefs})
		"flurry":
			list.append({"type": "hit", "coefs": coefs, "hits": int(c.get("hits", 1))})
		"blast":
			list.append({"type": "area", "at": "target", "coefs": coefs, "radius": float(c.get("radius", 0.0))})
		"stun":
			list.append({"type": "area", "at": "target", "coefs": coefs, "radius": float(c.get("radius", 0.0)), "stun": float(c.get("stun", 0.0))})
		"taunt":
			list.append({"type": "taunt", "radius": float(c.get("radius", 0.0))})
			list.append({"type": "shield", "who": "self", "amount": float(c.get("shield", 0.0)), "seconds": float(c.get("shield_seconds", 0.0))})
		"heal":
			list.append({"type": "heal", "who": "lowest", "coefs": coefs})
		"heal_all":
			list.append({"type": "heal", "who": "area", "coefs": coefs, "radius": float(c.get("radius", 0.0))})
	return list


## 패시브. holder = 패시브의 원래 주인 종(유산이면 주 코어의 종, 아니면 자기 종).
static func passive(species: HenchSpecies, holder: HenchSpecies) -> Dictionary:
	var legacy := holder != null and holder != species
	var source := holder if legacy else species
	var body := UiText.TIP_HENCH_PASSIVE % _b(source.passive)
	if legacy:
		body += " " + UiText.TIP_LEGACY_FROM % _b(source.name)
	return _info_sheet(source.passive, UiText.SKILL_TAG_LEGACY_SHORT if legacy else UiText.SKILL_TAG_PASSIVE, body, MOTION_PASSIVE, UiText.SKILL_NOTE_PASSIVE)


## 변이(돌연변이) 보정. 변이가 아니면 빈 내용.
static func variant(item: CoreItem) -> Dictionary:
	if not item.variant:
		return {}
	var bonus := roundi(GameConfig.VARIANT_STAT_BONUS * 100.0)
	var names := PackedStringArray()
	for stat: String in CoreStats.variant_stats(item):
		names.append(_c(stat_color(stat), SuffixDb.stat_name(stat)))
	var body := UiText.TIP_VARIANT % [UiText.LIST_SEPARATOR.join(names), _b("+%d%%" % bonus)]
	return _info_sheet(UiText.CHIP_VARIANT_TITLE % bonus, UiText.SKILL_TAG_VARIANT, body, MOTION_VARIANT, "")


## 믹스 계승 스탯(보조 코어에게서). 믹스로 태어나지 않았으면 빈 내용.
static func inherit(item: CoreItem) -> Dictionary:
	if not item.is_mix_born():
		return {}
	var value := UiText.SKILL_INHERIT_VALUE % [SuffixDb.stat_name(item.inherit_stat), item.inherit_value]
	var body := UiText.TIP_INHERIT % _b(_c(stat_color(item.inherit_stat), value))
	return _info_sheet(value, UiText.SKILL_TAG_INHERIT, body, MOTION_INHERIT, "")


## 꼬리표 맨 앞에 하나 더(PackedStringArray는 값으로 오가므로 새로 만들어 돌려준다).
static func _with_first(tags: PackedStringArray, first: String) -> PackedStringArray:
	var out := PackedStringArray([first])
	out.append_array(tags)
	return out


static func _info_sheet(title: String, tag: String, body: String, motion: String, dev: String) -> Dictionary:
	return {
		"title": title, "tags": PackedStringArray([tag]), "level": "", "level_state": "",
		"line": "", "body": body, "next": "", "dev": dev,
		"motion": motion, "radius": 0.0, "hits": 1, "amount": 0,
	}


# ─── 주인공 직업 스킬 ──────────────────────────────

## 직업 스킬(기획서 3장). level = 스킬 레벨(0 = 아직 안 배움 → 1레벨 값으로 보여 줌), stats = 주인공 능력치(없으면 숫자 없이 계수만),
## mods = 장착 패시브 보정(버프가 커진다), player_level = 주인공 레벨(안 배운 스킬이 "배울 수 있음"인지 "Lv n에 배움"인지).
## 배웠고 최고 레벨이 아니면 다음 레벨과 비교(계수 · 효과 값 · 재사용 대기)를 붙인다.
static func job_skill(skill: JobDb.Skill, level: int, stats: UnitStats = null, mods: Dictionary = {}, player_level := 0) -> Dictionary:
	var shown := maxi(level, 1)
	var level_text := UiText.TIP_LEVEL % [level, GameConfig.JOB_SKILL_MAX_LEVEL]
	var level_state := "learned"
	if level <= 0:
		level_state = "learnable" if player_level >= skill.unlock else "locked"
		level_text = (UiText.TIP_LEVEL_LEARNABLE if level_state == "learnable" else UiText.TIP_LEVEL_LOCKED) % skill.unlock
	var compare := level > 0 and level < GameConfig.JOB_SKILL_MAX_LEVEL
	var type_tag: String = UiText.JOB_TYPE_NAMES.get(skill.type, skill.type)
	var dev := (UiText.JOB_PASSIVE_NOTE if skill.is_passive() else UiText.JOB_ACTIVE_NOTE) + " " + UiText.TIP_DESIGN_DESC % skill.desc
	var sheet := {}
	if skill.is_passive():
		var now := JobRules.sum_mods([skill.id], {skill.id: shown})
		sheet = _info_sheet(skill.name, type_tag, UiText.TIP_PASSIVE_JOB % _mods_text(now), MOTION_PASSIVE, dev)
		if compare:
			sheet["next"] = _next_mods(now, JobRules.sum_mods([skill.id], {skill.id: level + 1}))
	else:
		var config := skill.config()
		var effects: Array[Dictionary] = []
		for raw: Dictionary in config.get("effects", []):
			effects.append(JobRules.scaled_effect(raw, shown, mods))
		var weapon: Dictionary = GameConfig.JOB_WEAPONS.get(skill.job_id, GameConfig.JOB_WEAPONS[GameConfig.START_JOB])
		var reach := stats.attack_range if stats != null else float(weapon["attack_range"])
		sheet = _active_sheet(effects, stats, reach, GameConfig.JOB_PARTY_RADIUS, JobRules.cooldown_at(float(config.get("cooldown", 0.0)), shown))
		sheet["title"] = skill.name
		sheet["tags"] = _with_first(sheet["tags"], type_tag)
		sheet["dev"] = dev
		sheet["motion"] = job_motion(effects[0]) if not effects.is_empty() else MOTION_PASSIVE
		if compare:
			sheet["next"] = _next_effects(config, level, mods)
	sheet["level"] = level_text
	sheet["level_state"] = level_state
	return sheet


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


# ─── 액티브 툴팁 ──────────────────────────────────

## 액티브 툴팁 몸통: 꼬리표(근접/원거리 · 단일/범위/자신) · 마나 · 재사용 · 사거리 줄 · 효과마다 문장 · 미리보기 값.
## reach = 시전자 사거리(겨누는 효과), heal_reach = 체력이 가장 낮은 동료를 찾는 거리.
static func _active_sheet(effects: Array[Dictionary], stats: UnitStats, reach: float, heal_reach: float, cooldown: float) -> Dictionary:
	var first: Dictionary = effects[0] if not effects.is_empty() else {}
	var tags := PackedStringArray()
	var aim := aim_reach(effects, reach)
	if aim > 0.0:
		tags.append(UiText.TIP_TAG_RANGED if aim > GameConfig.MELEE_RANGE_MAX else UiText.TIP_TAG_MELEE)
	tags.append(target_tag(first))
	var reach_text := UiText.TIP_REACH_SELF
	if aim > 0.0:
		reach_text = str(roundi(aim))
	elif first.get("type", "") == "heal" and first.get("who", "lowest") == "lowest":
		reach_text = str(roundi(heal_reach))
	var sentences := PackedStringArray()
	for effect in effects:
		sentences.append(effect_sentence(effect, stats))
	var line := UiText.TIP_LINE % [_b(str(mana_cost(cooldown))), _b(UiText.TIP_SECONDS % seconds(cooldown)), _b(reach_text)]
	return {
		"title": "", "tags": tags, "level": "", "level_state": "",
		"line": line, "body": " ".join(sentences), "next": "", "dev": "",
		"motion": "", "radius": float(first.get("radius", 0.0)), "hits": int(first.get("hits", 1)), "amount": _preview_amount(effects, stats),
	}


## 마나 소모(임시: 재사용 대기 × GameConfig.SKILL_MANA_PER_COOLDOWN — 아직 MP를 실제로 쓰지 않는다).
static func mana_cost(cooldown: float) -> int:
	return roundi(cooldown * GameConfig.SKILL_MANA_PER_COOLDOWN)


## 적을 겨누는 효과의 사거리(땅 위 px). 겨누는 효과가 없으면(자신 둘레 · 버프 · 회복) 0.
static func aim_reach(effects: Array[Dictionary], reach: float) -> float:
	var most := 0.0
	for effect in effects:
		var type := str(effect.get("type", ""))
		if type in AIMED or (type == "area" and effect.get("at", "target") == "target"):
			var own := float(effect.get("length", 0.0)) if type == "pierce" else float(effect.get("range", 0.0))
			most = maxf(most, own if own > 0.0 else reach)
	return most


## 대상 꼬리표: 하나만 = 단일, 여럿 = 범위, 나에게만 = 자신.
static func target_tag(effect: Dictionary) -> String:
	match str(effect.get("type", "")):
		"hit", "retreat":
			return UiText.TIP_TAG_SINGLE
		"dash":
			return UiText.TIP_TAG_AREA if float(effect.get("radius", 0.0)) > 0.0 else UiText.TIP_TAG_SINGLE
		"heal":
			return UiText.TIP_TAG_SINGLE if effect.get("who", "lowest") == "lowest" else UiText.TIP_TAG_AREA
		"shield", "buff":
			return UiText.TIP_TAG_SELF if effect.get("who", "self") == "self" else UiText.TIP_TAG_AREA
	return UiText.TIP_TAG_AREA


## 효과 하나의 설명 문장(BBCode).
static func effect_sentence(effect: Dictionary, stats: UnitStats) -> String:
	var coefs: Dictionary = effect.get("coefs", {})
	var radius := roundi(float(effect.get("radius", 0.0)))
	var kind := damage_word(coefs)
	var text := ""
	match str(effect.get("type", "")):
		"hit":
			var hits := int(effect.get("hits", 1))
			text = UiText.TIP_HIT_MULTI % [hits, amount_bb(coefs, stats), kind] if hits > 1 else UiText.TIP_HIT % [amount_bb(coefs, stats), kind]
		"area":
			text = (UiText.TIP_AREA_TARGET if effect.get("at", "target") == "target" else UiText.TIP_AREA_SELF) % [radius, amount_bb(coefs, stats), kind]
			if effect.has("stun"):
				text += " " + UiText.TIP_STUN % [_b(seconds(float(effect["stun"]))), term_bb("stun")]
			if effect.has("vulnerable"):
				text += " " + UiText.TIP_VULNERABLE % [_b(seconds(float(effect.get("seconds", 0.0)))), term_bb("vulnerable"), _b(_pct(float(effect["vulnerable"])))]
		"taunt":
			text = UiText.TIP_TAUNT % [radius, term_bb("taunt")]
		"shield":
			var share := float(effect.get("amount", 0.0))
			var shield := _c(stat_color("tough"), UiText.TIP_SHIELD_AMOUNT % _pct(share))
			if stats != null:
				shield = UiText.TIP_AMOUNT % [_b(str(roundi(stats.max_hp * share))), shield]
			text = UiText.TIP_SHIELD % [UiText.TIP_WHO.get(str(effect.get("who", "self")), ""), _b(seconds(float(effect.get("seconds", 0.0)))), shield, term_bb("shield")]
		"dash":
			var where := UiText.TIP_DASH_AREA % radius if radius > 0 else UiText.TIP_DASH_ONE
			text = UiText.TIP_DASH % [roundi(float(effect.get("range", 0.0))), where, amount_bb(coefs, stats), kind]
		"retreat":
			text = UiText.TIP_RETREAT % [amount_bb(coefs, stats), kind, roundi(float(effect.get("distance", 0.0)))]
		"pierce":
			text = UiText.TIP_PIERCE % [roundi(float(effect.get("length", 0.0))), roundi(float(effect.get("width", 0.0))), amount_bb(coefs, stats), kind]
		"smoke":
			text = UiText.TIP_SMOKE % [radius, _b(seconds(float(effect.get("seconds", 0.0)))), term_bb("stun")]
		"heal":
			if effect.get("who", "lowest") == "lowest":
				text = UiText.TIP_HEAL_LOWEST % amount_bb(coefs, stats, true)
			else:
				text = UiText.TIP_HEAL_AREA % [radius, amount_bb(coefs, stats, true)]
			if effect.get("cleanse", false):
				text += " " + UiText.TIP_CLEANSE % term_bb("stun")
		"revive":
			var count := int(effect.get("count", 1))
			var hp := _b(_pct(float(effect.get("hp", 0.5))))
			text = UiText.TIP_REVIVE % [count, hp] if count < GameConfig.PARTY_SIZE else UiText.TIP_REVIVE_ALL % hp
		"buff":
			var parts := PackedStringArray()
			for key: String in JobRules.BUFF_KEYS:
				if effect.has(key):
					parts.append(_b(str(UiText.JOB_BUFF_PARTS[key]).replace("%d", "%s") % _num(float(effect[key]) * 100.0)))
			text = UiText.TIP_BUFF % [UiText.TIP_WHO.get(str(effect.get("who", "self")), ""), _b(seconds(float(effect.get("seconds", 0.0)))), term_bb("buff"), UiText.LIST_SEPARATOR.join(parts)]
		"storm":
			text = UiText.TIP_STORM % [radius, int(effect.get("hits", 1)), amount_bb(coefs, stats), kind]
	return text


## 미리보기에 띄울 숫자(지금 한 번 값, 모르면 0): 피해 · 회복 계수가 있는 첫 효과, 없으면 보호막.
static func _preview_amount(effects: Array[Dictionary], stats: UnitStats) -> int:
	if stats == null:
		return 0
	for effect in effects:
		var coefs: Dictionary = effect.get("coefs", {})
		if not coefs.is_empty():
			return roundi(stats.skill_amount(coefs, effect.get("type", "") == "heal"))
	for effect in effects:
		if effect.get("type", "") == "shield":
			return roundi(stats.max_hp * float(effect.get("amount", 0.0)))
	return 0


# ─── 다음 레벨 비교 ───────────────────────────────

## 액티브 · 궁극기: 계수 · 효과 값 · 재사용 대기를 지금 레벨과 다음 레벨로 나란히("공격 143% → 157% · 재사용 10초 → 9.5초").
static func _next_effects(config: Dictionary, level: int, mods: Dictionary) -> String:
	var parts := PackedStringArray()
	for raw: Dictionary in config.get("effects", []):
		var now := JobRules.scaled_effect(raw, level, mods)
		var after := JobRules.scaled_effect(raw, level + 1, mods)
		var coefs: Dictionary = now.get("coefs", {})
		for stat: String in coefs:
			parts.append(UiText.TIP_NEXT_PART % [_c(stat_color(stat), SuffixDb.stat_name(stat)), _pct(float(coefs[stat])), _b(_pct(float(after["coefs"][stat])))])
		for key: String in NEXT_KEYS:
			if now.has(key) and not is_equal_approx(float(now[key]), float(after[key])):
				parts.append(UiText.TIP_NEXT_PART % [UiText.TIP_NEXT_NAMES.get(key, key), _pct(float(now[key])), _b(_pct(float(after[key])))])
	var base := float(config.get("cooldown", 0.0))
	var cool_now := JobRules.cooldown_at(base, level)
	var cool_after := JobRules.cooldown_at(base, level + 1)
	if not is_equal_approx(cool_now, cool_after):
		parts.append(UiText.TIP_NEXT_COOLDOWN % [seconds(cool_now), _b(seconds(cool_after))])
	return UiText.TIP_NEXT % UiText.LIST_SEPARATOR.join(parts) if not parts.is_empty() else ""


## 패시브: 보정마다 지금 → 다음("체력 +15% → +16.5%").
static func _next_mods(now: Dictionary, after: Dictionary) -> String:
	var parts := PackedStringArray()
	for key: String in now:
		var name: String = str(UiText.JOB_MOD_NAMES.get(key, key + " %d%%")).replace("%d", "%s")
		parts.append(UiText.TIP_ARROW % [name % _num(float(now[key]) * 100.0), _b(name % _num(float(after.get(key, 0.0)) * 100.0))])
	return UiText.TIP_NEXT % UiText.LIST_SEPARATOR.join(parts) if not parts.is_empty() else ""


static func _mods_text(mods: Dictionary) -> String:
	var parts := PackedStringArray()
	for key: String in mods:
		parts.append(_b(str(UiText.JOB_MOD_NAMES.get(key, key + " %d%%")).replace("%d", "%s") % _num(float(mods[key]) * 100.0)))
	return UiText.LIST_SEPARATOR.join(parts)


# ─── 글 조각 ─────────────────────────────────────

## 피해 · 회복 양: 능력치를 알면 "52(공격 143% + 방어 44%)", 모르면 계수만. 계수는 능력치 색.
static func amount_bb(coefs: Dictionary, stats: UnitStats, heal := false) -> String:
	var coef := coef_bb(coefs)
	if stats == null:
		return coef
	return UiText.TIP_AMOUNT % [_b(str(roundi(stats.skill_amount(coefs, heal)))), coef]


## 계수 BBCode: 능력치마다 그 색으로 "공격 143%"를 " + "로 잇는다.
static func coef_bb(coefs: Dictionary) -> String:
	var parts := PackedStringArray()
	for stat: String in coefs:
		parts.append(_c(stat_color(stat), UiText.TIP_COEF % [SuffixDb.stat_name(stat), _pct(float(coefs[stat]))]))
	return UiText.TIP_COEF_JOIN.join(parts)


## 계수 글(색 없이): {mighty: 1.8, precise: 0.8} → "공격 180% + 명중 80%".
static func coef_text(coefs: Dictionary) -> String:
	return plain(coef_bb(coefs))


## 마법 피해인가: 가장 큰 계수가 마나(충만)면 마법, 아니면 물리(임시 구분 — 방어 · 저항 계산은 아직 없다).
static func is_magic(coefs: Dictionary) -> bool:
	var top := ""
	var best := -1.0
	for stat: String in coefs:
		if float(coefs[stat]) > best:
			best = float(coefs[stat])
			top = stat
	return top == "abundant"


static func damage_word(coefs: Dictionary) -> String:
	return UiText.TIP_MAGIC if is_magic(coefs) else UiText.TIP_PHYSICAL


## 상태이상 낱말: 굵게 + 누르면 뜻(창의 RichTextLabel이 [url]을 받는다).
static func term_bb(id: String) -> String:
	var term: Array = UiText.STATUS_TERMS.get(id, [id, ""])
	return "[url=%s]%s[/url]" % [id, _b(_c(Palette.STATUS_TERM, str(term[0])))]


## 글 안의 상태이상 낱말(기절 · 화상 · 도발 …)을 term_bb로 바꾼다(도감 "기획 효과" 글처럼 그대로 들어온 글에).
static func link_terms(text: String) -> String:
	var out := text
	for id: String in UiText.STATUS_TERMS:
		out = out.replace(str(UiText.STATUS_TERMS[id][0]), term_bb(id))
	return out


## 능력치 색(사용자 결정 2026-10-03: 공격 = 주황, 마나 = 파랑, 방어 = 노랑, 체력 = 초록 …).
static func stat_color(stat: String) -> Color:
	return Palette.STAT_COLORS.get(stat, Palette.TEXT)


## BBCode를 걷어 낸 글자만.
static func plain(text: String) -> String:
	var tags := RegEx.create_from_string("\\[[^\\]]*\\]")
	return tags.sub(text, "", true)


## 도감 액티브 글의 괄호 안("매운 박치기 (공격 + 화상)" → "공격 + 화상"). 없으면 "".
static func design_note(active_text: String) -> String:
	var open := active_text.find(" (")
	if open < 0 or not active_text.ends_with(")"):
		return ""
	return active_text.substr(open + 2, active_text.length() - open - 3)


## 초를 짧게(8.0 → "8", 0.5 → "0.5", 6.65 → "6.7").
static func seconds(value: float) -> String:
	return _num(value)


## 비율 → 퍼센트 글(1.43 → "143%", 0.165 → "16.5%").
static func _pct(ratio: float) -> String:
	return _num(ratio * 100.0) + "%"


## 소수 한 자리까지, 끝의 ".0"은 뺀다(143.0 → "143", 16.5 → "16.5").
static func _num(value: float) -> String:
	return ("%.1f" % value).trim_suffix(".0")


static func _b(text: String) -> String:
	return "[b]%s[/b]" % text


static func _c(color: Color, text: String) -> String:
	return "[color=#%s]%s[/color]" % [color.to_html(false), text]

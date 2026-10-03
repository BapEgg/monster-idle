extends "res://tests/suite.gd"
## 주인공 직업 · 직업 스킬 테스트(기획서 3장): data/jobs.json, JobDb, JobRules, JobState, JobSkill, SkillSheet.job_skill.


## 기획서 3장: 직업 5종, 직업마다 MVP 액티브 5 · 패시브 2 · 궁극기 1, 해금 레벨(초안) 액티브 1·5·10·20·30 · 패시브 15·40 · 궁극기 25.
func test_job_data_matches_plan() -> void:
	var jobs := JobDb.ids()
	expect_true(jobs == ["warrior", "rogue", "archer", "healer", "buffer"], "직업 5종(전사 · 도적 · 궁수 · 힐러 · 버퍼)")
	for id in jobs:
		var job := JobDb.get_job(id)
		var actives := job.skills_of("active")
		var passives := job.skills_of("passive")
		var ultimates := job.skills_of("ultimate")
		expect_true(actives.size() == 5 and passives.size() == 2 and ultimates.size() == 1, "%s: 액티브 5 · 패시브 2 · 궁극기 1" % job.name)
		var unlocks := []
		for skill in actives:
			unlocks.append(skill.unlock)
		expect_true(unlocks == [1, 5, 10, 20, 30] and passives[0].unlock == 15 and passives[1].unlock == 40 and ultimates[0].unlock == 25, "%s: 해금 레벨이 기획서 초안대로" % job.name)
		expect_true(GameConfig.JOB_WEAPONS.has(id) and (GameConfig.JOB_BASE_STATS.get(id, {}) as Dictionary).keys() == Array(SuffixDb.ids()), "%s: 무기 · 능력치 9종(코어와 같은 순서)이 있다" % job.name)
		for skill in job.skills:
			var config := skill.config()
			if skill.is_passive():
				expect_true(config.has("mods") and not (config["mods"] as Dictionary).is_empty(), "%s: 패시브 보정 수치가 있다" % skill.name)
			else:
				expect_true(float(config.get("cooldown", 0.0)) > 0.0 and not (config.get("effects", []) as Array).is_empty(), "%s: 대기 시간 · 효과가 있다" % skill.name)
				expect_true(JobSkill.create(skill, 1) != null, "%s: 필드에서 쓸 수 있다" % skill.name)
				var tip := SkillSheet.job_skill(skill, 1)
				var sentence := SkillSheet.plain(tip["body"])
				expect_true(sentence.ends_with(".") and not sentence.contains("%") or sentence.contains("%"), "%s: 툴팁 설명 문장" % skill.name)
				expect_true(sentence.length() > 10 and SkillSheet.plain(tip["line"]) != "" and not sentence.contains("[") , "%s: 설명 문장 · 마나 · 재사용 · 사거리 줄 — %s" % [skill.name, sentence])
				for effect: Dictionary in config.get("effects", []):
					if str(effect["type"]) in ["hit", "area", "dash", "retreat", "pierce", "storm", "heal"]:
						var coefs: Dictionary = effect.get("coefs", {})
						var known := not coefs.is_empty()
						for stat: String in coefs:
							known = known and stat in SuffixDb.ids()
						expect_true(known, "%s: 피해 · 회복은 능력치 계수(9종 중)" % skill.name)


func test_points_slots_and_scaling() -> void:
	expect_true(JobRules.points_earned(1) == 0 and JobRules.points_earned(11) == 10 * GameConfig.JOB_SKILL_POINTS_PER_LEVEL, "스킬 포인트 = (레벨 − 1) × 레벨당 포인트")
	expect_true(JobRules.points_spent({"a": 1, "b": 4}) == 3, "배울 때의 레벨 1은 공짜")
	expect_true(JobRules.passive_slot_count(9) == 0 and JobRules.passive_slot_count(10) == 1 and JobRules.passive_slot_count(30) == 2, "패시브 칸: Lv 10 · 30에 하나씩")
	expect_near(JobRules.level_scale(1), 1.0, "스킬 레벨 1 = 그대로")
	expect_near(JobRules.level_scale(5), 1.0 + 4.0 * GameConfig.JOB_SKILL_LEVEL_BONUS, "스킬 레벨 5 = +4칸")
	var hit := JobRules.scaled_effect({"type": "hit", "coefs": {"mighty": 2.0, "precise": 0.5}, "range": 280.0}, 3)
	expect_near(float(hit["coefs"]["mighty"]), 2.0 * JobRules.level_scale(3), "계수는 스킬 레벨만큼 커진다")
	expect_near(float(hit["coefs"]["precise"]), 0.5 * JobRules.level_scale(3), "둘째 계수도 함께")
	expect_near(float(hit["range"]), 280.0, "사거리 · 범위 · 시간은 그대로")
	var buff := JobRules.scaled_effect({"type": "buff", "attack": 0.2, "seconds": 8.0}, 1, {"buff_power": 0.5, "buff_seconds": 0.25})
	expect_near(float(buff["attack"]), 0.3, "무대 체질: 버프 효과 +")
	expect_near(float(buff["seconds"]), 10.0, "앙코르: 버프 시간 +")
	var config_coefs: Dictionary = GameConfig.JOB_SKILLS["aimed_shot"]["effects"][0]["coefs"]
	JobRules.scaled_effect(GameConfig.JOB_SKILLS["aimed_shot"]["effects"][0], 5)
	expect_near(float(config_coefs["mighty"]), 1.8, "설정값(GameConfig)은 그대로 둔다(깊은 복사)")
	var guard := JobRules.scaled_effect({"type": "buff", "guard": 0.6}, 10, {"buff_power": 1.0})
	expect_near(float(guard["guard"]), JobRules.GUARD_CAP, "받는 피해 줄이기는 상한까지만")


## 사용자 결정(2026-10-03): 주인공도 코어와 같은 능력치 9종(장비가 나중에 이 값을 올린다), 전투 값은 코어와 같은 환산.
func test_player_sheet_and_stats() -> void:
	var base: Dictionary = GameConfig.JOB_BASE_STATS["warrior"]
	var scale := Growth.stat_scale(10)
	var sheet := JobRules.player_sheet("warrior", 10)
	expect_true(int(sheet["tough"]) == roundi(float(base["tough"]) * scale) and int(sheet["hp"]) == int(sheet["tough"]) * GameConfig.HP_PER_TOUGH, "능력치 = Lv 1 값 × 레벨 배율, HP = 체력 × %d" % GameConfig.HP_PER_TOUGH)
	expect_true(int(sheet["mp"]) == int(sheet["abundant"]) * GameConfig.MP_PER_ABUNDANT, "MP = 마나 × %d" % GameConfig.MP_PER_ABUNDANT)
	var stats := JobRules.player_stats("warrior", 10)
	expect_near(stats.max_hp, float(sheet["hp"]), "최대 체력 = HP")
	expect_near(stats.attack, float(sheet["mighty"]) * GameConfig.CORE_COMBAT_ATTACK_PER_MIGHTY, "공격력 = 공격 능력치 × 코어와 같은 환산")
	expect_true(stats.sheet == sheet, "전투 능력치에 능력치 표가 함께 있다(스킬 계수가 읽는다)")
	var half := GameConfig.CORE_COMBAT_SWIFT_HALF
	expect_near(stats.attack_interval, float(GameConfig.JOB_WEAPONS["warrior"]["attack_interval"]) * half / (half + float(sheet["swift"])), "공격 간격 = 무기 간격 × 공격 속도 환산")
	var healer := JobRules.player_sheet("healer", 10, {"heal_power": 0.2})
	expect_true(int(healer["abundant"]) == roundi(float(GameConfig.JOB_BASE_STATS["healer"]["abundant"]) * scale * 1.2), "왕진 가방: 마나 +20% → 회복 계수가 커진다")


func test_passive_mods_change_player_stats() -> void:
	var base := JobRules.player_stats("warrior", 10)
	var mods := JobRules.sum_mods(["iron_stance"], {"iron_stance": 1})
	var tough := JobRules.player_stats("warrior", 10, mods)
	var boosted := roundi(float(GameConfig.JOB_BASE_STATS["warrior"]["tough"]) * Growth.stat_scale(10) * (1.0 + float(GameConfig.JOB_SKILLS["iron_stance"]["mods"]["hp"])))
	expect_near(tough.max_hp, float(boosted * GameConfig.HP_PER_TOUGH), "철벽 자세: 체력 능력치 +")
	expect_true(tough.max_hp > base.max_hp, "철벽 자세: 최대 체력이 오른다")
	var nimble := JobRules.player_stats("rogue", 10, JobRules.sum_mods(["nimble_body"], {"nimble_body": 1}))
	expect_true(nimble.attack_interval < JobRules.player_stats("rogue", 10).attack_interval, "날렵한 몸놀림: 공격이 빨라진다")
	var archer := JobRules.player_stats("archer", 1)
	expect_true(archer.attack_range > GameConfig.MELEE_RANGE_MAX and JobRules.player_stats("warrior", 1).attack_range <= GameConfig.MELEE_RANGE_MAX, "궁수는 원거리(화살), 전사는 근접")


## 사용자 결정(2026-10-03): 처음 스킬만 처음부터 배우고, 나머지는 레벨이 닿으면 직업 창에서 "배우기".
func test_job_state_learn_equip_level() -> void:
	var state := JobState.new()
	expect_true(state.job_id == GameConfig.START_JOB, "처음 직업 = %s" % GameConfig.START_JOB)
	var learned := state.sync(1)
	expect_true(learned == ["shield_bash"] and state.actives[0] == "shield_bash", "Lv 1: 처음 스킬은 처음부터 배우고 바로 장착")
	expect_true(state.sync(12).is_empty() and not state.levels.has("war_cry"), "레벨이 올라도 저절로 배우지 않는다")
	expect_true(state.learnable(12) == ["war_cry", "shield_block"] and state.newly_learnable(1, 12) == ["war_cry", "shield_block"], "Lv 12: 배울 수 있는 스킬 = 도발 함성 · 방패 막기")
	expect_true(not state.can_learn("charge", 12) and not state.learn("charge", 12), "레벨이 모자라면 못 배움(돌진 충격 Lv 20)")
	expect_true(state.learn("war_cry", 12) and state.learn("shield_block", 12) and state.actives == ["shield_bash", "war_cry", "shield_block"], "배우면 빈 칸에 바로 장착")
	expect_true(not state.learn("war_cry", 12), "이미 배운 스킬은 다시 못 배움")
	for id in ["iron_stance", "fortress", "charge"]:
		state.learn(id, 26)
	expect_true(state.passives[0] == "iron_stance" and state.ultimate == "fortress" and state.levels.has("charge") and not state.is_equipped("charge"), "Lv 26: 패시브는 열린 칸에, 궁극기도 장착, 액티브 칸이 차면 배우기만")
	expect_true(state.points(26) == 25, "Lv 26 스킬 포인트 25(배우기는 포인트를 쓰지 않음)")
	expect_true(state.equip("charge", 1, 26) and state.actives == ["shield_bash", "charge", "shield_block"] and not state.is_equipped("war_cry"), "2번 칸에 돌진 충격 → 도발 함성은 빠짐")
	expect_true(state.equip("charge", 0, 26) and state.actives == ["charge", "shield_bash", "shield_block"], "장착한 스킬을 다른 칸에 → 두 칸이 자리를 바꾼다")
	expect_true(not state.equip("iron_stance", 1, 26), "Lv 26에는 패시브 2번 칸이 닫혀 있다")
	expect_true(not state.equip("double_slash", 0, 26), "다른 직업 스킬은 장착 못 함")
	expect_true(not state.equip("shield_throw", 0, 26), "아직 못 배운 스킬은 장착 못 함")
	expect_true(state.level_up("charge", 26) and state.skill_level("charge") == 2 and state.points(26) == 24, "스킬 레벨 올리기 → 포인트 1점")
	for i in 20:
		state.level_up("charge", 26)
	expect_true(state.skill_level("charge") == GameConfig.JOB_SKILL_MAX_LEVEL, "스킬 레벨 상한 %d" % GameConfig.JOB_SKILL_MAX_LEVEL)
	expect_true(state.unequip("charge") and state.actives[0] == "", "해제")
	var mods := state.mods(26)
	expect_true(mods.has("hp") and not mods.has("tank_damage_taken"), "장착한 패시브만 보정")


func test_job_state_save_and_change() -> void:
	var state := JobState.new()
	state.sync(26)
	for id in state.learnable(26):
		state.learn(id, 26)
	state.level_up("shield_bash", 26)
	state.equip("charge", 2, 26)
	var row: Dictionary = JSON.parse_string(JSON.stringify(state.to_dict()))
	var again := JobState.new()
	again.load_dict(row, 26)
	expect_true(again.to_dict() == state.to_dict(), "저장 → 다시 읽으면 같다")
	var broken := JobState.new()
	broken.load_dict({"job": "nope", "levels": {"double_slash": 3, "shield_bash": 99, "shield_throw": 1}, "actives": ["double_slash", "shield_bash", "shield_bash"]}, 5)
	expect_true(broken.job_id == GameConfig.START_JOB and not broken.levels.has("double_slash") and broken.skill_level("shield_bash") == GameConfig.JOB_SKILL_MAX_LEVEL, "없는 직업 · 다른 직업 스킬은 버리고, 레벨은 상한까지")
	expect_true(not broken.levels.has("shield_throw"), "레벨이 안 닿은 스킬(방패 던지기 Lv 30)은 버림")
	expect_true(broken.actives.count("shield_bash") == 1, "같은 스킬이 두 칸에 들어가지 않는다")
	expect_true(state.change_job("archer", 26) and state.levels.keys() == ["aimed_shot"] and state.actives[0] == "aimed_shot" and state.ultimate == "", "직업을 바꾸면(개발용) 처음 스킬만 다시 배움")


func test_job_skill_runtime_and_sheet() -> void:
	var skill := JobDb.get_skill("double_slash")
	var runtime := JobSkill.create(skill, 3)
	expect_true(runtime.title == "연속 베기" and runtime.cooldown > 0.0 and runtime.needs_enemy() and runtime.is_ready(), "연속 베기: 적을 때리는 스킬")
	expect_near(float(runtime.effects[0]["coefs"]["mighty"]), float(GameConfig.JOB_SKILLS["double_slash"]["effects"][0]["coefs"]["mighty"]) * JobRules.level_scale(3), "스킬 레벨 3 계수")
	runtime.use()
	expect_true(not runtime.is_ready() and runtime.wait_ratio() == 1.0, "쓰면 대기")
	expect_true(JobSkill.create(JobDb.get_skill("encore"), 1) == null, "패시브는 필드에서 쓰는 스킬이 아니다")
	expect_true(not JobSkill.create(JobDb.get_skill("courage_melody"), 1).needs_enemy(), "버프는 적이 없어도 쓴다")
	expect_near(JobRules.cooldown_at(10.0, 2), 9.5, "스킬 레벨 1당 재사용 대기 −5%(10초 → 9.5초)")
	expect_near(JobSkill.create(JobDb.get_skill("aimed_shot"), 3).cooldown, float(GameConfig.JOB_SKILLS["aimed_shot"]["cooldown"]) * (1.0 - 2.0 * GameConfig.JOB_SKILL_COOLDOWN_CUT), "필드 스킬도 레벨만큼 재사용 대기가 준다")
	var stats := UnitStats.new()
	stats.max_hp = 400.0
	stats.attack_range = 240.0
	stats.sheet = {"mighty": 20, "precise": 10}
	var sheet := SkillSheet.job_skill(JobDb.get_skill("aimed_shot"), 2, stats)
	expect_true(sheet["level"] == UiText.TIP_LEVEL % [2, GameConfig.JOB_SKILL_MAX_LEVEL] and sheet["level_state"] == "learned" and sheet["motion"] == "strike", "툴팁: Lv 2/%d · 강타 모션" % GameConfig.JOB_SKILL_MAX_LEVEL)
	expect_true(sheet["tags"] == PackedStringArray([UiText.JOB_TYPE_NAMES["active"], UiText.TIP_TAG_RANGED, UiText.TIP_TAG_SINGLE]), "꼬리표: 액티브 · 원거리 · 단일")
	var line := SkillSheet.plain(sheet["line"])
	var cool := JobRules.cooldown_at(float(GameConfig.JOB_SKILLS["aimed_shot"]["cooldown"]), 2)
	expect_true(line == UiText.TIP_LINE % [str(SkillSheet.mana_cost(cool)), UiText.TIP_SECONDS % SkillSheet.seconds(cool), "240"], "한 줄: 마나 · 재사용 대기(레벨 2) · 사거리 — %s" % line)
	# 조준 사격 = 공격 180% + 명중 80%, 스킬 레벨 2 → ×1.1 = 198% · 88%, 숫자 = (198% × 20 + 88% × 10) × 0.75
	var now := roundi((1.98 * 20.0 + 0.88 * 10.0) * GameConfig.SKILL_DAMAGE_PER_STAT)
	var body := SkillSheet.plain(sheet["body"])
	expect_true(body == UiText.TIP_HIT % ["%d(공격 198%% + 명중 88%%)" % now, UiText.TIP_PHYSICAL], "설명: \"대상 하나에게 %d(공격 198%% + 명중 88%%)의 물리 피해\" — %s" % [now, body])
	var next := SkillSheet.plain(sheet["next"])
	expect_true(next.contains("공격 198% → 216%") and next.contains("명중 88% → 96%") and next.contains(UiText.TIP_NEXT_COOLDOWN % [SkillSheet.seconds(cool), SkillSheet.seconds(JobRules.cooldown_at(float(GameConfig.JOB_SKILLS["aimed_shot"]["cooldown"]), 3))]), "다음 레벨 비교: 계수 · 재사용 — %s" % next)
	expect_true(SkillSheet.job_skill(JobDb.get_skill("aimed_shot"), GameConfig.JOB_SKILL_MAX_LEVEL, stats)["next"] == "" and SkillSheet.job_skill(JobDb.get_skill("aimed_shot"), 0, stats, {}, 1)["next"] == "", "최고 레벨 · 안 배운 스킬은 다음 레벨 비교 없음")
	var magic := SkillSheet.job_skill(JobDb.get_skill("dissonance"), 1, stats)
	var magic_body := SkillSheet.plain(magic["body"])
	expect_true(magic_body.contains(UiText.TIP_MAGIC) and magic_body.contains("약화") and magic["body"].contains("[url=vulnerable]") and magic_body.contains("6초"), "불협화음(마나 계수가 첫째) = 마법 피해 + 약화(6초 · 수치) — %s" % magic_body)
	var locked := SkillSheet.job_skill(JobDb.get_skill("sky_splitter"), 0)
	expect_true(locked["level"] == UiText.TIP_LEVEL_LOCKED % 25 and locked["level_state"] == "locked" and locked["tags"][0] == UiText.JOB_TYPE_NAMES["ultimate"], "못 배운 궁극기: \"Lv 25에 배움\"")
	expect_true(SkillSheet.job_skill(JobDb.get_skill("war_cry"), 0, null, {}, 10)["level_state"] == "learnable", "레벨은 됐는데 안 배움 = 배울 수 있음")
	var passive := SkillSheet.job_skill(JobDb.get_skill("iron_stance"), 1)
	expect_true(passive["motion"] == SkillSheet.MOTION_PASSIVE and SkillSheet.plain(passive["body"]).contains("체력 +15%") and SkillSheet.plain(passive["next"]).contains("체력 +15% → 체력 +16.5%"), "패시브: 보정 + 다음 레벨 — %s" % SkillSheet.plain(passive["next"]))
	expect_true(SkillSheet.plain(passive["dev"]).contains(JobDb.get_skill("iron_stance").desc), "개발 문구에 기획 설명")
	expect_true(SkillSheet.job_skill(JobDb.get_skill("protective_veil"), 1)["motion"] == "shield_all" and SkillSheet.job_skill(JobDb.get_skill("first_aid"), 1)["motion"] == "revive", "보호의 막 · 응급 처치 모션")

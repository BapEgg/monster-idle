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
		expect_true(GameConfig.JOB_STATS.has(id), "%s: 기본 능력치가 있다" % job.name)
		for skill in job.skills:
			var config := skill.config()
			if skill.is_passive():
				expect_true(config.has("mods") and not (config["mods"] as Dictionary).is_empty(), "%s: 패시브 보정 수치가 있다" % skill.name)
			else:
				expect_true(float(config.get("cooldown", 0.0)) > 0.0 and not (config.get("effects", []) as Array).is_empty(), "%s: 대기 시간 · 효과가 있다" % skill.name)
				expect_true(JobSkill.create(skill, 1) != null, "%s: 필드에서 쓸 수 있다" % skill.name)
				expect_true(not SkillSheet.job_skill(skill, 1).get("rows", []).is_empty(), "%s: 상세 창 계수 줄" % skill.name)


func test_points_slots_and_scaling() -> void:
	expect_true(JobRules.points_earned(1) == 0 and JobRules.points_earned(11) == 10 * GameConfig.JOB_SKILL_POINTS_PER_LEVEL, "스킬 포인트 = (레벨 − 1) × 레벨당 포인트")
	expect_true(JobRules.points_spent({"a": 1, "b": 4}) == 3, "배울 때의 레벨 1은 공짜")
	expect_true(JobRules.passive_slot_count(9) == 0 and JobRules.passive_slot_count(10) == 1 and JobRules.passive_slot_count(30) == 2, "패시브 칸: Lv 10 · 30에 하나씩")
	expect_near(JobRules.level_scale(1), 1.0, "스킬 레벨 1 = 그대로")
	expect_near(JobRules.level_scale(5), 1.0 + 4.0 * GameConfig.JOB_SKILL_LEVEL_BONUS, "스킬 레벨 5 = +4칸")
	var hit := JobRules.scaled_effect({"type": "hit", "power": 2.0, "range": 280.0}, 3)
	expect_near(float(hit["power"]), 2.0 * JobRules.level_scale(3), "배율은 스킬 레벨만큼 커진다")
	expect_near(float(hit["range"]), 280.0, "사거리 · 범위 · 시간은 그대로")
	var buff := JobRules.scaled_effect({"type": "buff", "attack": 0.2, "seconds": 8.0}, 1, {"buff_power": 0.5, "buff_seconds": 0.25})
	expect_near(float(buff["attack"]), 0.3, "무대 체질: 버프 효과 +")
	expect_near(float(buff["seconds"]), 10.0, "앙코르: 버프 시간 +")
	var heal := JobRules.scaled_effect({"type": "heal", "power": 2.0}, 1, {"heal_power": 0.2})
	expect_near(float(heal["power"]), 2.4, "왕진 가방: 회복 +")
	var guard := JobRules.scaled_effect({"type": "buff", "guard": 0.6}, 10, {"buff_power": 1.0})
	expect_near(float(guard["guard"]), JobRules.GUARD_CAP, "받는 피해 줄이기는 상한까지만")


func test_passive_mods_change_player_stats() -> void:
	var base := JobRules.player_stats("warrior", 10)
	var row: Dictionary = GameConfig.JOB_STATS["warrior"]
	expect_near(base.max_hp, float(row["hp"]) * Growth.stat_scale(10), "직업 기본 체력 × 레벨 배율")
	var mods := JobRules.sum_mods(["iron_stance"], {"iron_stance": 1})
	var tough := JobRules.player_stats("warrior", 10, mods)
	expect_near(tough.max_hp, base.max_hp * (1.0 + float(GameConfig.JOB_SKILLS["iron_stance"]["mods"]["hp"])), "철벽 자세: 최대 체력 +")
	var nimble := JobRules.player_stats("rogue", 10, JobRules.sum_mods(["nimble_body"], {"nimble_body": 1}))
	expect_true(nimble.attack_interval < JobRules.player_stats("rogue", 10).attack_interval, "날렵한 몸놀림: 공격이 빨라진다")
	var archer := JobRules.player_stats("archer", 1)
	expect_true(archer.attack_range > GameConfig.MELEE_RANGE_MAX and JobRules.player_stats("warrior", 1).attack_range <= GameConfig.MELEE_RANGE_MAX, "궁수는 원거리(화살), 전사는 근접")


func test_job_state_sync_equip_level() -> void:
	var state := JobState.new()
	expect_true(state.job_id == GameConfig.START_JOB, "처음 직업 = %s" % GameConfig.START_JOB)
	var learned := state.sync(1)
	expect_true(learned == ["shield_bash"] and state.actives[0] == "shield_bash", "Lv 1: 첫 액티브를 배우고 바로 장착")
	learned = state.sync(12)
	expect_true(learned == ["war_cry", "shield_block"] and state.actives == ["shield_bash", "war_cry", "shield_block"], "Lv 12: 액티브 둘을 더 배워 빈 칸에")
	state.sync(26)
	expect_true(state.levels.has("iron_stance") and state.passives[0] == "iron_stance" and state.ultimate == "fortress" and state.levels.has("charge") and not state.is_equipped("charge"), "Lv 26: 패시브는 열린 칸에, 궁극기도 장착, 액티브 칸이 차면 배우기만")
	expect_true(state.points(26) == 25, "Lv 26 스킬 포인트 25")
	expect_true(state.equip("charge", 1, 26) and state.actives == ["shield_bash", "charge", "shield_block"] and not state.is_equipped("war_cry"), "2번 칸에 돌진 충격 → 도발 함성은 빠짐")
	expect_true(state.equip("charge", 0, 26) and state.actives == ["charge", "", "shield_block"], "같은 스킬을 다른 칸에 → 옮겨 간다")
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
	state.level_up("shield_bash", 26)
	state.equip("charge", 2, 26)
	var row: Dictionary = JSON.parse_string(JSON.stringify(state.to_dict()))
	var again := JobState.new()
	again.load_dict(row, 26)
	expect_true(again.to_dict() == state.to_dict(), "저장 → 다시 읽으면 같다")
	var broken := JobState.new()
	broken.load_dict({"job": "nope", "levels": {"double_slash": 3, "shield_bash": 99}, "actives": ["double_slash", "shield_bash", "shield_bash"]}, 5)
	expect_true(broken.job_id == GameConfig.START_JOB and not broken.levels.has("double_slash") and broken.skill_level("shield_bash") == GameConfig.JOB_SKILL_MAX_LEVEL, "없는 직업 · 다른 직업 스킬은 버리고, 레벨은 상한까지")
	expect_true(broken.actives.count("shield_bash") == 1, "같은 스킬이 두 칸에 들어가지 않는다")
	expect_true(state.change_job("archer", 26) and state.levels.has("aimed_shot") and state.actives[0] == "aimed_shot" and not state.levels.has("shield_bash") and state.ultimate == "sky_splitter", "직업을 바꾸면(개발용) 처음부터 그 레벨까지 다시 배움")


func test_job_skill_runtime_and_sheet() -> void:
	var skill := JobDb.get_skill("double_slash")
	var runtime := JobSkill.create(skill, 3)
	expect_true(runtime.title == "연속 베기" and runtime.cooldown > 0.0 and runtime.needs_enemy() and runtime.is_ready(), "연속 베기: 적을 때리는 스킬")
	expect_near(float(runtime.effects[0]["power"]), float(GameConfig.JOB_SKILLS["double_slash"]["effects"][0]["power"]) * JobRules.level_scale(3), "스킬 레벨 3 배율")
	runtime.use()
	expect_true(not runtime.is_ready() and runtime.wait_ratio() == 1.0, "쓰면 대기")
	expect_true(JobSkill.create(JobDb.get_skill("encore"), 1) == null, "패시브는 필드에서 쓰는 스킬이 아니다")
	expect_true(not JobSkill.create(JobDb.get_skill("courage_melody"), 1).needs_enemy(), "버프는 적이 없어도 쓴다")
	var stats := UnitStats.new()
	stats.attack = 20.0
	stats.max_hp = 400.0
	var sheet := SkillSheet.job_skill(JobDb.get_skill("aimed_shot"), 2, stats)
	var power := float(GameConfig.JOB_SKILLS["aimed_shot"]["effects"][0]["power"]) * JobRules.level_scale(2)
	expect_true(sheet["rows"][0][1] == UiText.JOB_LEVEL_VALUE % [2, GameConfig.JOB_SKILL_MAX_LEVEL] and sheet["motion"] == "strike", "상세: 스킬 레벨 2/%d · 강타 모션" % GameConfig.JOB_SKILL_MAX_LEVEL)
	var damage := ""
	for row: Array in sheet["rows"]:
		if row[0] == UiText.SKILL_ROW_DAMAGE:
			damage = row[1]
	expect_true(damage == UiText.SKILL_POWER % roundi(power * 100.0) + UiText.SKILL_NOW % roundi(20.0 * power), "상세: 피해 = 공격력 × 배율 (지금 값) — %s" % damage)
	var locked := SkillSheet.job_skill(JobDb.get_skill("sky_splitter"), 0)
	expect_true(locked["rows"][0][1] == UiText.JOB_LEVEL_LOCKED % 25 and locked["tag"] == UiText.JOB_SKILL_TAG % ["궁수", "궁극기"], "못 배운 스킬: \"Lv 25에 배움\"")
	var passive := SkillSheet.job_skill(JobDb.get_skill("iron_stance"), 1)
	expect_true(passive["motion"] == SkillSheet.MOTION_PASSIVE and passive["rows"][1][1] == UiText.JOB_MOD_NAMES["hp"] % 15, "패시브: 보정 줄(최대 체력 +15%)")
	expect_true(SkillSheet.job_skill(JobDb.get_skill("protective_veil"), 1)["motion"] == "shield_all" and SkillSheet.job_skill(JobDb.get_skill("first_aid"), 1)["motion"] == "revive", "보호의 막 · 응급 처치 모션")

extends "res://tests/suite.gd"
## 스킬 기초 테스트: core/hench_skill.gd(효과 종류 · 대기 시간 · 범위), 도감의 skill, Combat.absorb(보호막),
## AutoControl.auto_skills(풀오토만 알아서 씀).


func test_every_species_has_a_known_skill() -> void:
	var all := HenchDb.parse(FileAccess.get_file_as_string(HenchDb.PATH))
	for s: HenchSpecies in all.values():
		var skill := HenchSkill.for_species(s)
		if s.grade == "king":
			expect_true(skill == null, "%s: 왕은 스킬 미정(없음)" % s.name)
			continue
		expect_true(skill != null and skill.cooldown > 0.0 and skill.title != "", "%s: 고유 액티브가 있다 (%s)" % [s.name, s.skill])
		if skill == null:
			continue
		# 역할 상식: 힐러는 회복 종류, 회복 종류는 힐러만
		expect_true(skill.is_heal() == (s.role == "healer"), "%s: 회복 스킬은 힐러만" % s.name)
	var gochu := HenchSkill.for_species(all["gochuryong"])
	expect_true(gochu.title == "매운 박치기" and gochu.kind == "strike", "고추룡 = 매운 박치기(강타)")
	expect_true((all["sotmabaem"] as HenchSpecies).skill == "taunt" and (all["dolguana"] as HenchSpecies).skill == "stun", "솥마뱀 = 도발+보호막, 돌구아나 = 기절")


func test_cooldown() -> void:
	var skill := HenchSkill.for_species(HenchDb.get_species("haemapo"))
	expect_true(skill.is_ready() and skill.wait_ratio() == 0.0, "처음에는 바로 쓸 수 있다")
	skill.use()
	expect_true(not skill.is_ready() and skill.wait_ratio() == 1.0, "쓰면 대기")
	skill.tick(skill.cooldown * 0.5)
	expect_near(skill.wait_ratio(), 0.5, "반쯤 지나면 덮개 절반")
	skill.tick(skill.cooldown)
	expect_true(skill.is_ready() and skill.left == 0.0, "대기가 끝나면 다시 쓸 수 있다(음수로 내려가지 않음)")
	expect_near(skill.cooldown, GameConfig.SKILL_KINDS["strike"]["cooldown"], "대기 시간 = 종류별 설정값")


func test_area() -> void:
	var points: Array[Vector2] = [Vector2(0, 0), Vector2(100, 0), Vector2(0, 40), Vector2(300, 0)]
	var inside := HenchSkill.indices_within(Vector2.ZERO, points, 110.0)
	expect_true(inside == ([0, 1, 2] as Array[int]), "범위 안: 화면 세로는 쿼터뷰 비율만큼 멀다(땅 위 거리) %s" % [inside])
	expect_true(HenchSkill.indices_within(Vector2.ZERO, points, 0.0) == ([0] as Array[int]), "범위 0 = 그 자리 하나")


func test_shield_absorbs_first() -> void:
	var r := Combat.absorb(30.0, 20.0)
	expect_true(r.x == 0.0 and r.y == 10.0, "보호막이 피해를 다 막으면 몸은 그대로")
	r = Combat.absorb(30.0, 50.0)
	expect_true(r.x == 20.0 and r.y == 0.0, "보호막보다 큰 피해는 넘친 만큼 몸에")
	r = Combat.absorb(0.0, 15.0)
	expect_true(r.x == 15.0 and r.y == 0.0, "보호막이 없으면 그대로")


func test_auto_skills_only_in_full_auto() -> void:
	var control := AutoControl.new(0.0)
	control.mode = AutoControl.Mode.FULL_AUTO
	expect_true(control.auto_skills(), "풀오토 = 스킬도 알아서")
	control.update(0.1, true)
	expect_true(control.auto_skills(), "풀오토에서 손대고 있어도 스킬은 알아서")
	control.mode = AutoControl.Mode.SEMI_AUTO
	expect_true(not control.auto_skills(), "세미오토(공격만 자동) = 스킬은 눌러서")
	control.mode = AutoControl.Mode.MANUAL
	expect_true(not control.auto_skills(), "수동 = 스킬은 눌러서")


func test_bad_skill_kind_is_detected() -> void:
	var s := HenchSpecies.from_dict({"id": "x", "name": "x", "tribe": "beast", "grade": "low", "role": "tank", "skill": "fireball"})
	expect_true(not s.problems().is_empty(), "모르는 스킬 종류는 데이터 오류로 잡힌다")


## 스킬 상세 창(SkillSheet, 사용자 결정 2026-10-03): 계수는 GameConfig.SKILL_KINDS 그대로, 지금 값은 전투 능력치로.
func test_skill_sheet_active() -> void:
	var gochu := HenchDb.get_species("gochuryong")
	var stats := UnitStats.new()
	stats.attack = 20.0
	stats.max_hp = 200.0
	var sheet := SkillSheet.active(gochu, stats)
	var power: float = GameConfig.SKILL_KINDS["strike"]["power"]
	expect_true(sheet["title"] == "매운 박치기" and sheet["motion"] == "strike" and sheet["description"] == UiText.SKILL_DESCRIPTIONS["strike"], "고추룡 = 매운 박치기, 강타 설명 · 강타 모션")
	expect_true(_row(sheet, UiText.SKILL_ROW_DAMAGE) == UiText.SKILL_POWER % roundi(power * 100.0) + UiText.SKILL_NOW % roundi(20.0 * power), "피해 = 공격력 × %d%% (지금 %d)" % [roundi(power * 100.0), roundi(20.0 * power)])
	expect_true(_row(sheet, UiText.SKILL_ROW_COOLDOWN) == UiText.SKILL_SECONDS % SkillSheet.seconds(GameConfig.SKILL_KINDS["strike"]["cooldown"]) and _row(sheet, UiText.SKILL_ROW_DESIGN) == "공격 + 화상", "재사용 대기 · 기획 효과(도감 괄호 안)")
	var preview := SkillSheet.active(gochu)
	expect_true(not _row(preview, UiText.SKILL_ROW_DAMAGE).contains("("), "능력치를 모르면(미리보기) 지금 값 없이 배율만")
	var flurry := SkillSheet.active(HenchDb.get_species("gyulbeom"), stats)
	var hits := int(GameConfig.SKILL_KINDS["flurry"]["hits"])
	expect_true(_row(flurry, UiText.SKILL_ROW_DAMAGE).contains("× %d번" % hits), "연타: 몇 번 때리나")
	var stun := SkillSheet.active(HenchDb.get_species("dolguana"), stats)
	expect_true(_row(stun, UiText.SKILL_ROW_RADIUS) == UiText.SKILL_RADIUS_VALUE % roundi(GameConfig.SKILL_KINDS["stun"]["radius"]) and _row(stun, UiText.SKILL_ROW_STUN) != "", "기절: 범위 · 기절 시간")
	var taunt := SkillSheet.active(HenchDb.get_species("sotmabaem"), stats)
	var share: float = GameConfig.SKILL_KINDS["taunt"]["shield"]
	expect_true(_row(taunt, UiText.SKILL_ROW_SHIELD).ends_with(UiText.SKILL_NOW % roundi(200.0 * share)), "도발: 보호막 = 최대 체력 × %d%%" % roundi(share * 100.0))
	stats.heal = 10.0
	var heal := SkillSheet.active(HenchDb.get_species("jinjuryong"), stats)
	expect_true(_row(heal, UiText.SKILL_ROW_HEAL).ends_with(UiText.SKILL_NOW % roundi(10.0 * float(GameConfig.SKILL_KINDS["heal"]["power"]))), "회복 = 회복력 × 배율")


func test_skill_sheet_passive_variant_inherit() -> void:
	var gochu := HenchDb.get_species("gochuryong")
	var own := SkillSheet.passive(gochu, gochu)
	expect_true(own["title"] == gochu.passive and own["tag"] == UiText.SKILL_TAG_PASSIVE and own["motion"] == SkillSheet.MOTION_PASSIVE, "자기 패시브")
	var turtle := HenchDb.get_species("kkangtonggeobuk")
	var legacy := SkillSheet.passive(gochu, turtle)
	expect_true(legacy["title"] == turtle.passive and legacy["tag"] == UiText.SKILL_TAG_LEGACY % turtle.name and _row(legacy, UiText.SKILL_ROW_FROM) == turtle.name, "유산 패시브: 원래 주인과 함께")
	var item := CoreItem.new()
	item.species_id = "haemapo"
	expect_true(SkillSheet.variant(item).is_empty() and SkillSheet.inherit(item).is_empty(), "보통 코어는 변이 · 계승 카드가 없다")
	item.variant = true
	var mutated := SkillSheet.variant(item)
	expect_true(_row(mutated, UiText.SKILL_ROW_STATS) == SuffixDb.stat_list(CoreStats.variant_stats(item)) and _row(mutated, UiText.SKILL_ROW_MIX) == UiText.SKILL_VARIANT_MIX, "변이: 오른 능력치 · 믹스 재료로 못 씀")
	var born := CoreItem.new()
	born.species_id = "dolguana"
	born.inherit_stat = "mighty"
	born.inherit_value = 6
	expect_true(SkillSheet.inherit(born)["title"] == UiText.SKILL_INHERIT_VALUE % [SuffixDb.stat_name("mighty"), 6], "믹스 계승: 공격 +6")
	expect_true(SkillSheet.design_note("물대포 (명중 비례)") == "명중 비례" and SkillSheet.design_note("물대포") == "", "도감 괄호 안 = 기획 효과")


func _row(sheet: Dictionary, caption: String) -> String:
	for row: Array in sheet.get("rows", []):
		if row[0] == caption:
			return row[1]
	return ""

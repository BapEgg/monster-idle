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


## 스킬 계수(기획서 4장 "스킬별 다중 스탯 계수", 사용자 결정 2026-10-03): 효과 종류의 계수 + 도감 설명의 "○○ 비례" 능력치.
func test_skill_coefficients() -> void:
	expect_true(HenchSkill.proportional_stat("물대포 (명중 비례)") == "precise" and HenchSkill.proportional_stat("새콤 할퀴기 (공속 비례 연타)") == "swift", "설명의 \"명중 비례\" → 명중, \"공속 비례\" → 공격 속도(공격보다 먼저 찾는다)")
	expect_true(HenchSkill.proportional_stat("뛰어들기 (체력 비례)") == "tough" and HenchSkill.proportional_stat("매운 박치기 (공격 + 화상)") == "", "체력 비례 → 체력, 비례가 없으면 없음")
	var strike: float = GameConfig.SKILL_KINDS["strike"]["coefs"]["mighty"]
	expect_true(HenchSkill.skill_coefs("strike", "물대포 (명중 비례)") == {"mighty": strike, "precise": GameConfig.SKILL_SECONDARY_COEF}, "물대포 = 공격 계수 + 명중 둘째 계수")
	expect_true(HenchSkill.skill_coefs("heal", "진주빛 치유 (마나 비례)") == GameConfig.SKILL_KINDS["heal"]["coefs"], "이미 있는 능력치(마나)는 더하지 않는다")
	expect_true(HenchSkill.skill_coefs("taunt", "솥뚜껑 막기 (방어 비례 보호막)").is_empty(), "피해 · 회복이 없는 도발은 계수 없음(보호막은 최대 체력 비율)")
	expect_near(Combat.skill_amount({"mighty": 2.0, "precise": 1.0}, {"mighty": 10.0, "precise": 4.0}), 24.0 * GameConfig.SKILL_DAMAGE_PER_STAT, "피해 = Σ 계수 × 능력치 × 환산값")
	expect_near(Combat.skill_amount({"abundant": 2.0}, {"abundant": 10.0}, true), 20.0 * GameConfig.SKILL_HEAL_PER_STAT, "회복은 회복 환산값")
	var plain := UnitStats.new()
	plain.attack = 15.0
	expect_near(plain.stat("mighty"), 15.0 / GameConfig.CORE_COMBAT_ATTACK_PER_MIGHTY, "능력치 표가 없으면 강력 = 공격력에서 거꾸로")
	expect_near(plain.stat("precise"), 0.0, "능력치 표가 없으면 나머지는 0")
	expect_near(plain.skill_amount({"mighty": 1.0}), 15.0 * GameConfig.SKILL_DAMAGE_PER_STAT / GameConfig.CORE_COMBAT_ATTACK_PER_MIGHTY, "공격 × 100% = 기본 공격 한 대만큼")
	expect_true(SkillSheet.is_magic({"abundant": 0.8, "mighty": 0.3}) and not SkillSheet.is_magic({"mighty": 1.8, "precise": 0.8}), "첫째(가장 큰) 계수가 마나면 마법 피해")
	expect_true(SkillSheet.coef_text({"mighty": 1.8, "precise": 0.8}) == "공격 180% + 명중 80%", "계수 글: 능력치 이름 n%를 +로 잇는다")
	var colored := SkillSheet.coef_bb({"mighty": 1.43, "sturdy": 0.44})
	expect_true(colored.contains(Palette.STAT_COLORS["mighty"].to_html(false)) and colored.contains(Palette.STAT_COLORS["sturdy"].to_html(false)), "계수는 능력치 색(공격 = 주황, 방어 = 노랑)")


## 스킬 툴팁(SkillSheet, 사용자 결정 2026-10-03: 롤 툴팁처럼) — 헨치 고유 스킬: 이름 + 꼬리표, 마나 · 재사용 · 사거리 줄,
## 계산된 숫자와 색 계수가 든 설명 문장, 상태이상은 굵게 + 누르면 뜻, 개발 문구는 따로.
func test_skill_sheet_active() -> void:
	var gochu := HenchDb.get_species("gochuryong")
	var stats := UnitStats.new()
	stats.max_hp = 200.0
	stats.attack_range = 56.0
	stats.sheet = {"mighty": 20, "precise": 10, "swift": 12, "abundant": 15}
	var sheet := SkillSheet.active(gochu, stats)
	var strike: float = GameConfig.SKILL_KINDS["strike"]["coefs"]["mighty"]
	var now := roundi(strike * 20.0 * GameConfig.SKILL_DAMAGE_PER_STAT)
	var cooldown: float = GameConfig.SKILL_KINDS["strike"]["cooldown"]
	expect_true(sheet["title"] == "매운 박치기" and sheet["motion"] == "strike" and int(sheet["amount"]) == now, "고추룡 = 매운 박치기, 강타 모션 · 미리보기 숫자 %d" % now)
	expect_true(sheet["tags"] == PackedStringArray([UiText.TIP_TAG_HENCH_ACTIVE, UiText.TIP_TAG_MELEE, UiText.TIP_TAG_SINGLE]) and sheet["level"] == "", "꼬리표: 고유 액티브 · 근접 · 단일(헨치 스킬은 레벨 없음)")
	expect_true(SkillSheet.plain(sheet["line"]) == UiText.TIP_LINE % [str(SkillSheet.mana_cost(cooldown)), UiText.TIP_SECONDS % SkillSheet.seconds(cooldown), "56"], "한 줄: 마나 · 재사용 대기 · 사거리 — %s" % SkillSheet.plain(sheet["line"]))
	var body := SkillSheet.plain(sheet["body"])
	expect_true(body == UiText.TIP_HIT % ["%d(공격 %d%%)" % [now, roundi(strike * 100.0)], UiText.TIP_PHYSICAL], "설명 문장 안에 숫자(계수): %s" % body)
	expect_true(SkillSheet.plain(sheet["dev"]).contains("공격 + 화상") and sheet["dev"].contains("[url=burn]"), "개발 문구에 기획 효과, 화상은 굵게 + 누르면 뜻")
	var preview := SkillSheet.active(gochu)
	expect_true(SkillSheet.plain(preview["body"]) == UiText.TIP_HIT % ["공격 %d%%" % roundi(strike * 100.0), UiText.TIP_PHYSICAL] and int(preview["amount"]) == 0, "능력치를 모르면(미리보기) 숫자 없이 계수만")
	var water := SkillSheet.active(HenchDb.get_species("haemapo"), stats)
	var water_now := roundi((strike * 20.0 + GameConfig.SKILL_SECONDARY_COEF * 10.0) * GameConfig.SKILL_DAMAGE_PER_STAT)
	expect_true(SkillSheet.plain(water["body"]).contains("%d(공격 %d%% + 명중 %d%%)" % [water_now, roundi(strike * 100.0), roundi(GameConfig.SKILL_SECONDARY_COEF * 100.0)]), "물대포(명중 비례): 공격 + 명중 계수 — %s" % SkillSheet.plain(water["body"]))
	var flurry := SkillSheet.active(HenchDb.get_species("gyulbeom"), stats)
	var hits := int(GameConfig.SKILL_KINDS["flurry"]["hits"])
	expect_true(SkillSheet.plain(flurry["body"]).contains("%d번" % hits) and SkillSheet.plain(flurry["body"]).contains("공격 속도 "), "연타(공속 비례): 몇 번 · 공격 속도 계수")
	var stun := SkillSheet.active(HenchDb.get_species("dolguana"), stats)
	var stun_body := SkillSheet.plain(stun["body"])
	expect_true(stun_body.contains("반지름 %d" % roundi(GameConfig.SKILL_KINDS["stun"]["radius"])) and stun_body.contains("%s초 동안 기절" % SkillSheet.seconds(GameConfig.SKILL_KINDS["stun"]["stun"])) and stun["body"].contains("[url=stun]"), "기절: 범위 · 지속 시간, 기절은 굵게 + 누르면 뜻 — %s" % stun_body)
	expect_true(stun["tags"].has(UiText.TIP_TAG_AREA), "기절(범위) 꼬리표 = 범위")
	var taunt := SkillSheet.active(HenchDb.get_species("sotmabaem"), stats)
	var share: float = GameConfig.SKILL_KINDS["taunt"]["shield"]
	var taunt_body := SkillSheet.plain(taunt["body"])
	expect_true(taunt_body.contains("도발") and taunt_body.contains("%d(최대 체력 %d%%)" % [roundi(200.0 * share), roundi(share * 100.0)]) and taunt["body"].contains("[url=taunt]") and SkillSheet.plain(taunt["line"]).ends_with(UiText.TIP_REACH_SELF), "도발: 도발 + 보호막(최대 체력 %d%%), 사거리 = 자신 — %s" % [roundi(share * 100.0), taunt_body])
	var heal := SkillSheet.active(HenchDb.get_species("jinjuryong"), stats)
	var heal_coef: float = GameConfig.SKILL_KINDS["heal"]["coefs"]["abundant"]
	expect_true(SkillSheet.plain(heal["body"]) == UiText.TIP_HEAL_LOWEST % ("%d(마나 %d%%)" % [roundi(heal_coef * 15.0 * GameConfig.SKILL_HEAL_PER_STAT), roundi(heal_coef * 100.0)]), "회복 = 마나 계수 — %s" % SkillSheet.plain(heal["body"]))
	expect_true(SkillSheet.plain(SkillSheet.link_terms("공격 + 화상")) == "공격 + 화상" and not SkillSheet.dev_notes, "상태이상 링크를 걷으면 글 그대로, 개발 문구는 처음엔 꺼짐")


func test_skill_sheet_passive_variant_inherit() -> void:
	var gochu := HenchDb.get_species("gochuryong")
	var own := SkillSheet.passive(gochu, gochu)
	expect_true(own["title"] == gochu.passive and own["tags"] == PackedStringArray([UiText.SKILL_TAG_PASSIVE]) and own["motion"] == SkillSheet.MOTION_PASSIVE and own["line"] == "", "자기 패시브(마나 · 재사용 줄 없음)")
	var turtle := HenchDb.get_species("kkangtonggeobuk")
	var legacy := SkillSheet.passive(gochu, turtle)
	expect_true(legacy["title"] == turtle.passive and legacy["tags"] == PackedStringArray([UiText.SKILL_TAG_LEGACY_SHORT]) and SkillSheet.plain(legacy["body"]).contains(turtle.name), "유산 패시브: 원래 주인과 함께")
	var item := CoreItem.new()
	item.species_id = "haemapo"
	expect_true(SkillSheet.variant(item).is_empty() and SkillSheet.inherit(item).is_empty(), "보통 코어는 변이 · 계승 카드가 없다")
	item.variant = true
	var mutated := SkillSheet.variant(item)
	var first_stat: String = CoreStats.variant_stats(item)[0]
	expect_true(SkillSheet.plain(mutated["body"]).contains(SuffixDb.stat_name(first_stat)) and SkillSheet.plain(mutated["body"]).contains("+%d%%" % roundi(GameConfig.VARIANT_STAT_BONUS * 100.0)), "변이: 오른 능력치 · 보정")
	var born := CoreItem.new()
	born.species_id = "dolguana"
	born.inherit_stat = "mighty"
	born.inherit_value = 6
	expect_true(SkillSheet.inherit(born)["title"] == UiText.SKILL_INHERIT_VALUE % [SuffixDb.stat_name("mighty"), 6] and SkillSheet.plain(SkillSheet.inherit(born)["body"]).contains("공격 +6"), "믹스 계승: 공격 +6")
	expect_true(SkillSheet.design_note("물대포 (명중 비례)") == "명중 비례" and SkillSheet.design_note("물대포") == "", "도감 괄호 안 = 기획 효과")

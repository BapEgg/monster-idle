extends "res://tests/suite.gd"
## core/hench_db.gd 테스트: data/henches.json이 기획서 도감과 맞는지, 잘못된 데이터를 걸러내는지.


func test_real_data_matches_plan() -> void:
	var all := HenchDb.parse(FileAccess.get_file_as_string(HenchDb.PATH))
	# 기획서 5장 용족 하급 4종: 이름, 역할, 레벨대
	var expected := {
		"sotmabaem": ["솥마뱀", "tank", 1, 10],
		"gochuryong": ["고추룡", "melee", 3, 12],
		"haemapo": ["해마포", "ranged", 5, 14],
		"jinjuryong": ["진주룡", "healer", 7, 16],
	}
	for id: String in expected:
		var s: HenchSpecies = all.get(id)
		expect_true(s != null, "%s 있음" % id)
		if s == null:
			continue
		var row: Array = expected[id]
		expect_true(s.name == row[0], "%s 이름 = %s" % [id, row[0]])
		expect_true(s.role == row[1], "%s 역할 = %s" % [id, row[1]])
		expect_true(s.level_min == row[2] and s.level_max == row[3], "%s 레벨 %d~%d" % [id, row[2], row[3]])
		expect_true(s.tribe == "dragon" and s.grade == "low", "%s 용족 하급" % id)


## 기획서 5~6장: 64종 = 8종족 × (하급 4 · 중급 2 · 상급 1 · 왕 1), 하급은 종족마다 4역할이 다 있다.
func test_all_64_species() -> void:
	var all := HenchDb.parse(FileAccess.get_file_as_string(HenchDb.PATH))
	expect_true(all.size() == 64, "64종 (실제 %d)" % all.size())
	for tribe: String in HenchSpecies.TRIBES:
		var grades := {"low": 0, "mid": 0, "high": 0, "king": 0}
		var low_roles := {}
		for s: HenchSpecies in all.values():
			if s.tribe != tribe:
				continue
			grades[s.grade] += 1
			if s.grade == "low":
				low_roles[s.role] = true
		expect_true(grades == {"low": 4, "mid": 2, "high": 1, "king": 1}, "%s: 하급 4 · 중급 2 · 상급 1 · 왕 1" % tribe)
		expect_true(low_roles.size() == 4, "%s: 하급에 4역할" % tribe)
		expect_true(TribeDb.get_tribe(tribe) != null, "%s: 종족 데이터(색·그림 경로)가 있다" % tribe)


## 믹스 공식: 하급은 드랍(공식 없음), 중급은 2개, 상급은 1개, 왕은 비밀(비어 있음). 공식의 종은 모두 있어야 한다.
func test_recipes() -> void:
	var all := HenchDb.parse(FileAccess.get_file_as_string(HenchDb.PATH))
	var expected := {"low": 0, "mid": 2, "high": 1, "king": 0}
	for s: HenchSpecies in all.values():
		expect_true(s.recipes.size() == expected[s.grade], "%s(%s): 공식 %d개" % [s.name, s.grade, expected[s.grade]])
		for pair in s.recipes:
			expect_true(all.has(pair[0]) and all.has(pair[1]), "%s: 공식의 종 %s · %s가 도감에 있다" % [s.name, pair[0], pair[1]])
	var dolguana: HenchSpecies = all["dolguana"]
	expect_true(dolguana.recipes[0] == PackedStringArray(["sotmabaem", "gombogom"]), "돌구아나 = 솥마뱀 + 곰보곰 (기획서 5장)")
	expect_true(dolguana.recipes[1] == PackedStringArray(["gochuryong", "kkangtonggeobuk"]), "돌구아나 = 고추룡 + 깡통거북")


## 사용자 결정(2026-10-03): 공식 [A, B] = 주 A · 보조 B, 반대 방향 [B, A]는 다른 공식.
## 기획서에 없는 반대 방향은 초안(draft_recipes): 주 코어(B) 종족의 같은 등급 종, 같은 역할이 있으면 그 종.
func test_draft_recipes() -> void:
	var all := HenchDb.parse(FileAccess.get_file_as_string(HenchDb.PATH))
	var official := {}
	var drafts := {}
	for s: HenchSpecies in all.values():
		for pair in s.recipes:
			expect_true(not official.has(pair[0] + "|" + pair[1]), "공식 %s + %s가 한 번만 나온다" % [pair[0], pair[1]])
			official[pair[0] + "|" + pair[1]] = s
		for pair in s.draft_recipes:
			expect_true(all.has(pair[0]) and all.has(pair[1]), "%s: 초안 공식의 종 %s · %s가 도감에 있다" % [s.name, pair[0], pair[1]])
			drafts[pair[0] + "|" + pair[1]] = s
	for key: String in drafts:
		expect_true(not official.has(key), "초안 %s가 기획서 공식과 겹치지 않는다" % key)
	for key: String in official:
		var pair := key.split("|")
		var reverse := pair[1] + "|" + pair[0]
		if official.has(reverse):
			continue
		expect_true(drafts.has(reverse), "기획서 공식 %s의 반대 방향 초안이 있다" % key)
		if not drafts.has(reverse):
			continue
		var original: HenchSpecies = official[key]
		var draft: HenchSpecies = drafts[reverse]
		var main: HenchSpecies = all[pair[1]]
		expect_true(draft.tribe == main.tribe and draft.grade == original.grade, "%s: 주 코어 종족 · 원래 결과와 같은 등급" % reverse)
		var same_role := false
		for s: HenchSpecies in all.values():
			same_role = same_role or (s.tribe == main.tribe and s.grade == original.grade and s.role == original.role)
		if same_role:
			expect_true(draft.role == original.role, "%s: 같은 역할이 있으면 그 종" % reverse)
	expect_true(HenchDb.recipe_result("kkangtonggeobuk", "gochuryong") == "gigwankokkiri" and HenchDb.is_draft_recipe("kkangtonggeobuk", "gochuryong"), "주 깡통거북 + 보조 고추룡 = 기관코끼리(초안)")


## 기획서 4장 초안: 하급은 종족당 근접딜러 1종 정도가 선공 → 용섬 입문은 고추룡만.
func test_aggressive_species() -> void:
	var all := HenchDb.parse(FileAccess.get_file_as_string(HenchDb.PATH))
	expect_true((all["gochuryong"] as HenchSpecies).aggressive, "고추룡(근접딜러)은 선공")
	for id: String in ["sotmabaem", "haemapo", "jinjuryong"]:
		expect_true(not (all[id] as HenchSpecies).aggressive, "%s는 비선공" % id)
	var missing := HenchSpecies.from_dict({"id": "x", "name": "x", "tribe": "beast", "grade": "low", "role": "tank"})
	expect_true(not missing.aggressive, "선공 칸이 없으면 비선공")


func test_config_ids_exist() -> void:
	for id: String in [GameConfig.BOSS_SPECIES]:
		expect_true(HenchDb.get_species(id) != null, "설정의 %s가 데이터에 있음" % id)
	expect_true(GameConfig.FOLLOW_SLOTS.size() >= GameConfig.PARTY_SIZE, "파티 수만큼 따라다닐 자리가 있음")


func test_bad_rows_are_detected() -> void:
	var text := JSON.stringify({"henches": [
		{"id": "ok", "name": "좋음", "tribe": "beast", "grade": "low", "role": "tank", "level": [1, 5]},
		{"id": "bad", "name": "나쁨", "tribe": "robot", "grade": "low", "role": "tank", "level": [1, 5]},
	]})
	var species := HenchSpecies.from_dict(JSON.parse_string(text)["henches"][1])
	expect_true(not species.problems().is_empty(), "모르는 종족은 문제로 잡힌다")
	expect_true(HenchSpecies.from_dict(JSON.parse_string(text)["henches"][0]).problems().is_empty(), "올바른 칸은 문제없음")

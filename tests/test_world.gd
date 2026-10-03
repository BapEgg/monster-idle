extends "res://tests/suite.gd"
## 섬 · 지역 테스트(기획서 7장: 8섬 × 3지역 입문 · 특수 · 심장부, 패배하면 이전 지역으로 후퇴): data/islands.json, IslandDb, WorldState.


func test_island_data() -> void:
	var islands := IslandDb.islands()
	expect_true(islands.size() == 8 and IslandDb.regions().size() == 3, "8섬 × 3지역")
	expect_true(IslandDb.start_island() == "dragon" and IslandDb.first_region() == "intro", "처음 = 용섬 입문")
	var names := PackedStringArray()
	for island in islands:
		names.append(island.name)
		expect_true(TribeDb.get_tribe(island.tribe) != null, "%s: 종족이 있다" % island.name)
		expect_true(IslandDb.king(island.id) != null, "%s: 섬의 왕이 있다(%s)" % [island.name, IslandDb.king(island.id).name if IslandDb.king(island.id) != null else "-"])
		for region in IslandDb.regions():
			expect_true(not IslandDb.spawn_table(island.id, region.id).is_empty(), "%s %s: 나오는 종이 있다" % [island.name, region.name])
	expect_true(IslandDb.king("dragon").id == "mireu", "용섬의 왕 = 미르")
	# 도감의 모든 서식지가 어떤 섬 · 지역과 맞는다(섬의 왕 빼고)
	var keys := {}
	for island in islands:
		for region in IslandDb.regions():
			keys[IslandDb.habitat_key(island.id, region.id)] = true
	for species: HenchSpecies in HenchDb.all().values():
		if species.grade == "king":
			continue
		for habitat in species.habitats:
			expect_true(keys.has(habitat), "%s의 서식지 \"%s\"가 섬 · 지역에 있다" % [species.name, habitat])


func test_spawn_tables() -> void:
	var intro := IslandDb.spawn_table("dragon", "intro")
	var ids := PackedStringArray()
	for row: Array in intro:
		ids.append(row[0])
	expect_true(ids == PackedStringArray(["sotmabaem", "gochuryong", "haemapo", "jinjuryong", "kkangtonggeobuk"]), "용섬 입문 = 솥마뱀 · 고추룡 · 해마포 · 진주룡 · 깡통거북(기계섬 하급도 서식지에 있음)")
	var heart := IslandDb.spawn_table("dragon", "heart")
	var weights := {}
	for row: Array in heart:
		weights[row[0]] = row[1]
	expect_true(weights.get("dolguana", 0.0) == 1.0 and weights.get("mungeimugi", 0.0) == 1.0 and is_equal_approx(weights.get("beomjongryong", 0.0), GameConfig.HEART_RARE_WEIGHT), "용섬 심장부 = 특수 종(흔함) + 범종룡(드묾)")
	expect_true(IslandDb.pick_species(heart, 0.0) == "dolguana" and IslandDb.pick_species(heart, 0.999) == "beomjongryong", "비중대로 고른다(끝 = 드문 심장부 종)")
	expect_true(IslandDb.pick_species([], 0.5) == "", "빈 표 = 없음")


func test_levels_open_and_retreat() -> void:
	expect_true(IslandDb.level_range("dragon", "intro") == Vector2i(1, 15) and IslandDb.level_range("dragon", "special") == Vector2i(15, 40) and IslandDb.level_range("dragon", "heart") == Vector2i(35, 60), "지역 레벨: 입문 1~15 · 특수 15~40 · 심장부 35~60(기획서 초안)")
	var dolguana := HenchDb.get_species("dolguana")
	expect_true(IslandDb.wild_level(dolguana, CoreItem.Age.ADULT, Vector2i(35, 60)) == 35, "특수 종이 심장부에 나오면 심장부 레벨대 아래 끝으로")
	expect_true(IslandDb.wild_level(HenchDb.get_species("gochuryong"), CoreItem.Age.ADULT, Vector2i(1, 15)) == Drops.wild_level(HenchDb.get_species("gochuryong"), CoreItem.Age.ADULT), "레벨대 안이면 그대로")
	expect_true(IslandDb.is_region_open("dragon", "intro", 1) and not IslandDb.is_region_open("dragon", "special", 14) and IslandDb.is_region_open("dragon", "special", 15), "지역은 레벨대 아래 끝에 닿으면 열린다(임시)")
	expect_true(IslandDb.retreat_region("heart") == "special" and IslandDb.retreat_region("special") == "intro" and IslandDb.retreat_region("intro") == "intro", "패배: 심장부 → 특수 → 입문, 입문은 그대로")
	var parsed := IslandDb.parse(JSON.stringify({"regions": [{"id": "intro", "name": "입문", "level": [1, 15]}], "islands": [{"id": "x", "name": "엑스섬", "tribe": "dragon", "levels": {"intro": [5, 20]}}]}))
	expect_true(parsed.islands[0].levels["intro"] == Vector2i(5, 20) and parsed.start == "x", "섬마다 레벨대를 덮어쓸 수 있다(흩어진 레벨 지도)")
	expect_true(IslandDb.field_seed("dragon", "intro") != IslandDb.field_seed("dragon", "special") and IslandDb.field_seed("dragon", "intro") == IslandDb.field_seed("dragon", "intro"), "필드 배치는 섬 · 지역마다 다르고 같은 곳이면 같다")


func test_world_state() -> void:
	WorldState.dev_open_all = false
	var world := WorldState.new()
	expect_true(world.island == "dragon" and world.region == "intro" and world.is_island_open("dragon") and not world.is_island_open("plant"), "처음: 용섬 입문, 용섬만 열림")
	expect_true(not world.can_enter("dragon", "special", 10) and world.can_enter("dragon", "special", 20) and not world.can_enter("plant", "intro", 60), "특수는 Lv 15부터, 닫힌 섬은 못 감")
	expect_true(not world.can_enter("dragon", "intro", 20), "지금 있는 곳으로는 이동하지 않는다")
	world.move_to("dragon", "heart")
	expect_true(world.retreat() and world.region == "special" and world.retreat() and world.region == "intro" and not world.retreat(), "패배하면 한 지역씩 후퇴, 입문에서는 그대로")
	WorldState.dev_open_all = true
	expect_true(world.can_enter("demon", "intro", 1), "개발용: 모든 섬 열기")
	WorldState.dev_open_all = false
	world.opened.append("plant")
	world.move_to("plant", "special")
	var again := WorldState.new()
	again.load_dict(JSON.parse_string(JSON.stringify(world.to_dict())))
	expect_true(again.island == "plant" and again.region == "special" and again.is_island_open("plant"), "저장 → 다시 읽으면 그대로")
	var broken := WorldState.new()
	broken.load_dict({"island": "demon", "region": "nope", "opened": ["nope", "demon"]})
	expect_true(broken.island == "dragon" and broken.region == "intro" and broken.is_island_open("demon") and broken.opened.size() == 2, "없는 지역이면 처음 섬 입문, 없는 섬 id는 버림")
	var not_open := WorldState.new()
	not_open.load_dict({"island": "flying", "region": "intro", "opened": []})
	expect_true(not_open.island == "dragon", "열리지 않은 섬에 있던 저장은 처음 섬으로")

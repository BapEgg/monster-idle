class_name IslandDb
extends RefCounted
## 섬 · 지역 데이터(data/islands.json, 기획서 7장: 8섬 × 3지역 입문 · 특수 · 심장부)와 지역 규칙(순수 함수).
## - 지역에 나오는 종 = 도감 서식지(habitats)가 "섬 이름 + 지역 이름"(예: "용섬 입문")인 종.
##   심장부는 그 섬 특수 지역의 종이 흔히 나오고, 심장부 종(상급)은 드물게 나온다(GameConfig.HEART_RARE_WEIGHT, 기획서 "상급 = 심장부 희귀").
## - 야생 레벨 = 종의 출현 레벨(Drops.wild_level)을 지역 레벨대 안으로 맞춘 값.
## - 지역은 주인공 레벨이 그 지역 레벨대의 아래 끝에 닿으면 열린다(임시). 섬은 처음 섬만 열려 있다(섬 개방은 다음 단계).
## - 패배하면 그 섬의 바로 앞 지역으로 후퇴한다(기획서 7장 "패배 시 페널티 없이 이전 지역 후퇴"). 입문이면 그 자리.
## 주의: 안드로이드로 내보낼 때 내보내기 설정의 "리소스가 아닌 파일" 필터에 *.json 을 넣어야 함께 들어간다.

const PATH := "res://data/islands.json"


class Region:
	var id := ""
	var name := ""
	## 레벨대(아래 끝 = 열리는 레벨)
	var level := Vector2i(1, 1)
	## 지역 차례(0 = 입문)
	var index := 0


class Island:
	var id := ""
	var name := ""
	var tribe := ""
	## 섬 지도 창에서의 자리(0~1)
	var map_pos := Vector2.ZERO
	## 지역 id → 레벨대(이 섬만 다를 때)
	var levels := {}


class Data:
	var start := ""
	var regions: Array[Region] = []
	var islands: Array[Island] = []


static var _data: Data


static func data() -> Data:
	if _data == null:
		_data = parse(FileAccess.get_file_as_string(PATH))
	return _data


## 섬들(지도 차례).
static func islands() -> Array[Island]:
	return data().islands


static func get_island(id: String) -> Island:
	for island in data().islands:
		if island.id == id:
			return island
	return null


## 지역들(입문 → 특수 → 심장부).
static func regions() -> Array[Region]:
	return data().regions


static func get_region(id: String) -> Region:
	for region in data().regions:
		if region.id == id:
			return region
	return null


static func start_island() -> String:
	return data().start


static func first_region() -> String:
	return data().regions[0].id if not data().regions.is_empty() else ""


## 그 섬 그 지역의 레벨대(섬에 따로 적었으면 그 값).
static func level_range(island_id: String, region_id: String) -> Vector2i:
	var island := get_island(island_id)
	if island != null and island.levels.has(region_id):
		return island.levels[region_id]
	var region := get_region(region_id)
	return region.level if region != null else Vector2i(1, 1)


## 도감 서식지 글("용섬 입문").
static func habitat_key(island_id: String, region_id: String) -> String:
	var island := get_island(island_id)
	var region := get_region(region_id)
	if island == null or region == null:
		return ""
	return island.name + " " + region.name


## 서식지가 그 섬 그 지역인 종들(도감 차례).
static func species_in(island_id: String, region_id: String) -> Array[HenchSpecies]:
	var key := habitat_key(island_id, region_id)
	var list: Array[HenchSpecies] = []
	for species: HenchSpecies in HenchDb.all().values():
		if key in species.habitats:
			list.append(species)
	return list


## 그 섬의 왕(섬 종족의 왕 등급 종). 없으면 null.
static func king(island_id: String) -> HenchSpecies:
	var island := get_island(island_id)
	if island == null:
		return null
	for species: HenchSpecies in HenchDb.all().values():
		if species.grade == "king" and species.tribe == island.tribe:
			return species
	return null


## 출현표: [[종 id, 비중], …]. 심장부는 그 섬 특수 지역 종(비중 1) + 심장부 종(비중 HEART_RARE_WEIGHT).
static func spawn_table(island_id: String, region_id: String) -> Array:
	var table := []
	var heart := region_id == regions()[regions().size() - 1].id and regions().size() > 1
	if heart:
		for species in species_in(island_id, regions()[regions().size() - 2].id):
			table.append([species.id, 1.0])
	for species in species_in(island_id, region_id):
		table.append([species.id, GameConfig.HEART_RARE_WEIGHT if heart else 1.0])
	return table


## 출현표에서 roll(0~1)로 종 하나. 표가 비면 "".
static func pick_species(table: Array, roll: float) -> String:
	if table.is_empty():
		return ""
	var weights := []
	for row: Array in table:
		weights.append(float(row[1]))
	return str(table[Drops.weighted_index(weights, roll)][0])


## 야생 레벨: 종의 출현 레벨(나이 반영)을 지역 레벨대 안으로.
static func wild_level(species: HenchSpecies, age: CoreItem.Age, levels: Vector2i) -> int:
	return clampi(Drops.wild_level(species, age), levels.x, levels.y)


## 그 지역이 열렸나: 주인공 레벨이 레벨대 아래 끝에 닿으면(임시).
static func is_region_open(island_id: String, region_id: String, player_level: int) -> bool:
	return player_level >= level_range(island_id, region_id).x


## 패배하면 갈 지역(바로 앞 지역). 첫 지역이면 그대로.
static func retreat_region(region_id: String) -> String:
	var region := get_region(region_id)
	if region == null or region.index == 0:
		return region_id
	return regions()[region.index - 1].id


## 필드 장식물 씨앗(섬 · 지역마다 다른 배치, 같은 곳이면 늘 같은 배치).
static func field_seed(island_id: String, region_id: String) -> int:
	return GameConfig.FIELD_SEED + hash(island_id + "/" + region_id) % 100000


## JSON 글자 → Data. 잘못된 칸은 오류를 알리고 건너뛴다.
static func parse(text: String) -> Data:
	var result := Data.new()
	var root: Variant = JSON.parse_string(text)
	if not root is Dictionary:
		push_error("섬 데이터를 읽지 못함")
		return result
	for row: Variant in root.get("regions", []):
		if not row is Dictionary:
			continue
		var region := Region.new()
		region.id = str(row.get("id", ""))
		region.name = str(row.get("name", region.id))
		region.level = _range(row.get("level", [1, 1]))
		region.index = result.regions.size()
		result.regions.append(region)
	for row: Variant in root.get("islands", []):
		if not row is Dictionary:
			continue
		var island := Island.new()
		island.id = str(row.get("id", ""))
		island.name = str(row.get("name", island.id))
		island.tribe = str(row.get("tribe", ""))
		var at: Variant = row.get("map", [0.5, 0.5])
		island.map_pos = Vector2(float(at[0]), float(at[1])) if at is Array and (at as Array).size() == 2 else Vector2(0.5, 0.5)
		var levels: Variant = row.get("levels", {})
		if levels is Dictionary:
			for key: Variant in levels:
				island.levels[str(key)] = _range(levels[key])
		result.islands.append(island)
	result.start = str(root.get("start_island", result.islands[0].id if not result.islands.is_empty() else ""))
	return result


static func _range(value: Variant) -> Vector2i:
	if value is Array and (value as Array).size() == 2:
		return Vector2i(int(value[0]), int(value[1]))
	return Vector2i(1, 1)

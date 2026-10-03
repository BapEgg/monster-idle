class_name WorldState
extends RefCounted
## 지금 있는 섬 · 지역과 열린 섬(기획서 7장 섬 구조). 저장된다(GameSave).
## 섬 개방(도감 → 레시피 힌트 → 길잡이 믹스)은 다음 단계라 지금은 처음 섬만 열려 있고, 개발용으로 모든 섬을 열 수 있다(dev_open_all).

## 섬 · 지역을 옮겼을 때(필드 다시 짓기 · 미니맵 · 지도 창)
signal moved

## 개발 확인용: 모든 섬을 연다(디버그 화면 버튼, 저장하지 않음).
static var dev_open_all := false

var island := IslandDb.start_island()
var region := IslandDb.first_region()
## 열린 섬 id들(처음 섬은 늘 열림)
var opened: PackedStringArray = [IslandDb.start_island()]


func is_island_open(id: String) -> bool:
	return dev_open_all or id in opened


## 그 섬 그 지역에 갈 수 있나(섬이 열렸고, 지역이 주인공 레벨로 열렸고, 지금 있는 곳이 아님).
func can_enter(island_id: String, region_id: String, player_level: int) -> bool:
	if IslandDb.get_island(island_id) == null or IslandDb.get_region(region_id) == null:
		return false
	if island_id == island and region_id == region:
		return false
	return is_island_open(island_id) and IslandDb.is_region_open(island_id, region_id, player_level)


## 옮긴다(갈 수 있는지는 부르는 쪽이 can_enter로 본다).
func move_to(island_id: String, region_id: String) -> void:
	island = island_id
	region = region_id
	moved.emit()


## 패배: 바로 앞 지역으로(입문이면 그대로). 옮겼으면 true.
func retreat() -> bool:
	var back := IslandDb.retreat_region(region)
	if back == region:
		return false
	move_to(island, back)
	return true


func to_dict() -> Dictionary:
	return {"island": island, "region": region, "opened": Array(opened)}


## 저장 내용 → 상태. 없는 섬 · 지역이면 처음 섬 입문으로, 처음 섬은 늘 열림.
func load_dict(row: Dictionary) -> void:
	opened = PackedStringArray([IslandDb.start_island()])
	var saved: Variant = row.get("opened", [])
	if saved is Array:
		for id: Variant in saved:
			if IslandDb.get_island(str(id)) != null and str(id) not in opened:
				opened.append(str(id))
	var id := str(row.get("island", ""))
	var at := str(row.get("region", ""))
	if IslandDb.get_island(id) != null and IslandDb.get_region(at) != null and id in opened:
		island = id
		region = at
	else:
		island = IslandDb.start_island()
		region = IslandDb.first_region()
	moved.emit()

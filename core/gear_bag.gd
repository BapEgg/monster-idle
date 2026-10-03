class_name GearBag
extends RefCounted
## 주인공의 장비 가방: 가진 장비 전부 + 칸마다 낀 장비(칸 → uid, 기획서 3장 7칸). 저장(GameSave)과 직업 창 캐릭터 탭이 쓴다.
## 낀 장비는 아이템 칸(inventory)에 보이지 않고 인형 칸에만 보인다(믹스마스터 · 디아블로처럼).

signal changed

var items: Array[GearItem] = []
## 칸(GearRules.SLOTS) → 낀 장비 uid
var equipped := {}
var next_uid := 1


## 넣는다(번호를 붙여서). 넣은 장비를 돌려준다.
func add(item: GearItem) -> GearItem:
	item.uid = next_uid
	next_uid += 1
	items.append(item)
	changed.emit()
	return item


func find(uid: int) -> GearItem:
	for item in items:
		if item.uid == uid:
			return item
	return null


## 그 장비가 낀 칸(안 꼈으면 "").
func slot_of(item: GearItem) -> String:
	for slot: String in equipped:
		if equipped[slot] == item.uid:
			return slot
	return ""


## 그 칸에 낀 장비(없으면 null).
func in_slot(slot: String) -> GearItem:
	return find(int(equipped[slot])) if equipped.has(slot) else null


## 아이템 칸에 보일 것(안 낀 장비).
func inventory() -> Array[GearItem]:
	var list: Array[GearItem] = []
	for item in items:
		if slot_of(item) == "":
			list.append(item)
	return list


## 낀 장비들(칸 차례).
func equipped_items() -> Array[GearItem]:
	var list: Array[GearItem] = []
	for slot: String in GearRules.SLOTS:
		var item := in_slot(slot)
		if item != null:
			list.append(item)
	return list


## 그 부위에 낀 장비들(장신구는 둘까지).
func worn_of_kind(kind: String) -> Array[GearItem]:
	var list: Array[GearItem] = []
	for slot in GearRules.slots_for(kind):
		var item := in_slot(slot)
		if item != null:
			list.append(item)
	return list


## 낀다. slot = ""이면 그 부위의 빈 칸(없으면 첫 칸). 있던 장비는 아이템 칸으로 돌아간다. 못 끼면 false.
func equip(item: GearItem, job_id: String, player_level: int, slot := "") -> bool:
	if find(item.uid) != item or GearRules.problem(item, job_id, player_level) != GearRules.Problem.OK:
		return false
	var slots := GearRules.slots_for(item.kind)
	if slot == "":
		slot = slots[0]
		for each in slots:
			if not equipped.has(each):
				slot = each
				break
	elif not slots.has(slot):
		return false
	var was := slot_of(item)
	if was != "":
		equipped.erase(was)
	equipped[slot] = item.uid
	changed.emit()
	return true


## 그 칸의 장비를 뺀다(아이템 칸으로).
func unequip(slot: String) -> void:
	if equipped.erase(slot):
		changed.emit()


func toggle_lock(item: GearItem) -> void:
	item.locked = not item.locked
	changed.emit()


## 직업이 바뀌면 다른 직업의 무기를 뺀다.
func fit_job(job_id: String) -> void:
	var weapon := in_slot("weapon")
	if weapon != null and weapon.job_id != job_id:
		unequip("weapon")


## 낀 장비가 올려 주는 것의 합 {능력치: 값}.
func bonus() -> Dictionary:
	return GearRules.total(equipped_items())


func to_dict() -> Dictionary:
	var rows := []
	for item in items:
		rows.append(item.to_dict())
	return {"items": rows, "equipped": equipped.duplicate(), "next_uid": next_uid}


## 저장에서 되살린다. 번호가 겹치거나 없는 장비 · 맞지 않는 칸은 버린다.
func load_dict(data: Dictionary) -> void:
	items.clear()
	equipped.clear()
	var seen := {}
	for row: Variant in data.get("items", []):
		if not row is Dictionary:
			continue
		var item := GearItem.from_dict(row)
		if item.uid <= 0 or seen.has(item.uid) or not item.kind in GearDb.kinds():
			continue
		seen[item.uid] = true
		items.append(item)
	var slots: Dictionary = data.get("equipped", {})
	for slot: String in slots:
		var item := find(int(slots[slot]))
		if slot in GearRules.SLOTS and item != null and GearRules.slot_kind(slot) == item.kind and slot_of(item) == "":
			equipped[slot] = item.uid
	var biggest := 0
	for uid: int in seen:
		biggest = maxi(biggest, uid)
	next_uid = maxi(int(data.get("next_uid", 1)), biggest + 1)
	changed.emit()

class_name JobState
extends RefCounted
## 주인공의 직업과 직업 스킬 상태(기획서 3장): 지금 직업, 배운 스킬 레벨, 장착 칸(액티브 3 · 패시브(레벨 따라 열림) · 궁극기 1).
## 남은 스킬 포인트는 따로 적지 않고 "받은 것 − 쓴 것"으로 센다(JobRules). 저장된다(GameSave).
## 직업을 바꾸면(개발용) 배운 것과 장착이 처음으로 돌아간다.

## 직업 · 스킬 레벨 · 장착이 바뀌었을 때(직업 창 · 스킬 칸 · 주인공 능력치)
signal changed

var job_id := GameConfig.START_JOB
## 배운 스킬 id → 스킬 레벨(1부터)
var levels := {}
## 액티브 칸(빈 칸 = "")
var actives: Array[String] = []
## 패시브 칸(열린 칸까지만 쓴다, 빈 칸 = "")
var passives: Array[String] = []
var ultimate := ""


func _init() -> void:
	_clear_slots()


func _clear_slots() -> void:
	actives.clear()
	for i in GameConfig.JOB_ACTIVE_SLOTS:
		actives.append("")
	passives.clear()
	for i in GameConfig.JOB_PASSIVE_SLOT_LEVELS.size():
		passives.append("")
	ultimate = ""


func job() -> JobDb.Job:
	return JobDb.get_job(job_id)


## 그 스킬의 레벨(배우지 않았으면 0).
func skill_level(id: String) -> int:
	return int(levels.get(id, 0))


## 남은 스킬 포인트.
func points(player_level: int) -> int:
	return maxi(JobRules.points_earned(player_level) - JobRules.points_spent(levels), 0)


## 주인공 레벨에 맞춰 해금된 스킬을 배우고(레벨 1), 빈 칸이 있으면 바로 장착한다. 새로 배운 스킬 id들을 돌려준다.
func sync(player_level: int) -> Array[String]:
	var learned: Array[String] = []
	var of_job := job()
	if of_job == null:
		return learned
	for skill in of_job.skills:
		if JobRules.is_unlocked(skill, player_level) and not levels.has(skill.id):
			levels[skill.id] = 1
			learned.append(skill.id)
			_auto_equip(skill, player_level)
	if not learned.is_empty():
		changed.emit()
	return learned


func _auto_equip(skill: JobDb.Skill, player_level: int) -> void:
	match skill.type:
		"active":
			var empty := actives.find("")
			if empty >= 0:
				actives[empty] = skill.id
		"passive":
			var open := JobRules.passive_slot_count(player_level)
			for i in open:
				if passives[i] == "":
					passives[i] = skill.id
					return
		"ultimate":
			if ultimate == "":
				ultimate = skill.id


## 스킬 레벨을 올릴 수 있나(배웠고, 상한 아래이고, 포인트가 있으면).
func can_level_up(id: String, player_level: int) -> bool:
	var level := skill_level(id)
	return level > 0 and level < GameConfig.JOB_SKILL_MAX_LEVEL and points(player_level) > 0


func level_up(id: String, player_level: int) -> bool:
	if not can_level_up(id, player_level):
		return false
	levels[id] = skill_level(id) + 1
	changed.emit()
	return true


func is_equipped(id: String) -> bool:
	return id != "" and (id in actives or id in passives or ultimate == id)


## 장착한다. 액티브 · 패시브는 slot 칸에(다른 칸에 있었으면 옮김, 그 칸에 있던 스킬은 빠짐), 궁극기는 하나뿐인 칸에.
## 배우지 않았거나, 닫힌 패시브 칸이거나, 칸 번호가 틀리면 false.
func equip(id: String, slot: int, player_level: int) -> bool:
	var skill := JobDb.get_skill(id)
	if skill == null or skill.job_id != job_id or skill_level(id) <= 0:
		return false
	match skill.type:
		"active":
			if slot < 0 or slot >= actives.size():
				return false
			_remove_from(actives, id)
			actives[slot] = id
		"passive":
			if slot < 0 or slot >= JobRules.passive_slot_count(player_level):
				return false
			_remove_from(passives, id)
			passives[slot] = id
		"ultimate":
			ultimate = id
	changed.emit()
	return true


func unequip(id: String) -> bool:
	if not is_equipped(id):
		return false
	_remove_from(actives, id)
	_remove_from(passives, id)
	if ultimate == id:
		ultimate = ""
	changed.emit()
	return true


static func _remove_from(slots: Array[String], id: String) -> void:
	for i in slots.size():
		if slots[i] == id:
			slots[i] = ""


## 그 종류의 첫 빈 칸(없으면 -1). 패시브는 열린 칸만 본다.
func empty_slot(type: String, player_level: int) -> int:
	match type:
		"active":
			return actives.find("")
		"passive":
			for i in JobRules.passive_slot_count(player_level):
				if passives[i] == "":
					return i
			return -1
		"ultimate":
			return 0 if ultimate == "" else -1
	return -1


## 열린 패시브 칸에 장착한 패시브들.
func equipped_passives(player_level: int) -> Array[String]:
	var list: Array[String] = []
	for i in mini(JobRules.passive_slot_count(player_level), passives.size()):
		if passives[i] != "":
			list.append(passives[i])
	return list


## 장착한 패시브의 보정 합.
func mods(player_level: int) -> Dictionary:
	return JobRules.sum_mods(equipped_passives(player_level), levels)


## 직업을 바꾼다(개발용): 배운 것 · 장착을 비우고 그 레벨까지 다시 배운다.
func change_job(id: String, player_level: int) -> bool:
	if JobDb.get_job(id) == null or id == job_id:
		return false
	job_id = id
	levels.clear()
	_clear_slots()
	sync(player_level)
	changed.emit()
	return true


func to_dict() -> Dictionary:
	return {"job": job_id, "levels": levels.duplicate(), "actives": Array(actives), "passives": Array(passives), "ultimate": ultimate}


## 저장 내용 → 상태. 없는 직업 · 다른 직업의 스킬 · 상한을 넘는 레벨은 버리거나 줄이고, 그 레벨까지 해금된 것을 배운다.
func load_dict(row: Dictionary, player_level: int) -> void:
	var id := str(row.get("job", GameConfig.START_JOB))
	job_id = id if JobDb.get_job(id) != null else GameConfig.START_JOB
	levels.clear()
	_clear_slots()
	var saved: Variant = row.get("levels", {})
	if saved is Dictionary:
		for key: Variant in saved:
			var skill := JobDb.get_skill(str(key))
			if skill != null and skill.job_id == job_id and JobRules.is_unlocked(skill, player_level):
				levels[skill.id] = clampi(int(saved[key]), 1, GameConfig.JOB_SKILL_MAX_LEVEL)
	_load_slots(row.get("actives", []), actives, "active")
	_load_slots(row.get("passives", []), passives, "passive")
	var ult := str(row.get("ultimate", ""))
	var ult_skill := JobDb.get_skill(ult)
	ultimate = ult if ult_skill != null and ult_skill.type == "ultimate" and levels.has(ult) else ""
	sync(player_level)
	changed.emit()


func _load_slots(saved: Variant, slots: Array[String], type: String) -> void:
	if not saved is Array:
		return
	for i in mini((saved as Array).size(), slots.size()):
		var id := str(saved[i])
		var skill := JobDb.get_skill(id)
		if skill != null and skill.type == type and levels.has(id) and id not in slots:
			slots[i] = id

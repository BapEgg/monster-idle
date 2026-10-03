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


## 처음부터 가진 스킬(해금 레벨 GameConfig.JOB_START_SKILL_LEVEL 이하)을 배우고 빈 칸에 장착한다. 새로 배운 스킬 id들을 돌려준다.
## 그보다 높은 스킬은 레벨이 닿아도 저절로 배우지 않는다 — 직업 창에서 "배우기"(사용자 결정 2026-10-03: 레벨은 됐는데 아직 안 배운 상태가 있다).
func sync(player_level: int) -> Array[String]:
	var learned: Array[String] = []
	var of_job := job()
	if of_job == null:
		return learned
	for skill in of_job.skills:
		if skill.unlock <= GameConfig.JOB_START_SKILL_LEVEL and JobRules.is_unlocked(skill, player_level) and not levels.has(skill.id):
			levels[skill.id] = 1
			learned.append(skill.id)
			_auto_equip(skill, player_level)
	if not learned.is_empty():
		changed.emit()
	return learned


## 배울 수 있나(레벨은 닿았고 아직 안 배움).
func can_learn(id: String, player_level: int) -> bool:
	var skill := JobDb.get_skill(id)
	return skill != null and skill.job_id == job_id and JobRules.is_unlocked(skill, player_level) and not levels.has(id)


## 배운다(스킬 레벨 1, 임시: 포인트는 쓰지 않음). 빈 칸이 있으면 바로 장착한다.
func learn(id: String, player_level: int) -> bool:
	if not can_learn(id, player_level):
		return false
	levels[id] = 1
	_auto_equip(JobDb.get_skill(id), player_level)
	changed.emit()
	return true


## 레벨은 닿았는데 아직 안 배운 스킬들.
func learnable(player_level: int) -> Array[String]:
	var list: Array[String] = []
	var of_job := job()
	if of_job != null:
		for skill in of_job.skills:
			if can_learn(skill.id, player_level):
				list.append(skill.id)
	return list


## 레벨이 from에서 to로 오르며 새로 배울 수 있게 된 스킬들(레벨업 알림).
func newly_learnable(from_level: int, to_level: int) -> Array[String]:
	var list: Array[String] = []
	var of_job := job()
	if of_job != null:
		for skill in of_job.skills:
			if skill.unlock > from_level and skill.unlock <= to_level and not levels.has(skill.id):
				list.append(skill.id)
	return list


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


## 장착한다. 액티브 · 패시브는 slot 칸에(그 칸에 있던 스킬은 빠진다. 장착한 스킬을 다른 칸으로 옮기면 두 칸이 자리를 바꾼다), 궁극기는 하나뿐인 칸에.
## 배우지 않았거나, 닫힌 패시브 칸이거나, 칸 번호가 틀리면 false.
func equip(id: String, slot: int, player_level: int) -> bool:
	var skill := JobDb.get_skill(id)
	if skill == null or skill.job_id != job_id or skill_level(id) <= 0:
		return false
	match skill.type:
		"active":
			if slot < 0 or slot >= actives.size():
				return false
			_place(actives, id, slot)
		"passive":
			if slot < 0 or slot >= JobRules.passive_slot_count(player_level):
				return false
			_place(passives, id, slot)
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


## slot 칸에 넣는다. 이미 다른 칸에 있던 스킬이면 그 칸과 자리를 바꾼다.
static func _place(slots: Array[String], id: String, slot: int) -> void:
	var old := slots.find(id)
	var displaced := slots[slot]
	slots[slot] = id
	if old >= 0 and old != slot:
		slots[old] = displaced


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


## 직업을 바꾼다(개발용): 배운 것 · 장착을 비우고 처음 스킬만 다시 배운다.
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


## 저장 내용 → 상태. 없는 직업 · 다른 직업의 스킬 · 아직 레벨이 안 닿은 스킬은 버리고, 상한을 넘는 레벨은 줄인다. 처음 스킬은 배운다.
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

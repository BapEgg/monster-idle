class_name JobDb
extends RefCounted
## 주인공 직업 데이터(data/jobs.json, 기획서 3장): 직업 5종과 직업 스킬(MVP 액티브 5 · 패시브 2 · 궁극기 1).
## 이름 · 해금 레벨 · 설명은 데이터 파일, 스킬 수치(대기 시간 · 효과 · 패시브 보정)는 GameConfig.JOB_SKILLS에 있다.
## 처음 찾을 때 한 번만 읽는다. 주의: 안드로이드로 내보낼 때 "리소스가 아닌 파일" 필터에 *.json 을 넣어야 함께 들어간다.

const PATH := "res://data/jobs.json"
const TYPES := ["active", "passive", "ultimate"]


## 직업 하나.
class Job:
	var id := ""
	var name := ""
	## 역할(tank · melee · ranged · healer · buffer)
	var role := ""
	var weapon := ""
	## 인물 · 섬에 온 계기(기획서 3장)
	var person := ""
	var color := Color.WHITE
	var skills: Array[Skill] = []

	## 그 종류(active · passive · ultimate)의 스킬들(해금 레벨 순서 그대로).
	func skills_of(type: String) -> Array[Skill]:
		var list: Array[Skill] = []
		for skill in skills:
			if skill.type == type:
				list.append(skill)
		return list


## 직업 스킬 하나.
class Skill:
	var id := ""
	var name := ""
	## active · passive · ultimate
	var type := ""
	## 해금 레벨
	var unlock := 1
	var desc := ""
	var job_id := ""

	## 수치(GameConfig.JOB_SKILLS): 액티브 · 궁극기 = {cooldown, effects}, 패시브 = {mods}.
	func config() -> Dictionary:
		return GameConfig.JOB_SKILLS.get(id, {})

	func is_passive() -> bool:
		return type == "passive"


static var _jobs := {}
static var _order: Array[String] = []
static var _skills := {}


## id로 직업을 찾는다. 없으면 null.
static func get_job(id: String) -> Job:
	_load()
	return _jobs.get(id)


## 모든 직업 id(데이터 순서).
static func ids() -> Array[String]:
	_load()
	return _order


## id로 직업 스킬을 찾는다(어느 직업이든). 없으면 null.
static func get_skill(id: String) -> Skill:
	_load()
	return _skills.get(id)


static func _load() -> void:
	if not _jobs.is_empty():
		return
	var parsed := parse(FileAccess.get_file_as_string(PATH))
	_jobs = parsed
	_order.clear()
	for id: String in parsed:
		_order.append(id)
		for skill in (parsed[id] as Job).skills:
			_skills[skill.id] = skill


## JSON 글자 → { id: Job }(데이터 순서를 지킨다). 잘못된 칸은 오류를 알리고 건너뛴다.
static func parse(text: String) -> Dictionary:
	var result := {}
	var root: Variant = JSON.parse_string(text)
	if not root is Dictionary or not root.get("jobs") is Array:
		push_error("직업 데이터를 읽지 못함: jobs 배열이 없음")
		return result
	for row: Variant in root["jobs"]:
		if not row is Dictionary:
			continue
		var job := Job.new()
		job.id = str(row.get("id", ""))
		job.name = str(row.get("name", ""))
		job.role = str(row.get("role", ""))
		job.weapon = str(row.get("weapon", ""))
		job.person = str(row.get("person", ""))
		job.color = Color.from_string(str(row.get("color", "#ffffff")), Color.WHITE)
		for skill_row: Variant in row.get("skills", []):
			if not skill_row is Dictionary:
				continue
			var skill := Skill.new()
			skill.id = str(skill_row.get("id", ""))
			skill.name = str(skill_row.get("name", ""))
			skill.type = str(skill_row.get("type", ""))
			skill.unlock = int(skill_row.get("unlock", 1))
			skill.desc = str(skill_row.get("desc", ""))
			skill.job_id = job.id
			if skill.id == "" or skill.type not in TYPES:
				push_error("직업 스킬 데이터 오류: %s의 %s" % [job.id, skill.id])
				continue
			job.skills.append(skill)
		if job.id == "" or job.skills.is_empty():
			push_error("직업 데이터 오류: id 또는 스킬이 없음")
			continue
		result[job.id] = job
	return result

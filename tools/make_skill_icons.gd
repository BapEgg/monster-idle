extends SceneTree
## 직업 스킬 임시 아이콘(96×96 PNG)을 만든다: 둥근 네모 바탕 + 효과 종류를 나타내는 흰 도형(칼 · 터짐 · 방패 · 십자 …).
## 바탕 색: 액티브 = 직업 색, 패시브 = 차분한 회청색(안쪽 고리), 궁극기 = 자홍 + 금테.
## data/jobs.json의 icon_path 틀(art/skills/<직업>/<스킬>.png)에 저장한다. 진짜 그림이 생기면 같은 이름으로 덮어쓰고 이 스크립트는 다시 돌리지 않는다.
## 실행: <Godot> --headless --path . --script res://tools/make_skill_icons.gd  → 그다음 --import

const SIZE := 96
## 2배 크기로 그린 뒤 줄여서 가장자리를 부드럽게 한다.
const SCALE := 2
const CORNER := 0.18
const GLYPH := Color(1, 1, 1, 0.95)
const PASSIVE_BG := Color("4f6a8a")
const ULTIMATE_BG := Color("b5367f")
const ULTIMATE_RIM := Color("ffd84a")
## 패시브 보정 → 도형
const MOD_GLYPHS := {
	"hp": "heart", "party_hp": "heart", "damage_taken": "shield", "tank_damage_taken": "shield", "attack": "hit",
	"attack_speed": "dash", "move_speed": "dash", "range": "eye", "ambush": "hit", "heal_power": "heal",
	"buff_seconds": "buff", "buff_power": "buff",
}


func _initialize() -> void:
	for id in JobDb.ids():
		var job := JobDb.get_job(id)
		for skill in job.skills:
			if skill.icon_path == "":
				continue
			_save(_icon(skill, job.color), skill.icon_path)
		print("아이콘: ", id)
	quit()


func _save(image: Image, path: String) -> void:
	image.resize(SIZE, SIZE, Image.INTERPOLATE_LANCZOS)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	image.save_png(ProjectSettings.globalize_path(path))


func _icon(skill: JobDb.Skill, job_color: Color) -> Image:
	var s := float(SIZE * SCALE)
	var img := Image.create(int(s), int(s), false, Image.FORMAT_RGBA8)
	var bg := job_color.darkened(0.25)
	match skill.type:
		"passive":
			bg = PASSIVE_BG
		"ultimate":
			bg = ULTIMATE_BG
	if skill.type == "ultimate":
		_round_rect(img, Rect2(0.0, 0.0, 1.0, 1.0), ULTIMATE_RIM, s)
		_round_rect(img, Rect2(0.05, 0.05, 0.9, 0.9), bg, s)
	else:
		_round_rect(img, Rect2(0.02, 0.02, 0.96, 0.96), bg.darkened(0.35), s)
		_round_rect(img, Rect2(0.06, 0.06, 0.88, 0.88), bg, s)
	if skill.type == "passive":
		_ring(img, Vector2(0.5, 0.5) * s, s * 0.36, s * 0.025, Color(1, 1, 1, 0.35))
	# 위쪽 반사광
	_polygon(img, _scaled([Vector2(0.12, 0.1), Vector2(0.88, 0.1), Vector2(0.88, 0.22), Vector2(0.12, 0.32)], s), Color(1, 1, 1, 0.12))
	_glyph(img, _glyph_of(skill), s)
	if skill.type == "ultimate":
		for at: Vector2 in [Vector2(0.2, 0.2), Vector2(0.8, 0.78)]:
			_star(img, at * s, s * 0.07, ULTIMATE_RIM)
	return img


## 스킬이 무엇을 하나 → 도형 이름(첫 효과 종류, 패시브는 첫 보정).
static func _glyph_of(skill: JobDb.Skill) -> String:
	var config := skill.config()
	if skill.is_passive():
		var mods: Dictionary = config.get("mods", {})
		return MOD_GLYPHS.get(mods.keys()[0], "buff") if not mods.is_empty() else "buff"
	var effects: Array = config.get("effects", [])
	if effects.is_empty():
		return "buff"
	var first: Dictionary = effects[0]
	var type := str(first.get("type", "hit"))
	if type == "hit" and int(first.get("hits", 1)) > 1:
		return "flurry"
	if type == "area" and first.has("stun"):
		return "stun"
	if type == "heal" and first.get("cleanse", false):
		return "cleanse"
	if type == "heal" and first.get("who", "lowest") == "area":
		return "heal_all"
	if type == "buff":
		if first.has("guard"):
			return "shield"
		if first.has("speed") and not first.has("attack"):
			return "dash"
		if first.has("speed") and first.has("attack"):
			return "buff_both"
	return type


func _glyph(img: Image, kind: String, s: float) -> void:
	var c := Vector2(0.5, 0.5)
	match kind:
		"hit":
			_sword(img, Vector2(0.28, 0.72), Vector2(0.72, 0.28), s)
		"flurry":
			_sword(img, Vector2(0.24, 0.66), Vector2(0.62, 0.28), s)
			_sword(img, Vector2(0.4, 0.76), Vector2(0.78, 0.38), s)
		"area":
			_burst(img, c, s, 8)
		"stun":
			_burst(img, c, s, 5)
			for i in 3:
				_star(img, (c + Vector2.from_angle(-PI * 0.5 + i * TAU / 3.0) * 0.3) * s, s * 0.06, GLYPH)
		"taunt":
			_line(img, Vector2(0.5, 0.22) * s, Vector2(0.5, 0.58) * s, s * 0.12, GLYPH)
			_ellipse(img, Vector2(0.5, 0.74) * s, Vector2(0.07, 0.07) * s, GLYPH)
		"shield":
			var outline := [Vector2(0.5, 0.18), Vector2(0.78, 0.28), Vector2(0.74, 0.58), Vector2(0.5, 0.82), Vector2(0.26, 0.58), Vector2(0.22, 0.28)]
			_polygon(img, _scaled(outline, s), GLYPH)
			_line(img, Vector2(0.5, 0.28) * s, Vector2(0.5, 0.7) * s, s * 0.05, Color(0, 0, 0, 0.25))
		"dash":
			_chevron(img, Vector2(0.32, 0.5), 1.0, s)
			_chevron(img, Vector2(0.54, 0.5), 1.0, s)
		"retreat":
			_chevron(img, Vector2(0.68, 0.5), -1.0, s)
			_chevron(img, Vector2(0.46, 0.5), -1.0, s)
		"pierce":
			_line(img, Vector2(0.2, 0.8) * s, Vector2(0.74, 0.26) * s, s * 0.06, GLYPH)
			_polygon(img, _scaled([Vector2(0.84, 0.16), Vector2(0.62, 0.24), Vector2(0.76, 0.38)], s), GLYPH)
			_line(img, Vector2(0.2, 0.8) * s, Vector2(0.14, 0.7) * s, s * 0.04, GLYPH)
			_line(img, Vector2(0.2, 0.8) * s, Vector2(0.3, 0.86) * s, s * 0.04, GLYPH)
		"smoke":
			for puff: Vector3 in [Vector3(0.36, 0.58, 0.16), Vector3(0.56, 0.5, 0.2), Vector3(0.68, 0.64, 0.14), Vector3(0.46, 0.68, 0.14)]:
				_ellipse(img, Vector2(puff.x, puff.y) * s, Vector2(puff.z, puff.z) * s, Color(GLYPH, 0.85))
		"heal", "heal_all", "cleanse":
			_line(img, Vector2(0.5, 0.24) * s, Vector2(0.5, 0.76) * s, s * 0.16, GLYPH)
			_line(img, Vector2(0.24, 0.5) * s, Vector2(0.76, 0.5) * s, s * 0.16, GLYPH)
			if kind == "heal_all":
				_ring(img, c * s, s * 0.36, s * 0.035, GLYPH)
			elif kind == "cleanse":
				for at: Vector2 in [Vector2(0.24, 0.24), Vector2(0.76, 0.26), Vector2(0.74, 0.76)]:
					_star(img, at * s, s * 0.07, GLYPH)
		"revive", "heart":
			_heart(img, s)
			if kind == "revive":
				_line(img, Vector2(0.5, 0.36) * s, Vector2(0.5, 0.6) * s, s * 0.07, Color(0, 0, 0, 0.3))
				_line(img, Vector2(0.38, 0.48) * s, Vector2(0.62, 0.48) * s, s * 0.07, Color(0, 0, 0, 0.3))
		"buff", "buff_both":
			_polygon(img, _scaled([Vector2(0.5, 0.18), Vector2(0.76, 0.48), Vector2(0.24, 0.48)], s), GLYPH)
			_line(img, Vector2(0.5, 0.46) * s, Vector2(0.5, 0.8) * s, s * 0.14, GLYPH)
			if kind == "buff_both":  # 공격 + 공격 속도: 양옆 작은 화살표
				for x: float in [0.24, 0.76]:
					_polygon(img, _scaled([Vector2(x, 0.42), Vector2(x + 0.08, 0.54), Vector2(x - 0.08, 0.54)], s), GLYPH)
					_line(img, Vector2(x, 0.52) * s, Vector2(x, 0.7) * s, s * 0.05, GLYPH)
		"storm":
			for i in 3:
				var blade := _ellipse_points(Vector2(0.5, 0.5) + Vector2.from_angle(i * TAU / 3.0) * 0.16, Vector2(0.2, 0.07), i * TAU / 3.0 + 0.6)
				_polygon(img, _scaled(blade, s), GLYPH)
			_ellipse(img, c * s, Vector2(0.07, 0.07) * s, GLYPH)
		"eye":
			_polygon(img, _scaled(_ellipse_points(c, Vector2(0.3, 0.16), 0.0), s), GLYPH)
			_ellipse(img, c * s, Vector2(0.1, 0.1) * s, Color(0.1, 0.12, 0.16))
		_:
			_star(img, c * s, s * 0.26, GLYPH)


# ─── 도형 ───────────────────────────────────────

func _sword(img: Image, hilt: Vector2, tip: Vector2, s: float) -> void:
	var along := (tip - hilt).normalized()
	var side := Vector2(-along.y, along.x)
	_line(img, (hilt + along * 0.08) * s, (tip - along * 0.06) * s, s * 0.07, GLYPH)
	_polygon(img, _scaled([tip, tip - along * 0.1 + side * 0.035, tip - along * 0.1 - side * 0.035], s), GLYPH)
	_line(img, (hilt + along * 0.08 + side * 0.09) * s, (hilt + along * 0.08 - side * 0.09) * s, s * 0.05, GLYPH)
	_line(img, hilt * s, (hilt + along * 0.08) * s, s * 0.05, GLYPH)


func _burst(img: Image, c: Vector2, s: float, spikes: int) -> void:
	_ellipse(img, c * s, Vector2(0.14, 0.14) * s, GLYPH)
	for i in spikes:
		var dir := Vector2.from_angle(i * TAU / spikes)
		_line(img, (c + dir * 0.2) * s, (c + dir * 0.34) * s, s * 0.05, GLYPH)


func _chevron(img: Image, at: Vector2, facing: float, s: float) -> void:
	_line(img, (at + Vector2(-0.08 * facing, -0.18)) * s, (at + Vector2(0.1 * facing, 0.0)) * s, s * 0.08, GLYPH)
	_line(img, (at + Vector2(0.1 * facing, 0.0)) * s, (at + Vector2(-0.08 * facing, 0.18)) * s, s * 0.08, GLYPH)


func _heart(img: Image, s: float) -> void:
	_ellipse(img, Vector2(0.38, 0.42) * s, Vector2(0.14, 0.14) * s, GLYPH)
	_ellipse(img, Vector2(0.62, 0.42) * s, Vector2(0.14, 0.14) * s, GLYPH)
	_polygon(img, _scaled([Vector2(0.25, 0.48), Vector2(0.75, 0.48), Vector2(0.5, 0.8)], s), GLYPH)


func _star(img: Image, center: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 10:
		var r := radius if i % 2 == 0 else radius * 0.45
		points.append(center + Vector2.from_angle(-PI * 0.5 + i * TAU / 10.0) * r)
	_polygon(img, points, color)


func _round_rect(img: Image, rect: Rect2, color: Color, s: float) -> void:
	var r := CORNER * rect.size.x
	var box := Rect2(rect.position * s, rect.size * s)
	var radius := r * s
	var area := Rect2i(box).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			var p := Vector2(x + 0.5, y + 0.5)
			var nearest := Vector2(clampf(p.x, box.position.x + radius, box.end.x - radius), clampf(p.y, box.position.y + radius, box.end.y - radius))
			if p.distance_to(nearest) <= radius:
				_blend(img, x, y, color)


func _ring(img: Image, center: Vector2, radius: float, width: float, color: Color) -> void:
	var area := Rect2i(Rect2(center - Vector2.ONE * (radius + width), Vector2.ONE * (radius + width) * 2.0)).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			if absf(Vector2(x + 0.5, y + 0.5).distance_to(center) - radius) <= width * 0.5:
				_blend(img, x, y, color)


# ─── 그리기 도우미(이미지에 직접 칠한다, make_placeholder_art.gd와 같다) ──────

func _blend(img: Image, x: int, y: int, color: Color) -> void:
	img.set_pixel(x, y, img.get_pixel(x, y).blend(color))


func _ellipse(img: Image, center: Vector2, radii: Vector2, color: Color) -> void:
	var box := Rect2i(Vector2i(center - radii), Vector2i(radii * 2.0) + Vector2i.ONE).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
	for y in range(box.position.y, box.end.y):
		for x in range(box.position.x, box.end.x):
			var d := (Vector2(x + 0.5, y + 0.5) - center) / radii
			if d.length_squared() <= 1.0:
				_blend(img, x, y, color)


func _polygon(img: Image, points: PackedVector2Array, color: Color) -> void:
	var box := Rect2(points[0], Vector2.ZERO)
	for p in points:
		box = box.expand(p)
	var area := Rect2i(box.grow(1.0)).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), points):
				_blend(img, x, y, color)


func _line(img: Image, a: Vector2, b: Vector2, width: float, color: Color) -> void:
	var box := Rect2(a, Vector2.ZERO).expand(b).grow(width)
	var area := Rect2i(box).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			var p := Vector2(x + 0.5, y + 0.5)
			if p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b)) <= width * 0.5:
				_blend(img, x, y, color)


## 0~1 좌표를 이미지 크기로.
func _scaled(points: Array, s: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p: Vector2 in points:
		out.append(p * s)
	return out


## 기울어진 타원의 둘레 점(0~1 좌표).
func _ellipse_points(center: Vector2, radii: Vector2, angle: float, count := 24) -> Array:
	var out := []
	for i in count:
		var t := TAU * i / count
		out.append(center + Vector2(cos(t) * radii.x, sin(t) * radii.y).rotated(angle))
	return out

extends SceneTree
## 종족별 임시 그림을 만든다: 아이콘(64×64, 보석)과 초상화(192×192, 배경이 투명한 동그란 몸 + 종족 특징).
## data/tribes.json에 적힌 경로에 PNG로 저장한다. 진짜 그림이 생기면 그 파일을 같은 이름으로 덮어쓰면 되고,
## 이 스크립트는 다시 돌리지 않는다(덮어써 버린다).
## 초상화 배경이 투명해야 믹스창의 "힌트(실루엣)"가 몸 모양으로 보인다.
## 실행: <Godot> --headless --path . --script res://tools/make_placeholder_art.gd  → 그다음 --import

const ICON_SIZE := 64
const PORTRAIT_SIZE := 192
## 2배 크기로 그린 뒤 줄여서 가장자리를 부드럽게 한다.
const SCALE := 2


func _initialize() -> void:
	var tribes := TribeDb.parse(FileAccess.get_file_as_string(TribeDb.PATH))
	for tribe: TribeDb.Tribe in tribes.values():
		_save(_icon(tribe.color), tribe.icon_path, ICON_SIZE)
		_save(_portrait(tribe.id, tribe.color), tribe.portrait_path, PORTRAIT_SIZE)
		print("그림: ", tribe.id)
	quit()


func _save(image: Image, path: String, size: int) -> void:
	image.resize(size, size, Image.INTERPOLATE_LANCZOS)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	image.save_png(ProjectSettings.globalize_path(path))


# ─── 아이콘: 종족 색 보석 ───────────────────────────

func _icon(color: Color) -> Image:
	var s := float(ICON_SIZE * SCALE)
	var img := Image.create(int(s), int(s), false, Image.FORMAT_RGBA8)
	var gem := [Vector2(0.5, 0.06), Vector2(0.92, 0.38), Vector2(0.5, 0.96), Vector2(0.08, 0.38)]
	_polygon(img, _scaled(_grow(gem, 0.06), s), color.darkened(0.65))
	_polygon(img, _scaled(gem, s), color)
	_polygon(img, _scaled([gem[0], gem[1], Vector2(0.5, 0.42), gem[3]], s), color.lightened(0.35))
	_polygon(img, _scaled([Vector2(0.5, 0.42), gem[1], gem[2]], s), color.darkened(0.15))
	_line(img, Vector2(0.24, 0.36) * s, Vector2(0.44, 0.2) * s, s * 0.05, Color(1, 1, 1, 0.8))
	return img


# ─── 초상화: 동그란 몸 + 눈 + 종족 특징 ─────────────────

func _portrait(tribe: String, color: Color) -> Image:
	var s := float(PORTRAIT_SIZE * SCALE)
	var img := Image.create(int(s), int(s), false, Image.FORMAT_RGBA8)
	var dark := color.darkened(0.55)
	var part := color.darkened(0.2)
	_ellipse(img, Vector2(0.5, 0.92) * s, Vector2(0.3, 0.05) * s, Color(0, 0, 0, 0.25))
	_feature(img, tribe, s, part, dark)
	_ellipse(img, Vector2(0.5, 0.58) * s, Vector2(0.36, 0.33) * s, dark)
	_ellipse(img, Vector2(0.5, 0.58) * s, Vector2(0.34, 0.31) * s, color)
	_ellipse(img, Vector2(0.5, 0.67) * s, Vector2(0.21, 0.18) * s, color.lightened(0.3))
	for side: float in [-1.0, 1.0]:
		var eye := Vector2(0.5 + side * 0.12, 0.51) * s
		_ellipse(img, eye, Vector2(0.07, 0.08) * s, Color.WHITE)
		_ellipse(img, eye + Vector2(-side * 0.012, 0.012) * s, Vector2(0.035, 0.04) * s, Color("2b2b33"))
		_ellipse(img, eye + Vector2(-side * 0.025, -0.02) * s, Vector2(0.013, 0.013) * s, Color.WHITE)
	return img


## 종족마다 몸 뒤에 붙는 특징(뿔·잎·귀·안테나·날개 …). 몸보다 먼저 그려 몸 뒤로 숨는다.
func _feature(img: Image, tribe: String, s: float, part: Color, dark: Color) -> void:
	for side: float in [-1.0, 1.0]:
		match tribe:
			"dragon":  # 긴 뿔
				_polygon(img, _scaled(_mirror([Vector2(0.36, 0.34), Vector2(0.27, 0.06), Vector2(0.44, 0.29)], side), s), part)
			"demon":  # 짧고 굽은 뿔 + 뾰족한 꼬리
				_polygon(img, _scaled(_mirror([Vector2(0.33, 0.33), Vector2(0.22, 0.14), Vector2(0.27, 0.13), Vector2(0.42, 0.28)], side), s), dark)
			"beast":  # 둥근 귀
				_ellipse(img, Vector2(0.5 + side * 0.24, 0.3) * s, Vector2(0.11, 0.11) * s, part)
				_ellipse(img, Vector2(0.5 + side * 0.24, 0.3) * s, Vector2(0.06, 0.06) * s, part.lightened(0.35))
			"insect":  # 더듬이
				_line(img, Vector2(0.5 + side * 0.09, 0.3) * s, Vector2(0.5 + side * 0.2, 0.08) * s, s * 0.02, dark)
				_ellipse(img, Vector2(0.5 + side * 0.2, 0.08) * s, Vector2(0.035, 0.035) * s, dark)
			"flying":  # 날개
				_polygon(img, _scaled(_mirror(_ellipse_points(Vector2(0.17, 0.55), Vector2(0.18, 0.1), -0.5), side), s), part)
	match tribe:
		"plant":  # 새싹
			_line(img, Vector2(0.5, 0.3) * s, Vector2(0.5, 0.14) * s, s * 0.025, part.darkened(0.2))
			_polygon(img, _scaled(_ellipse_points(Vector2(0.4, 0.12), Vector2(0.11, 0.05), -0.4), s), part.lightened(0.15))
			_polygon(img, _scaled(_ellipse_points(Vector2(0.6, 0.12), Vector2(0.11, 0.05), 0.4), s), part.lightened(0.15))
		"machine":  # 안테나
			_line(img, Vector2(0.5, 0.3) * s, Vector2(0.5, 0.1) * s, s * 0.025, dark)
			_ellipse(img, Vector2(0.5, 0.09) * s, Vector2(0.05, 0.05) * s, part.lightened(0.3))
		"spirit":  # 머리 위 불꽃
			_polygon(img, _scaled([Vector2(0.5, 0.04), Vector2(0.6, 0.22), Vector2(0.5, 0.32), Vector2(0.4, 0.22)], s), part.lightened(0.4))
		"demon":
			_polygon(img, _scaled([Vector2(0.78, 0.74), Vector2(0.96, 0.62), Vector2(0.9, 0.78)], s), dark)


# ─── 그리기 도우미(이미지에 직접 칠한다) ────────────────

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


## 왼쪽(side = -1)은 그대로, 오른쪽(side = 1)은 가운데 기준으로 뒤집는다.
func _mirror(points: Array, side: float) -> Array:
	if side < 0.0:
		return points
	var out := []
	for p: Vector2 in points:
		out.append(Vector2(1.0 - p.x, p.y))
	return out


## 가운데에서 바깥으로 조금 키운 다각형(테두리용).
func _grow(points: Array, amount: float) -> Array:
	var center := Vector2.ZERO
	for p: Vector2 in points:
		center += p
	center /= points.size()
	var out := []
	for p: Vector2 in points:
		out.append(p + (p - center).normalized() * amount)
	return out


## 기울어진 타원의 둘레 점(0~1 좌표).
func _ellipse_points(center: Vector2, radii: Vector2, angle: float, count := 24) -> Array:
	var out := []
	for i in count:
		var t := TAU * i / count
		out.append(center + Vector2(cos(t) * radii.x, sin(t) * radii.y).rotated(angle))
	return out

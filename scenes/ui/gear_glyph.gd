class_name GearGlyph
extends RefCounted
## 장비 임시 그림(도형): 부위마다 하나, 무기는 직업마다(전사 방패 · 도적 단검 · 궁수 활 · 힐러 지팡이 · 버퍼 첼로).
## 아이템 칸(GearCard)과 인형 칸(GearDoll)이 같이 쓴다. 그림이 들어오면 이 파일 대신 아이콘 그림을 그린다.

## rect 안에 그 부위 그림을 color로 그린다.
static func draw(canvas: CanvasItem, kind: String, job_id: String, rect: Rect2, color: Color) -> void:
	var c := rect.get_center()
	var u := minf(rect.size.x, rect.size.y) * 0.5  # 반지름 단위
	var line := maxf(u * 0.12, 1.5)
	match kind:
		"weapon":
			_weapon(canvas, job_id, c, u, line, color)
		"helmet":
			var dome := PackedVector2Array()
			for i in 17:
				var angle := PI + PI * i / 16.0
				dome.append(c + Vector2(cos(angle) * u * 0.62, sin(angle) * u * 0.62 + u * 0.12))
			canvas.draw_colored_polygon(dome, color)
			canvas.draw_rect(Rect2(c + Vector2(-u * 0.75, u * 0.1), Vector2(u * 1.5, u * 0.18)), color)
			canvas.draw_rect(Rect2(c + Vector2(-u * 0.08, -u * 0.3), Vector2(u * 0.16, u * 0.55)), Color(0, 0, 0, 0.25))
		"armor":
			var body := PackedVector2Array([
				c + Vector2(-u * 0.32, -u * 0.62), c + Vector2(-u * 0.72, -u * 0.38), c + Vector2(-u * 0.6, -u * 0.05),
				c + Vector2(-u * 0.42, -u * 0.12), c + Vector2(-u * 0.42, u * 0.66), c + Vector2(u * 0.42, u * 0.66),
				c + Vector2(u * 0.42, -u * 0.12), c + Vector2(u * 0.6, -u * 0.05), c + Vector2(u * 0.72, -u * 0.38),
				c + Vector2(u * 0.32, -u * 0.62), c + Vector2(0, -u * 0.42),
			])
			canvas.draw_colored_polygon(body, color)
		"gloves":
			canvas.draw_rect(Rect2(c + Vector2(-u * 0.32, -u * 0.5), Vector2(u * 0.6, u * 0.78)), color)
			canvas.draw_circle(c + Vector2(-u * 0.02, -u * 0.5), u * 0.3, color, true, -1.0, true)
			canvas.draw_line(c + Vector2(u * 0.22, -u * 0.05), c + Vector2(u * 0.55, -u * 0.3), color, line * 2.2, true)
			canvas.draw_rect(Rect2(c + Vector2(-u * 0.38, u * 0.3), Vector2(u * 0.72, u * 0.3)), color)
		"boots":
			var boot := PackedVector2Array([
				c + Vector2(-u * 0.4, -u * 0.65), c + Vector2(u * 0.05, -u * 0.65), c + Vector2(u * 0.05, u * 0.12),
				c + Vector2(u * 0.62, u * 0.25), c + Vector2(u * 0.68, u * 0.6), c + Vector2(-u * 0.4, u * 0.6),
			])
			canvas.draw_colored_polygon(boot, color)
		"accessory":
			canvas.draw_arc(c + Vector2(0, u * 0.15), u * 0.42, 0.0, TAU, 28, color, line * 1.6, true)
			var gem := PackedVector2Array([c + Vector2(0, -u * 0.62), c + Vector2(u * 0.22, -u * 0.32), c + Vector2(0, -u * 0.12), c + Vector2(-u * 0.22, -u * 0.32)])
			canvas.draw_colored_polygon(gem, color)
		_:
			canvas.draw_circle(c, u * 0.4, color, true, -1.0, true)


static func _weapon(canvas: CanvasItem, job_id: String, c: Vector2, u: float, line: float, color: Color) -> void:
	match job_id:
		"warrior":  # 대형 방패
			var shield := PackedVector2Array([
				c + Vector2(0, -u * 0.72), c + Vector2(u * 0.58, -u * 0.5), c + Vector2(u * 0.5, u * 0.2),
				c + Vector2(0, u * 0.72), c + Vector2(-u * 0.5, u * 0.2), c + Vector2(-u * 0.58, -u * 0.5),
			])
			canvas.draw_colored_polygon(shield, color)
			canvas.draw_line(c + Vector2(0, -u * 0.5), c + Vector2(0, u * 0.5), Color(0, 0, 0, 0.25), line * 1.4, true)
		"rogue":  # 단검
			var tip := c + Vector2(u * 0.6, -u * 0.6)
			var guard := c + Vector2(-u * 0.22, u * 0.22)
			var side := Vector2(u * 0.12, u * 0.12)
			canvas.draw_colored_polygon(PackedVector2Array([tip, guard + side, guard - side]), color)
			canvas.draw_line(guard + Vector2(-u * 0.22, -u * 0.22), guard + Vector2(u * 0.22, u * 0.22), color, line * 1.6, true)
			canvas.draw_line(guard, c + Vector2(-u * 0.6, u * 0.6), color, line * 2.0, true)
		"archer":  # 활
			canvas.draw_arc(c + Vector2(-u * 0.35, 0), u * 0.75, -PI * 0.36, PI * 0.36, 20, color, line * 1.8, true)
			var top := c + Vector2(-u * 0.35, 0) + Vector2.from_angle(-PI * 0.36) * u * 0.75
			var bottom := c + Vector2(-u * 0.35, 0) + Vector2.from_angle(PI * 0.36) * u * 0.75
			canvas.draw_line(top, bottom, color, line * 0.6, true)
			canvas.draw_line(c + Vector2(-u * 0.55, 0), c + Vector2(u * 0.6, 0), color, line, true)
			canvas.draw_colored_polygon(PackedVector2Array([c + Vector2(u * 0.72, 0), c + Vector2(u * 0.5, -u * 0.12), c + Vector2(u * 0.5, u * 0.12)]), color)
		"healer":  # 지팡이
			canvas.draw_line(c + Vector2(-u * 0.45, u * 0.7), c + Vector2(u * 0.25, -u * 0.3), color, line * 1.8, true)
			canvas.draw_circle(c + Vector2(u * 0.36, -u * 0.44), u * 0.22, color, true, -1.0, true)
			canvas.draw_arc(c + Vector2(u * 0.36, -u * 0.44), u * 0.34, 0.0, TAU, 20, color, line * 0.7, true)
		"buffer":  # 첼로
			canvas.draw_circle(c + Vector2(0, u * 0.3), u * 0.36, color, true, -1.0, true)
			canvas.draw_circle(c + Vector2(0, -u * 0.12), u * 0.27, color, true, -1.0, true)
			canvas.draw_line(c + Vector2(0, -u * 0.3), c + Vector2(0, -u * 0.78), color, line * 1.4, true)
			canvas.draw_line(c + Vector2(-u * 0.55, u * 0.5), c + Vector2(u * 0.55, -u * 0.45), color, line * 0.7, true)
		_:
			canvas.draw_line(c + Vector2(-u * 0.6, u * 0.6), c + Vector2(u * 0.6, -u * 0.6), color, line * 2.0, true)

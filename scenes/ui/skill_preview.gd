@tool
class_name SkillPreview
extends Control
## 스킬 상세 창의 모션 미리보기(임시 도형, 사용자 결정 2026-10-03: 롤처럼 스킬을 누르면 모션을 미리 본다).
## 쿼터뷰 바닥 위에 시전자(종족 색 원) · 적(빨강) · 동료(초록)를 놓고, 효과 종류(motion)마다 짧은 연출을 되풀이한다.
## 범위가 있으면 바닥에 범위 타원을 그려 계수의 "반지름"이 얼마만 한지 보이게 한다(땅 위 px를 그대로 줄여 그림).
## 그림 단계에서 종마다 다른 공격 모션으로 바뀐다(사용자 결정 2026-10-02). @tool: 에디터에서도 강타가 돈다.

# 임시 도형 치수: 미리보기 폭에 들어오는 땅 위 거리(px) · 쿼터뷰 눌림 · 한 바퀴(초) · 유닛 반지름(땅 위 px)
const GROUND_WIDTH := 520.0
const SQUASH := 0.5
const LOOP_SECONDS := 2.4
const UNIT_RADIUS := 30.0
const NUMBER_FONT_SIZE := 16
const NUMBER_RISE := 50.0  # 땅 위 px
const NUMBER_SECONDS := 0.7
## 시전자 · 적 · 동료 자리(땅 위 px, 미리보기 가운데 기준)
const CASTER_HOME := Vector2(-170, 0)
const HEALER_HOME := Vector2(-40, 0)
const TARGET_AT := Vector2(130, 0)
const CLUSTER := [Vector2(0, 0), Vector2(55, -60), Vector2(70, 55), Vector2(115, 10)]
const ALLIES := [Vector2(80, 70), Vector2(-150, -90), Vector2(170, -80)]

## 미리보기 종류: SkillSheet의 motion(strike · flurry · blast · stun · taunt · heal · heal_all · passive · variant · inherit)
var motion := "strike":
	set(value):
		motion = value
		_started = Time.get_ticks_msec()
var radius := 0.0
var hits := 1
## 숫자로 띄울 값(0이면 숫자 없이 반짝임만)
var amount := 0
var caster_color := Color("e0603a")
var effect_color := Color("ff9a3d")

var _started := 0


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_started = Time.get_ticks_msec()


## 상세 창이 SkillSheet 내용으로 채운다.
func show_sheet(sheet: Dictionary, caster: Color, effect: Color) -> void:
	radius = float(sheet.get("radius", 0.0))
	hits = int(sheet.get("hits", 1))
	amount = int(sheet.get("amount", 0))
	caster_color = caster
	effect_color = effect
	motion = str(sheet.get("motion", "strike"))


func _process(_delta: float) -> void:
	queue_redraw()


## 한 바퀴 안의 지금 시각(초).
func _now() -> float:
	return fposmod((Time.get_ticks_msec() - _started) / 1000.0, LOOP_SECONDS)


## 땅 위 px → 이 노드 안 좌표.
func _at(ground: Vector2) -> Vector2:
	var k := size.x / GROUND_WIDTH
	return size * 0.5 + Vector2(ground.x, ground.y * SQUASH) * k + Vector2(0, size.y * 0.08)


func _scale() -> float:
	return size.x / GROUND_WIDTH


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Palette.PREVIEW_BG)
	var t := _now()
	match motion:
		"strike", "flurry":
			_draw_strike(t)
		"blast", "stun":
			_draw_blast(t)
		"taunt":
			_draw_taunt(t)
		"heal":
			_draw_heal(t)
		"heal_all":
			_draw_heal_all(t)
		_:
			_draw_aura(t)


# ─── 효과 종류마다 ─────────────────────────────

## 강타 · 연타: 다가가서 때리고(연타는 여러 번) 돌아온다.
func _draw_strike(t: float) -> void:
	var count := hits if motion == "flurry" else 1
	var gap := 0.12
	var reach := TARGET_AT - Vector2(UNIT_RADIUS * 2.0, 0)
	var dash := 0.3
	var last_hit := dash + gap * (count - 1)
	var caster := CASTER_HOME
	if t < dash:
		caster = CASTER_HOME.lerp(reach, ease(t / dash, 0.4))
	elif t < last_hit + 0.15:
		caster = reach + Vector2(sin(t * 60.0) * 3.0 if count > 1 else 0.0, 0)
	elif t < last_hit + 0.5:
		caster = reach.lerp(CASTER_HOME, ease((t - last_hit - 0.15) / 0.35, 1.8))
	var hurt := 0.0
	var recoil := 0.0
	for i in count:
		var at := dash + gap * i
		if t >= at:
			hurt += 0.6 / count
			recoil = maxf(recoil, 1.0 - (t - at) / 0.15)
			_draw_number(TARGET_AT, "-%d" % amount if amount > 0 else "", t - at, Palette.PREVIEW_DAMAGE, i)
	var target := TARGET_AT + Vector2(10.0 * maxf(recoil, 0.0), 0)
	_draw_unit(target, Palette.PREVIEW_ENEMY, 1.0 - hurt)
	if recoil > 0.0:
		draw_circle(_at(target), UNIT_RADIUS * _scale() * (1.0 + 0.3 * recoil), Color(effect_color, 0.5 * recoil), true, -1.0, true)
	_draw_unit(caster, caster_color, 1.0)


## 범위 · 기절: 구슬을 던지면 대상 자리에서 범위만큼 터진다(기절이면 맞은 적 위에 별이 돈다).
func _draw_blast(t: float) -> void:
	var fly := 0.45
	var center := TARGET_AT
	_draw_range(center, radius)
	var burst := clampf((t - fly) / 0.25, 0.0, 1.0)
	var fade := 1.0 - clampf((t - fly - 0.25) / 0.6, 0.0, 1.0)
	for offset: Vector2 in CLUSTER:
		var enemy := center + offset
		var inside := offset.length() <= radius
		var hurt := 0.5 if inside and t >= fly else 0.0
		_draw_unit(enemy, Palette.PREVIEW_ENEMY, 1.0 - hurt, not inside)
		if inside and t >= fly:
			_draw_number(enemy, "-%d" % amount if amount > 0 else "", t - fly, Palette.PREVIEW_DAMAGE)
			if motion == "stun" and t >= fly + 0.2:
				_draw_stars(enemy, t)
	if t < fly:
		var orb := CASTER_HOME.lerp(center, t / fly)
		var lift := sin(t / fly * PI) * 40.0
		draw_circle(_at(orb) - Vector2(0, lift * _scale() + UNIT_RADIUS * _scale()), 8.0 * _scale() + 3.0, effect_color, true, -1.0, true)
	elif fade > 0.0:
		_draw_ring(center, radius * burst, Color(effect_color, 0.8 * fade), 4.0)
		_draw_disc(center, radius * burst, Color(effect_color, 0.22 * fade))
	_draw_unit(CASTER_HOME, caster_color, 1.0)


## 도발 + 보호막: 둘레로 고리가 퍼지고 적이 "!" 하며 나에게 몰려온다. 나는 보호막을 두른다.
func _draw_taunt(t: float) -> void:
	var home := HEALER_HOME
	_draw_range(home, radius)
	var ring := clampf(t / 0.4, 0.0, 1.0)
	var fade := 1.0 - clampf((t - 0.4) / 0.4, 0.0, 1.0)
	if fade > 0.0:
		_draw_ring(home, radius * ring, Color(effect_color, 0.8 * fade), 4.0)
	for offset: Vector2 in [Vector2(150, -30), Vector2(110, 70), Vector2(-200, 60)]:
		var start := home + offset
		var inside := offset.length() <= radius
		var pull := clampf((t - 0.5) / 0.9, 0.0, 1.0) if inside else 0.0
		var stop := home + offset.normalized() * UNIT_RADIUS * 2.4
		var enemy := start.lerp(stop, ease(pull, 0.6))
		_draw_unit(enemy, Palette.PREVIEW_ENEMY, 1.0, not inside)
		if inside and t >= 0.4 and t < 1.6:
			_draw_text(enemy, "!", Palette.PREVIEW_DAMAGE, UNIT_RADIUS * 2.2)
	_draw_unit(home, caster_color, 1.0)
	if t >= 0.3:
		var on := clampf((t - 0.3) / 0.2, 0.0, 1.0)
		draw_circle(_at(home) - Vector2(0, UNIT_RADIUS * _scale()), UNIT_RADIUS * _scale() * 1.7, Color(Palette.SHIELD_BAR, 0.25 * on), true, -1.0, true)
		draw_arc(_at(home) - Vector2(0, UNIT_RADIUS * _scale()), UNIT_RADIUS * _scale() * 1.7, 0.0, TAU, 32, Color(Palette.SHIELD_BAR, 0.8 * on), 2.0, true)
		if amount > 0:
			_draw_number(home, "+%d" % amount, t - 0.3, Palette.SHIELD_BAR)


## 회복: 초록 구슬이 체력이 가장 낮은 동료에게 날아가 체력이 찬다.
func _draw_heal(t: float) -> void:
	var ally: Vector2 = ALLIES[0]
	var fly := 0.4
	var filled := clampf((t - fly) / 0.3, 0.0, 1.0)
	_draw_unit(ally, Palette.PREVIEW_ALLY, lerpf(0.3, 0.8, filled))
	_draw_unit(Vector2(-60, -90), Palette.PREVIEW_ALLY, 0.9)
	if t < fly:
		var orb := HEALER_HOME.lerp(ally, t / fly)
		draw_circle(_at(orb) - Vector2(0, UNIT_RADIUS * _scale()), 7.0 * _scale() + 3.0, effect_color, true, -1.0, true)
	else:
		_draw_number(ally, "+%d" % amount if amount > 0 else "+", t - fly, Palette.PREVIEW_HEAL)
		_draw_sparkles(ally, t - fly)
	_draw_unit(HEALER_HOME, caster_color, 1.0)


## 범위 회복: 초록 고리가 둘레로 퍼지고 범위 안 동료가 모두 찬다.
func _draw_heal_all(t: float) -> void:
	var home := HEALER_HOME
	_draw_range(home, radius)
	var ring := clampf(t / 0.45, 0.0, 1.0)
	var fade := 1.0 - clampf((t - 0.45) / 0.5, 0.0, 1.0)
	if fade > 0.0:
		_draw_ring(home, radius * ring, Color(effect_color, 0.8 * fade), 4.0)
		_draw_disc(home, radius * ring, Color(effect_color, 0.15 * fade))
	for offset: Vector2 in ALLIES:
		var inside := (offset - home).length() <= radius
		var reached := inside and t >= 0.45 * (offset - home).length() / maxf(radius, 1.0)
		_draw_unit(offset, Palette.PREVIEW_ALLY, 0.85 if reached else 0.4, not inside)
		if reached:
			var since := t - 0.45 * (offset - home).length() / maxf(radius, 1.0)
			_draw_number(offset, "+%d" % amount if amount > 0 else "+", since, Palette.PREVIEW_HEAL)
	_draw_unit(home, caster_color, 1.0)


## 패시브 · 변이 · 계승: 늘 켜져 있는 효과라 시전자 둘레에 은은한 빛(변이는 보라 반짝임이 돈다).
func _draw_aura(t: float) -> void:
	var home := Vector2.ZERO
	var pulse := 0.5 + 0.5 * sin(t / LOOP_SECONDS * TAU * 2.0)
	var center := _at(home) - Vector2(0, UNIT_RADIUS * _scale())
	draw_circle(center, UNIT_RADIUS * _scale() * (1.6 + 0.3 * pulse), Color(effect_color, 0.12 + 0.12 * pulse), true, -1.0, true)
	_draw_unit(home, caster_color, 1.0)
	if motion == SkillSheet.MOTION_VARIANT:
		for i in 3:
			var angle := t / LOOP_SECONDS * TAU + i * TAU / 3.0
			var spot := center + Vector2(cos(angle), sin(angle) * SQUASH) * UNIT_RADIUS * _scale() * 2.0
			draw_circle(spot, 4.0, effect_color, true, -1.0, true)
	elif motion == SkillSheet.MOTION_INHERIT:
		_draw_number(home, "+", fposmod(t, 1.2), effect_color)


# ─── 도형 도우미 ─────────────────────────────

## 유닛: 바닥 그림자 + 몸(원) + 체력 바. faded면 범위 밖이라 흐리게.
func _draw_unit(ground: Vector2, color: Color, hp_ratio: float, faded := false) -> void:
	var k := _scale()
	var foot := _at(ground)
	var r := UNIT_RADIUS * k
	var alpha := 0.45 if faded else 1.0
	_draw_ellipse(foot, Vector2(r * 1.1, r * 0.45), Color(Palette.PREVIEW_SHADOW, Palette.PREVIEW_SHADOW.a * alpha))
	var body := foot - Vector2(0, r)
	draw_circle(body, r, Color(color, alpha), true, -1.0, true)
	draw_arc(body, r, 0.0, TAU, 24, Color(Palette.TEXT_OUTLINE, 0.6 * alpha), 1.5, true)
	var bar := Rect2(body + Vector2(-r, -r - 9.0), Vector2(r * 2.0, 4.0))
	draw_rect(bar, Color(Palette.PREVIEW_HP_BG, alpha))
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * clampf(hp_ratio, 0.0, 1.0), bar.size.y)), Color(Palette.PREVIEW_HP, alpha))


## 바닥 범위(땅 위 반지름)를 옅은 타원으로.
func _draw_range(ground: Vector2, ground_radius: float) -> void:
	if ground_radius <= 0.0:
		return
	_draw_ring(ground, ground_radius, Palette.PREVIEW_RANGE, 2.0)


func _draw_ring(ground: Vector2, ground_radius: float, color: Color, width: float) -> void:
	if ground_radius <= 1.0:
		return
	var k := _scale()
	var points := PackedVector2Array()
	for i in 41:
		var a := TAU * i / 40.0
		points.append(_at(ground) + Vector2(cos(a), sin(a) * SQUASH) * ground_radius * k)
	draw_polyline(points, color, width, true)


func _draw_disc(ground: Vector2, ground_radius: float, color: Color) -> void:
	if ground_radius <= 1.0:
		return
	_draw_ellipse(_at(ground), Vector2(ground_radius, ground_radius * SQUASH) * _scale(), color)


func _draw_ellipse(center: Vector2, half: Vector2, color: Color) -> void:
	if half.x < 1.0 or half.y < 1.0:
		return
	var points := PackedVector2Array()
	for i in 32:
		var a := TAU * i / 32.0
		points.append(center + Vector2(cos(a) * half.x, sin(a) * half.y))
	draw_colored_polygon(points, color)


## 떠오르며 사라지는 숫자(since = 뜬 뒤 지난 초). order만큼 옆으로 비켜 겹치지 않게.
func _draw_number(ground: Vector2, text: String, since: float, color: Color, order := 0) -> void:
	if text == "" or since < 0.0 or since > NUMBER_SECONDS:
		return
	var rise := UNIT_RADIUS * 2.6 + NUMBER_RISE * since / NUMBER_SECONDS
	var shifted := ground + Vector2(order * 18.0, 0)
	_draw_text(shifted, text, Color(color, 1.0 - since / NUMBER_SECONDS), rise)


## 유닛 머리 위(above = 땅에서 위로 몇 px, 땅 위 단위)에 글자.
func _draw_text(ground: Vector2, text: String, color: Color, above: float) -> void:
	var font := UiKit.bold_font()
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, NUMBER_FONT_SIZE).x
	var at := _at(ground) - Vector2(width * 0.5, above * _scale())
	draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, NUMBER_FONT_SIZE, 4, Color(Palette.TEXT_OUTLINE, color.a))
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, NUMBER_FONT_SIZE, color)


## 기절 별: 머리 위를 빙빙 돈다.
func _draw_stars(ground: Vector2, t: float) -> void:
	var k := _scale()
	var top := _at(ground) - Vector2(0, UNIT_RADIUS * k * 2.3)
	for i in 3:
		var a := t * 5.0 + i * TAU / 3.0
		draw_circle(top + Vector2(cos(a) * 12.0, sin(a) * 4.0), 3.0, Palette.STUN_STAR, true, -1.0, true)


## 회복 반짝임: 몸 둘레로 작은 점이 올라간다.
func _draw_sparkles(ground: Vector2, since: float) -> void:
	if since > 0.6:
		return
	var k := _scale()
	var body := _at(ground) - Vector2(0, UNIT_RADIUS * k)
	for i in 4:
		var x := (i - 1.5) * 10.0
		var y := -since * 50.0 - i * 4.0
		draw_circle(body + Vector2(x, y), 2.5, Color(Palette.PREVIEW_HEAL, 1.0 - since / 0.6), true, -1.0, true)

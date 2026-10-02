class_name HpBar
extends RefCounted
## 체력 바(머리 위 · 화면 위 대상 창 공용). 방금 깎인 만큼은 밝은 "잔상"으로 남겼다가 천천히 줄인다.
## 칸 나누기(눈금)는 넣지 않는다. 나중에 섬의 왕 체력 바를 패턴 구간마다 나눌 때 쓴다(사용자 결정 2026-10-02).


## 잔상의 다음 값(0~1). 체력이 줄면 잔상은 GameConfig.HP_TRAIL_SPEED 빠르기로 따라 내려오고, 늘면 바로 따라 올라간다.
static func next_trail(trail: float, ratio: float, delta: float) -> float:
	if ratio >= trail:
		return ratio
	return maxf(trail - GameConfig.HP_TRAIL_SPEED * delta, ratio)


## 체력 바를 그린다. canvas의 _draw() 안에서만 부른다. ratio = 남은 체력 비율, trail = 잔상 비율.
static func draw(canvas: CanvasItem, rect: Rect2, ratio: float, trail: float, fill: Color) -> void:
	canvas.draw_rect(rect.grow(1.0), Palette.HP_BAR_BACK)
	if trail > ratio:
		canvas.draw_rect(Rect2(rect.position, Vector2(rect.size.x * trail, rect.size.y)), Palette.HP_BAR_TRAIL)
	canvas.draw_rect(Rect2(rect.position, Vector2(rect.size.x * ratio, rect.size.y)), fill)

class_name Targeting
extends RefCounted
## 대상 고르기(순수 함수). 화면에서 몹을 눌러 지정하거나(두 번 누르면 바로 공격), 공격 버튼을 눌렀을 때 가까운 적을 고른다.


## 누른 자리(at)에서 radius 안에 있는 점 중 가장 가까운 것의 번호. 없으면 -1.
## 손가락이 닿은 자리 기준이라 화면에서 보이는 거리 그대로 잰다(points = 몹의 몸 가운데).
static func index_at(points: PackedVector2Array, at: Vector2, radius: float) -> int:
	var best := -1
	var best_distance := radius
	for i in points.size():
		var d := points[i].distance_to(at)
		if d <= best_distance:
			best = i
			best_distance = d
	return best


## from에서 땅 위 거리 max_distance 안에 있는 점 중 가장 가까운 것의 번호. 없으면 -1.
static func nearest_within(points: PackedVector2Array, from: Vector2, max_distance: float) -> int:
	var best := -1
	var best_distance := max_distance
	for i in points.size():
		var d := Iso.ground_distance(from, points[i])
		if d <= best_distance:
			best = i
			best_distance = d
	return best


## 더블 탭인가: 같은 몹을 GameConfig.DOUBLE_TAP_SECONDS 안에 다시 눌렀나. 시각은 밀리초.
static func is_double_tap(previous_ms: int, now_ms: int, same_unit: bool) -> bool:
	return same_unit and now_ms - previous_ms <= GameConfig.DOUBLE_TAP_SECONDS * 1000.0

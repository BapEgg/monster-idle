class_name SaveSchedule
extends RefCounted
## 묶어서 저장하기(순수 계산). 기획서 9장: 처치마다 저장하면 저장 횟수만큼 서버 요금이 나간다.
## 바뀐 것이 생기면 표시(mark_dirty)만 해 두고, interval초가 지나면 한 번 저장한다. 그 사이에 바뀐 것은 모두 그 한 번에 묶인다.
## 사용자가 직접 한 일(urgent)은 soon초 뒤로 앞당긴다(믹스한 뒤 바로 꺼도 남게).

var interval: float
var soon: float
## 아직 저장하지 않은 바뀐 것이 있나
var dirty := false

var _left := 0.0  # 저장까지 남은 시간(초)


func _init(interval_seconds: float, soon_seconds: float) -> void:
	interval = interval_seconds
	soon = soon_seconds


## 바뀐 것이 생겼다. 이미 기다리는 중이면 기다리는 시간을 늘리지 않는다(계속 바뀌어도 interval마다 한 번은 저장).
func mark_dirty(urgent := false) -> void:
	if not dirty:
		dirty = true
		_left = interval
	if urgent:
		_left = minf(_left, soon)


## 시간을 흘린다. 지금 저장할 때면 true를 돌려주고 표시를 지운다.
func tick(delta: float) -> bool:
	if not dirty:
		return false
	_left -= delta
	if _left > 0.0:
		return false
	dirty = false
	return true


## 방금 저장했다(끌 때처럼 기다리지 않고 바로 저장한 경우).
func clear() -> void:
	dirty = false

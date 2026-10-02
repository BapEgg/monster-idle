class_name HuntLog
extends RefCounted
## 사냥 기록(프로토타입 4: 하루 처치 수 측정). 기획서 8장: 드랍률 = 하루 목표 ÷ 하루 처치 수.
## 자동·수동을 나눠 사냥한 시간과 처치 수를 세서 시간당 처치 수를 내고,
## 하루 예상 처치 수 = 자동 시간당 처치 수 × 24(방치형이라 하루 종일 자동으로 돈다고 본다).
## 수동 시간당 ÷ 자동 시간당으로 "수동이 얼마나 이득인지"(기획서 7장 목표 10~20%)도 본다.

const SECONDS_PER_HOUR := 3600.0
const HOURS_PER_DAY := 24.0

var auto_seconds := 0.0
var manual_seconds := 0.0
var auto_kills := 0
var manual_kills := 0
var cores := 0
var shining_cores := 0


func add_time(seconds: float, manual: bool) -> void:
	if manual:
		manual_seconds += seconds
	else:
		auto_seconds += seconds


func add_kill(manual: bool) -> void:
	if manual:
		manual_kills += 1
	else:
		auto_kills += 1


func add_core(item: CoreItem) -> void:
	cores += 1
	if item.shining:
		shining_cores += 1


func kills() -> int:
	return auto_kills + manual_kills


## 시간당 처치 수. 그 방식으로 사냥한 시간이 없으면 -1(아직 모름).
func kills_per_hour(manual: bool) -> float:
	var seconds := manual_seconds if manual else auto_seconds
	if seconds <= 0.0:
		return -1.0
	return (manual_kills if manual else auto_kills) / seconds * SECONDS_PER_HOUR


## 하루 예상 처치 수(자동 시간당 × 24). 자동으로 사냥한 시간이 없으면 -1.
func daily_kills_estimate() -> float:
	var per_hour := kills_per_hour(false)
	return per_hour * HOURS_PER_DAY if per_hour >= 0.0 else -1.0


## 수동이 자동보다 얼마나 빠른가(0.15 = 15% 더 많이 잡음). 둘 중 하나라도 모르면 NAN.
func manual_advantage() -> float:
	var auto := kills_per_hour(false)
	var manual := kills_per_hour(true)
	if auto <= 0.0 or manual < 0.0:
		return NAN
	return manual / auto - 1.0

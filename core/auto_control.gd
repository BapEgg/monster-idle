class_name AutoControl
extends RefCounted
## 사냥 방식(화면 오른쪽 아래 3단계 버튼)과 "손대면 수동" 판단. 사용자 결정(2026-10-02).
## - 풀오토: 자동 사냥. 조작(입력)이 있는 동안만 수동이고, 손을 뗀 뒤 return_seconds가 지나면 자동으로 돌아온다.
##   return_seconds = 0이면 손을 떼는 즉시 자동이다(현재 기본값).
## - 세미오토: 이동은 직접, 사거리 안의 적은 자동으로 공격한다.
## - 수동: 이동도 공격도 직접 한다(공격 버튼).
## 설정의 네 가지(자동 사냥 / 수동 사냥 / 스킬만 자동 / 공격만 자동) 중 "스킬만 자동"·"공격만 자동"은
## 세미오토의 세부로 고르게 할 자리다. 스킬이 아직 없어서 지금 세미오토는 "공격만 자동"이다.

enum Mode { FULL_AUTO, SEMI_AUTO, MANUAL }

var mode := Mode.FULL_AUTO
var return_seconds := 3.0

var _since_input := INF  # 마지막 입력 뒤 지난 시간. INF = 한 번도 안 만짐
var _held := false


func _init(seconds: float, start_mode := Mode.FULL_AUTO) -> void:
	return_seconds = seconds
	mode = start_mode


## 매 프레임 부른다. has_input = 지금 키·조이스틱을 만지고 있나.
func update(delta: float, has_input: bool) -> void:
	_held = has_input
	if has_input:
		_since_input = 0.0
	else:
		_since_input += delta


## 이동을 직접 하나. 풀오토에서는 만지는 동안(과 자동 복귀 대기 동안)만, 세미오토·수동은 늘 그렇다.
func is_manual() -> bool:
	if mode != Mode.FULL_AUTO:
		return true
	return _held or _since_input < return_seconds


## 사거리 안의 적을 알아서 공격하나. 수동만 공격 버튼으로 직접 한다.
func auto_attacks() -> bool:
	return mode != Mode.MANUAL


## 지금 손을 대고 있나(수동 중에서도 "조작 중"과 "자동 복귀 대기"를 가른다).
func is_held() -> bool:
	return _held


func seconds_until_auto() -> float:
	return maxf(return_seconds - _since_input, 0.0)

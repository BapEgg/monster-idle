class_name AutoControl
extends RefCounted
## "손대면 수동": 조작(입력)이 있는 동안은 수동이고, 손을 뗀 뒤 return_seconds가 지나면 자동으로 돌아온다.
## return_seconds = 0이면 손을 떼는 즉시 자동이다(현재 기본값, 사용자 결정 2026-10-02).
## 나중에 설정 옵션(자동 사냥 / 수동 사냥 / 스킬만 자동 / 공격만 자동)이 생기면 그 선택도 이 클래스가 맡는다.

var return_seconds := 3.0

var _since_input := INF  # 마지막 입력 뒤 지난 시간. INF = 한 번도 안 만짐
var _held := false


func _init(seconds: float) -> void:
	return_seconds = seconds


## 매 프레임 부른다. has_input = 지금 키·조이스틱을 만지고 있나.
func update(delta: float, has_input: bool) -> void:
	_held = has_input
	if has_input:
		_since_input = 0.0
	else:
		_since_input += delta


func is_manual() -> bool:
	return _held or _since_input < return_seconds


## 지금 손을 대고 있나(수동 중에서도 "조작 중"과 "자동 복귀 대기"를 가른다).
func is_held() -> bool:
	return _held


func seconds_until_auto() -> float:
	return maxf(return_seconds - _since_input, 0.0)

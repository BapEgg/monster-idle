extends RefCounted
## 테스트 묶음의 바탕. test_*.gd 파일은 이 파일을 extends 하고, test_ 로 시작하는 함수를 만든다.
## expect_* 로 확인하고, 실패는 failures에 모인다.

var checks := 0
var failures := PackedStringArray()
var current_test := ""


func expect_true(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append("%s · %s" % [current_test, label])


func expect_near(actual: float, expected: float, label: String, tolerance := 0.001) -> void:
	expect_true(absf(actual - expected) <= tolerance, "%s (기대 %s, 실제 %s)" % [label, expected, actual])


func expect_vec(actual: Vector2, expected: Vector2, label: String, tolerance := 0.001) -> void:
	expect_true(actual.distance_to(expected) <= tolerance, "%s (기대 %s, 실제 %s)" % [label, expected, actual])

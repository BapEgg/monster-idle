class_name SkillTimer
extends RefCounted
## 스킬 하나의 대기 시간(헨치 고유 액티브 HenchSkill · 주인공 직업 스킬 JobSkill이 함께 쓴다). 스킬 칸(SkillSlot)이 이것만 보고 그린다.

## 화면에 보일 스킬 이름
var title := ""
## 스킬 그림(메인 화면 스킬 칸의 바탕). 없으면 칸이 주인 색 + 이름으로 대신 그린다.
var icon: Texture2D
var cooldown := 0.0
## 다시 쓰기까지 남은 시간(초). 0이면 쓸 수 있다.
var left := 0.0


func is_ready() -> bool:
	return left <= 0.0


func tick(delta: float) -> void:
	left = maxf(left - delta, 0.0)


func use() -> void:
	left = cooldown


## 남은 대기의 비율(1 = 막 씀, 0 = 쓸 수 있음). 스킬 칸의 어두운 덮개가 이만큼 남는다.
func wait_ratio() -> float:
	return clampf(left / cooldown, 0.0, 1.0) if cooldown > 0.0 else 0.0

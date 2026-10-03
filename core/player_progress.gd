class_name PlayerProgress
extends RefCounted
## 주인공 레벨과 경험치(성장 1차). 처치하면 경험치가 쌓이고(Growth.exp_per_kill), 다 차면 레벨이 오른다(Growth.add_exp).
## 헨치(코어) 골드 레벨업의 상한이 이 레벨이다. 저장된다(GameSave).

## 레벨이나 경험치가 바뀌었을 때(HUD 레벨 막대)
signal changed
## 레벨이 올랐을 때(새 레벨). main이 능력치를 다시 정하고 연출을 띄운다.
signal leveled_up(level: int)

var level := 1
## 지금 레벨에서 모은 경험치
var exp_points := 0


## 경험치를 더한다. 오른 레벨 수를 돌려준다.
func gain(amount: int) -> int:
	var before := level
	var result := Growth.add_exp(level, exp_points, amount)
	level = result.x
	exp_points = result.y
	changed.emit()
	if level > before:
		leveled_up.emit(level)
	return level - before


## 다음 레벨까지 필요한 경험치(최고 레벨이면 0).
func exp_to_next() -> int:
	return Growth.exp_to_next(level)


## 다음 레벨까지 찬 비율(0~1, 최고 레벨이면 1).
func progress() -> float:
	var need := exp_to_next()
	return 1.0 if need <= 0 else float(exp_points) / need


func is_max() -> bool:
	return level >= GameConfig.MAX_LEVEL


func to_dict() -> Dictionary:
	return {"level": level, "exp": exp_points}


func load_dict(row: Dictionary) -> void:
	level = clampi(int(row.get("level", 1)), 1, GameConfig.MAX_LEVEL)
	exp_points = 0 if is_max() else clampi(int(row.get("exp", 0)), 0, maxi(exp_to_next() - 1, 0))
	changed.emit()

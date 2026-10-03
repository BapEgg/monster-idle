class_name MixMastery
extends RefCounted
## 믹스 숙련도(기획서 4장 믹스 세부 규칙): 1~9단계. 믹스할 때마다 경험치(성공 100% · 실패 50%),
## 단계마다 성공 확률이 조금씩 오른다. 수치는 GameConfig.MIX_MASTERY_*(초안). 저장된다(GameSave).

var level := 1
## 지금 단계에서 모은 경험치
var exp_points := 0


## 믹스 한 번에 얻는 경험치(성공 100% · 실패 50%). 마지막 단계면 0.
func exp_for(success: bool) -> int:
	if is_max():
		return 0
	var amount := GameConfig.MIX_MASTERY_EXP_PER_MIX
	if not success:
		amount = roundi(amount * GameConfig.MIX_MASTERY_FAIL_EXP_RATE)
	return amount


## 믹스 한 번의 경험치를 더한다. 단계가 올랐으면 true.
func gain(success: bool) -> bool:
	if is_max():
		return false
	exp_points += exp_for(success)
	var leveled := false
	while not is_max() and exp_points >= exp_to_next():
		exp_points -= exp_to_next()
		level += 1
		leveled = true
	if is_max():
		exp_points = 0
	return leveled


func is_max() -> bool:
	return level >= GameConfig.MIX_MASTERY_MAX_LEVEL


## 다음 단계까지 필요한 경험치(마지막 단계면 0).
func exp_to_next() -> int:
	if is_max():
		return 0
	return int(GameConfig.MIX_MASTERY_EXP_TO_NEXT[level - 1])


## 다음 단계까지 찬 비율(0~1, 마지막 단계면 1). 숙련도 막대.
func progress() -> float:
	return 1.0 if is_max() else float(exp_points) / exp_to_next()


## 성공 확률 보너스(1단계 = 0).
func success_bonus() -> float:
	return (level - 1) * GameConfig.MIX_MASTERY_BONUS_PER_LEVEL


func to_dict() -> Dictionary:
	return {"level": level, "exp": exp_points}


func load_dict(row: Dictionary) -> void:
	level = clampi(int(row.get("level", 1)), 1, GameConfig.MIX_MASTERY_MAX_LEVEL)
	exp_points = 0 if is_max() else clampi(int(row.get("exp", 0)), 0, exp_to_next() - 1)

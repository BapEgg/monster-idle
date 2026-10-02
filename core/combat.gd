class_name Combat
extends RefCounted
## 전투 계산(순수 함수). 장면과 떨어져 있어 tests/에서 바로 검사한다.


## 회복할 대상: 체력 비율이 threshold보다 낮은 것 중 가장 낮은 것의 번호. 없으면 -1.
static func heal_target_index(hp_ratios: Array[float], threshold: float) -> int:
	var best := -1
	for i in hp_ratios.size():
		if hp_ratios[i] < threshold and (best == -1 or hp_ratios[i] < hp_ratios[best]):
			best = i
	return best


## 공격자가 얻는 위협 점수. 야생 헨치는 위협 점수가 가장 높은 상대를 노린다.
## 탱커는 몇 배로 얻어서 적을 끌어당긴다.
static func threat(damage: float, is_tank: bool) -> float:
	return damage * (GameConfig.TANK_THREAT_SCALE if is_tank else 1.0)

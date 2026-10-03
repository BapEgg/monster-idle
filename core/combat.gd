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


## 보호막이 먼저 피해를 받는다. 돌려주는 값: x = 몸에 들어가는 피해, y = 남은 보호막.
static func absorb(shield: float, damage: float) -> Vector2:
	var blocked := minf(maxf(shield, 0.0), damage)
	return Vector2(damage - blocked, shield - blocked)


## 실제로 들어가는 피해. 기습(아직 파티를 알아채지 못한 적에게 수동 조작 중에 넣은 첫 타)이면 배율만큼 세다.
## 사용자 결정(2026-10-02): 기습 보너스는 수동 중일 때만 준다. 자동 사냥은 손해가 아니라 보너스가 없을 뿐이다.
static func hit_damage(damage: float, ambush: bool) -> float:
	return damage * (GameConfig.AMBUSH_SCALE if ambush else 1.0)

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
## bonus = 공격한 쪽의 기습 배율 보너스(직업 패시브: 기습의 달인).
static func hit_damage(damage: float, ambush: bool, bonus := 0.0) -> float:
	return damage * (GameConfig.AMBUSH_SCALE + bonus if ambush else 1.0)


## 치명타인가: roll(0~1 균등)이 치명 확률보다 작으면.
static func is_crit(chance: float, roll: float) -> bool:
	return roll < clampf(chance, 0.0, 1.0)


## 치명타면 치명 피해 배율만큼(배율이 1보다 작아도 줄지는 않는다).
static func crit_hit(damage: float, crit: bool, scale: float) -> float:
	return damage * maxf(scale, 1.0) if crit else damage


## 스킬 피해 · 회복(기획서 4장 "스킬별 다중 스탯 계수"): Σ 계수 × 능력치 × 환산값(GameConfig.SKILL_DAMAGE_PER_STAT / SKILL_HEAL_PER_STAT).
## coefs = {능력치 id: 계수}, stats = {능력치 id: 값}(코어 · 주인공 능력치 9종). 없는 능력치는 0.
static func skill_amount(coefs: Dictionary, stats: Dictionary, heal := false) -> float:
	var total := 0.0
	for stat: String in coefs:
		total += float(coefs[stat]) * float(stats.get(stat, 0.0))
	return total * (GameConfig.SKILL_HEAL_PER_STAT if heal else GameConfig.SKILL_DAMAGE_PER_STAT)

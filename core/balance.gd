class_name Balance
extends RefCounted
## 밸런스 1차(기획서 8장): 확률은 "하루 목표 획득량"을 먼저 정하고 거꾸로 계산한다(순수 함수).
##   드랍률 = 하루 목표 ÷ 하루 처치 수. 하루 처치 수는 프로토타입에서 잰 값(GameConfig.MEASURED_DAILY_KILLS, tools/measure_hunt.gd).
##   목표가 범위(예: 하루 10~15개)면 가운데를 쓴다.
## 확률 보너스(마크 · 수동 우대 …)는 모두 더한 뒤(B) 수확 체감: 유효 보너스 = B × K ÷ (B + K), 최종 = 기본 × (1 + 유효 보너스).
## 개발 확인용 배율(dev_boost)은 디버그 화면에서 켜고 끈다. 켜면 코어·변이 확률에 곱한다(빛나는 비율은 그대로).

const DAYS_PER_WEEK := 7.0
const DAYS_PER_MONTH := 30.0

## 개발 확인용 드랍 배율(1 = 실제 값). 디버그 화면의 "드랍 확인" 버튼이 바꾼다. 저장하지 않는다.
static var dev_boost := 1.0


## 하루 목표 ÷ 하루 처치 수(0~1). 처치 수를 모르면(0 이하) 0.
static func drop_chance(daily_target: float, daily_kills: float) -> float:
	if daily_kills <= 0.0:
		return 0.0
	return clampf(daily_target / daily_kills, 0.0, 1.0)


## 목표 범위(최소, 최대)의 가운데를 하루치로(days일에 그만큼이 목표).
static func per_day(target_range: Vector2, days: float) -> float:
	return (target_range.x + target_range.y) * 0.5 / days


## 하루 처치 수로 거꾸로 계산한 기본 확률(보너스 · 개발 배율 빼고):
## core = 처치당 코어, shining = 떨어진 코어가 빛나는 비율, variant = 야생이 변이체로 나올 확률.
static func chances_for(daily_kills: float) -> Dictionary:
	var cores := per_day(GameConfig.TARGET_CORES_PER_DAY, 1.0)
	return {
		"core": drop_chance(cores, daily_kills),
		"shining": clampf(per_day(GameConfig.TARGET_SHINING_PER_WEEK, DAYS_PER_WEEK) / cores, 0.0, 1.0),
		"variant": drop_chance(per_day(GameConfig.TARGET_VARIANTS_PER_MONTH, DAYS_PER_MONTH), daily_kills),
	}


## 그 확률로 하루 처치 수만큼 잡았을 때 얻는 양: 하루 코어 · 주 빛나는 코어 · 월 변이체(디버그 화면의 "목표 대비").
static func expected(daily_kills: float, core: float, shining: float, variant: float) -> Dictionary:
	var cores := daily_kills * core
	return {
		"cores_per_day": cores,
		"shining_per_week": cores * shining * DAYS_PER_WEEK,
		"variants_per_month": daily_kills * variant * DAYS_PER_MONTH,
	}


## 수확 체감: 더한 보너스 B(0.2 = +20%)의 유효 보너스 = B × K ÷ (B + K). 보너스가 없으면 0.
static func effective_bonus(total_bonus: float, k: float) -> float:
	if total_bonus <= 0.0 or k <= 0.0:
		return 0.0
	return total_bonus * k / (total_bonus + k)


## 기본 확률에 보너스(수확 체감)를 붙인 최종 확률(1을 넘지 않는다).
static func with_bonus(base: float, total_bonus: float, k: float) -> float:
	return minf(base * (1.0 + effective_bonus(total_bonus, k)), 1.0)


# ─── 게임에서 쓰는 확률(잰 하루 처치 수 기준 + 개발 배율) ─────────────

static func core_chance() -> float:
	return minf(chances_for(GameConfig.MEASURED_DAILY_KILLS)["core"] * dev_boost, 1.0)


static func shining_chance() -> float:
	return chances_for(GameConfig.MEASURED_DAILY_KILLS)["shining"]


## 야생이 변이체로 나올 확률. bonus = 더한 보너스(수동 중이면 GameConfig.MANUAL_VARIANT_BONUS), 변이체 K로 수확 체감.
static func variant_chance(bonus := 0.0) -> float:
	var base: float = chances_for(GameConfig.MEASURED_DAILY_KILLS)["variant"] * dev_boost
	return with_bonus(base, bonus, GameConfig.VARIANT_BONUS_K)

class_name BossRules
extends RefCounted
## 섬의 왕 보스전 규칙(순수 계산): 체력 구간(체력 바 눈금)과 구간마다 쓰는 장판의 차례.
## 수치는 GameConfig.BOSS_PHASES · BOSS_PATTERNS(연습용 임시 보스, 왕별 규칙은 기획서에서 미정).


## 남은 체력 비율 → 구간 번호(0부터).
static func phase_index(hp_ratio: float) -> int:
	var phases: Array = GameConfig.BOSS_PHASES
	for i in phases.size():
		if hp_ratio > float(phases[i]["until"]):
			return i
	return phases.size() - 1


## 체력 바에 그을 눈금(구간 경계 비율들, 0은 빼고).
static func phase_marks() -> Array[float]:
	var marks: Array[float] = []
	for phase: Dictionary in GameConfig.BOSS_PHASES:
		if float(phase["until"]) > 0.0:
			marks.append(float(phase["until"]))
	return marks


## 그 구간에서 count번째로 쓸 장판(차례대로 돌아간다 — 외워서 피할 수 있게).
static func pattern_at(phase: int, count: int) -> String:
	var patterns: Array = GameConfig.BOSS_PHASES[phase]["patterns"]
	return patterns[count % patterns.size()]


## 그 구간의 장판 사이 간격(초).
static func pattern_interval(phase: int) -> float:
	return float(GameConfig.BOSS_PHASES[phase]["interval"])

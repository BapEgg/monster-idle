class_name Affinity
extends RefCounted
## 종족 상성(사용자 결정 2026-10-03, 믹스마스터 상성 원 → 우리 세계관으로 고친 추천 A):
## 정령 → 마 → 용 → 비행 → 곤충 → 식물 → 기계 → 야수 → 정령. 화살표 앞 종족이 뒤 종족에게 강하다(data/tribes.json의 beats).
## 모든 종족이 하나에게 강하고 하나에게 약하다. 강한 상대를 때리면 주는 피해 +GameConfig.AFFINITY_ADVANTAGE,
## 약한 상대(나에게 강한 종족)를 때리면 −GameConfig.AFFINITY_DISADVANTAGE. 종족이 없는 쪽(주인공)은 늘 중립. 순수 계산이라 테스트로 확인한다.

enum Relation { NEUTRAL, ADVANTAGE, DISADVANTAGE }


## 그 종족이 강한 종족(없으면 "").
static func beats(tribe_id: String) -> String:
	var tribe := TribeDb.get_tribe(tribe_id)
	return tribe.beats if tribe != null else ""


## 그 종족에게 강한 종족 = 그 종족의 약점(없으면 "").
static func beaten_by(tribe_id: String) -> String:
	if tribe_id == "":
		return ""
	for id in TribeDb.ids():
		if beats(id) == tribe_id:
			return id
	return ""


## 때리는 쪽 종족이 맞는 쪽 종족에게 유리한가 · 불리한가.
static func relation(attacker: String, defender: String) -> Relation:
	if attacker == "" or defender == "" or attacker == defender:
		return Relation.NEUTRAL
	if beats(attacker) == defender:
		return Relation.ADVANTAGE
	if beats(defender) == attacker:
		return Relation.DISADVANTAGE
	return Relation.NEUTRAL


## 주는 피해 배율(유리 1.25 · 불리 0.8 · 중립 1, 값은 GameConfig).
static func damage_scale(attacker: String, defender: String) -> float:
	match relation(attacker, defender):
		Relation.ADVANTAGE:
			return 1.0 + GameConfig.AFFINITY_ADVANTAGE
		Relation.DISADVANTAGE:
			return 1.0 - GameConfig.AFFINITY_DISADVANTAGE
	return 1.0


## 상성 원의 차례: start에서 시작해 "강한 상대"를 따라 한 바퀴(상성표 그림이 이 차례로 시계 방향).
static func cycle(start: String) -> PackedStringArray:
	var order := PackedStringArray()
	var at := start
	while at != "" and not order.has(at):
		order.append(at)
		at = beats(at)
	return order

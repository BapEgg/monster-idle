class_name UnitStats
extends RefCounted
## 유닛 능력치 한 벌. 값은 GameConfig의 표(PLAYER_STATS, ROLE_STATS)에서 만든다.

var max_hp := 1.0
var attack := 0.0
## 공격(또는 회복) 한 번 뒤 다음까지 기다리는 시간(초).
var attack_interval := 1.0
## 사거리(땅 위 px). GameConfig.MELEE_RANGE_MAX보다 길면 투사체를 쏜다.
var attack_range := 0.0
var heal := 0.0
## 이동 속력(px/초, 화면 가로 기준).
var speed := 0.0


static func from_table(row: Dictionary, move_speed: float, hp_scale := 1.0, attack_scale := 1.0) -> UnitStats:
	var s := UnitStats.new()
	s.max_hp = float(row["hp"]) * hp_scale
	s.attack = float(row["attack"]) * attack_scale
	s.attack_interval = float(row["attack_interval"])
	s.attack_range = float(row["attack_range"])
	s.heal = float(row.get("heal", 0.0)) * attack_scale
	s.speed = move_speed
	return s


static func for_player() -> UnitStats:
	return from_table(GameConfig.PLAYER_STATS, GameConfig.PLAYER_SPEED)


## 역할(tank·melee·ranged·healer)별 능력치. 야생이면 체력·공격을 깎는다.
static func for_hench(role: String, wild: bool) -> UnitStats:
	var row: Dictionary = GameConfig.ROLE_STATS[role]
	if wild:
		return from_table(row, GameConfig.HENCH_SPEED, GameConfig.WILD_HP_SCALE, GameConfig.WILD_ATTACK_SCALE)
	return from_table(row, GameConfig.HENCH_SPEED)

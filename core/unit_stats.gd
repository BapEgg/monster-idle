class_name UnitStats
extends RefCounted
## 유닛 능력치 한 벌. 값은 GameConfig의 표(PLAYER_STATS, ROLE_STATS)나 코어 능력치(from_core)에서 만든다.
## 표에서 만들 때는 레벨만큼 체력 · 공격 · 회복이 오른다(Growth.stat_scale, 주인공 · 야생 · 코어 없는 헨치).

var max_hp := 1.0
var attack := 0.0
## 공격(또는 회복) 한 번 뒤 다음까지 기다리는 시간(초).
var attack_interval := 1.0
## 사거리(땅 위 px). GameConfig.MELEE_RANGE_MAX보다 길면 투사체를 쏜다.
var attack_range := 0.0
var heal := 0.0
## 회복 한 번 뒤 다음까지 기다리는 시간(초). 기본 공격과 따로 센다(힐러는 회복하면서도 공격한다).
var heal_interval := 1.0
## 이동 속력(px/초, 화면 가로 기준).
var speed := 0.0


static func from_table(row: Dictionary, move_speed: float, hp_scale := 1.0, attack_scale := 1.0) -> UnitStats:
	var s := UnitStats.new()
	s.max_hp = float(row["hp"]) * hp_scale
	s.attack = float(row["attack"]) * attack_scale
	s.attack_interval = float(row["attack_interval"])
	s.attack_range = float(row["attack_range"])
	s.heal = float(row.get("heal", 0.0)) * attack_scale
	s.heal_interval = float(row.get("heal_interval", row["attack_interval"]))
	s.speed = move_speed
	return s


static func for_player(level := 1) -> UnitStats:
	var scale := Growth.stat_scale(level)
	return from_table(GameConfig.PLAYER_STATS, GameConfig.PLAYER_SPEED, scale, scale)


## 섬의 왕(보스전, 연습용 임시 능력치).
static func for_boss() -> UnitStats:
	return from_table(GameConfig.BOSS_STATS, GameConfig.BOSS_SPEED)


## 역할(tank·melee·ranged·healer)별 능력치 × 레벨 배율. 야생이면 체력·공격에 야생 배율(GameConfig.WILD_*_SCALE)을 곱한다.
static func for_hench(role: String, wild: bool, level := 1) -> UnitStats:
	var row: Dictionary = GameConfig.ROLE_STATS.get(role, GameConfig.ROLE_STATS["tank"])  # 섬의 왕(boss)은 아직 필드 능력치가 없다
	var scale := Growth.stat_scale(level)
	if wild:
		return from_table(row, GameConfig.HENCH_SPEED, GameConfig.WILD_HP_SCALE * scale, GameConfig.WILD_ATTACK_SCALE * scale)
	return from_table(row, GameConfig.HENCH_SPEED, scale, scale)


## 파티에 넣은 코어의 능력치(CoreStats)로 싸우는 헨치(임시 환산, GameConfig.CORE_COMBAT_*).
## 사거리·회복 간격은 역할 표를 따르고, 회복은 역할 표에 회복이 있는 역할(힐러)만 한다.
static func from_core(item: CoreItem) -> UnitStats:
	var core := CoreStats.compute(item)
	var s := for_hench(item.species().role, false)
	s.max_hp = maxf(float(core["hp"]), 1.0)
	s.attack = float(core["mighty"]) * GameConfig.CORE_COMBAT_ATTACK_PER_MIGHTY
	s.attack_interval *= GameConfig.CORE_COMBAT_SWIFT_HALF / (GameConfig.CORE_COMBAT_SWIFT_HALF + float(core["swift"]))
	if s.heal > 0.0:
		s.heal = float(core["abundant"]) * GameConfig.CORE_COMBAT_HEAL_PER_ABUNDANT
	return s

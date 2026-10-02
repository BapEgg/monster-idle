class_name Detection
extends RefCounted
## 선공 몬스터의 감지 계산(순수 함수). 사용자 결정(2026-10-02): 거리 + 감지 시간, 몹이 바라보는 방향 기준의 시야.
## 사람 눈처럼 정면은 빨리 알아채고, 주변시는 늦게, 등 뒤는 아예 못 본다.
## 방향·거리는 모두 땅 위에서 잰다(화면은 세로가 눌려 있어서 화면 각도와 실제 각도가 다르다).

enum Zone { FRONT, SIDE, BEHIND }


## 상대가 내 시야의 어디에 있나. facing = 내가 바라보는 화면 방향, offset = 나에게서 상대까지(화면 px).
static func zone(facing: Vector2, offset: Vector2) -> Zone:
	var angle := rad_to_deg(absf(Iso.to_ground(facing).angle_to(Iso.to_ground(offset))))
	if angle <= GameConfig.DETECT_FRONT_HALF_ANGLE:
		return Zone.FRONT
	if angle <= GameConfig.DETECT_SIDE_HALF_ANGLE:
		return Zone.SIDE
	return Zone.BEHIND


## 1초에 감지 게이지(0~1)가 차는 양. 감지 거리 밖이거나 등 뒤면 0.
static func fill_rate(facing: Vector2, offset: Vector2) -> float:
	if Iso.to_ground(offset).length() > GameConfig.DETECT_RANGE:
		return 0.0
	match zone(facing, offset):
		Zone.FRONT:
			return 1.0 / GameConfig.DETECT_FRONT_SECONDS
		Zone.SIDE:
			return 1.0 / GameConfig.DETECT_SIDE_SECONDS
	return 0.0


## 다음 프레임의 감지 게이지(0~1). 보이면 rate만큼 차고, 안 보이면(rate = 0) 천천히 빠진다.
static func next_gauge(gauge: float, rate: float, delta: float) -> float:
	if rate > 0.0:
		return minf(gauge + rate * delta, 1.0)
	return maxf(gauge - delta / GameConfig.DETECT_FORGET_SECONDS, 0.0)

class_name GameSave
extends RefCounted
## 저장할 내용 만들기(capture)와 되살리기(restore). 순수 함수라 테스트로 확인한다.
## 저장하는 것: 가방의 코어(파티 자리 · 잠금 · 유산 포함), 골드 · 코어 조각, 사냥 방식, 저장한 때.
## 저장하지 않는 것(임시): 처치 수와 사냥 기록(이번 접속만 잰다), 주인공 위치(켜면 시작 지점), 날아오는 중인 코어.
## 어디에 저장하느냐는 SaveStore가 맡는다(지금은 기기 파일, 나중에 Firebase).

## 저장 내용의 판. 모양이 바뀌면 올리고, restore에서 옛 판을 고쳐 읽는다.
const VERSION := 1


## 지금 상태 → 저장할 내용. now = 저장한 때(유닉스 초, 나중에 오프라인 보상 계산에 쓴다).
static func capture(bag: Bag, wallet: Wallet, mode: AutoControl.Mode, now: int) -> Dictionary:
	var cores := []
	for item in bag.cores:
		cores.append(item.to_dict())
	return {
		"version": VERSION,
		"saved_at": now,
		"gold": wallet.gold,
		"shards": wallet.shards,
		"control_mode": mode,
		"cores": cores,
	}


## 저장 내용 → 가방·지갑. 도감에 없는 종(데이터가 바뀐 경우)의 코어는 버리고 그 수를 돌려준다.
## 파티 자리는 0 ~ party_size-1만 받고, 같은 자리가 겹치면 먼저 나온 코어만 남긴다.
static func restore(data: Dictionary, bag: Bag, wallet: Wallet, party_size: int) -> int:
	var dropped := 0
	var taken := {}
	for row: Variant in data.get("cores", []):
		if not row is Dictionary:
			dropped += 1
			continue
		var item := CoreItem.from_dict(row)
		if HenchDb.get_species(item.species_id) == null:
			dropped += 1
			continue
		if item.party_slot < 0 or item.party_slot >= party_size or taken.has(item.party_slot):
			item.party_slot = -1
		if item.party_slot >= 0:
			taken[item.party_slot] = true
		bag.add(item)
	wallet.gold = maxi(int(data.get("gold", 0)), 0)
	wallet.shards = maxi(int(data.get("shards", 0)), 0)
	wallet.changed.emit()
	return dropped


## 저장된 사냥 방식. 없거나 이상하면 처음 방식(GameConfig.START_CONTROL_MODE).
static func control_mode(data: Dictionary) -> AutoControl.Mode:
	var mode := int(data.get("control_mode", GameConfig.START_CONTROL_MODE))
	if mode < 0 or mode >= AutoControl.Mode.size():
		return GameConfig.START_CONTROL_MODE
	return mode as AutoControl.Mode

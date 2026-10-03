class_name GameSave
extends RefCounted
## 저장할 내용 만들기(capture)와 되살리기(restore). 순수 함수라 테스트로 확인한다.
## 저장하는 것: 가방의 코어(파티 자리 · 잠금 · 유산 · 믹스 계승 · 경험치 포함), 골드 · 종마다 코어 조각 · 경험치 조각, 사냥 방식, 믹스 숙련도, 도감,
## 주인공 레벨 · 경험치, 저장한 때.
## 저장하지 않는 것(임시): 처치 수와 사냥 기록(이번 접속만 잰다), 주인공 위치(켜면 시작 지점), 날아오는 중인 코어.
## 어디에 저장하느냐는 SaveStore가 맡는다(지금은 기기 파일, 나중에 Firebase).

## 저장 내용의 판. 모양이 바뀌면 올리고, restore에서 옛 판을 고쳐 읽는다.
## 2: 믹스 숙련도 · 도감 · 코어의 믹스 계승(inherit_*) 추가, 주 코어 성별(main_parent_gender) 뺌 — 1판은 없는 칸을 기본값으로 읽는다.
## 3: 믹스 숙련도에 믹스한 횟수(mixes) 추가 — 2판은 0으로 읽는다.
## 4: 주인공 레벨 · 경험치(player) 추가 — 3판까지는 1레벨로 읽는다.
## 5: 경험치 조각(exp_shards) · 코어의 경험치(cores[].exp) 추가 — 4판까지는 0으로 읽는다.
## 6: 코어 조각을 종마다(core_shards = {종 id: 개수}) — 5판까지의 종 없는 조각 수(shards)는 어느 종인지 몰라 버린다.
const VERSION := 6


## 지금 상태 → 저장할 내용. now = 저장한 때(유닉스 초, 나중에 오프라인 보상 계산에 쓴다).
static func capture(bag: Bag, wallet: Wallet, mode: AutoControl.Mode, now: int, mastery: MixMastery, codex: Codex, progress: PlayerProgress = null) -> Dictionary:
	var cores := []
	for item in bag.cores:
		cores.append(item.to_dict())
	return {
		"version": VERSION,
		"saved_at": now,
		"gold": wallet.gold,
		"core_shards": wallet.core_shards.duplicate(),
		"exp_shards": wallet.exp_shards,
		"control_mode": mode,
		"mix_mastery": mastery.to_dict(),
		"codex": Array(codex.ids()),
		"player": progress.to_dict() if progress != null else {},
		"cores": cores,
	}


## 저장 내용 → 가방 · 지갑 · 숙련도 · 도감. 도감 데이터에 없는 종(데이터가 바뀐 경우)의 코어는 버리고 그 수를 돌려준다.
## 파티 자리는 0 ~ party_size-1만 받고, 같은 자리가 겹치면 먼저 나온 코어만 남긴다.
## 가방에 있는 코어의 종은 도감에도 등록한다(도감이 없던 옛 저장).
static func restore(data: Dictionary, bag: Bag, wallet: Wallet, party_size: int, mastery: MixMastery, codex: Codex, progress: PlayerProgress = null) -> int:
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
		codex.register(item.species_id)
	for id: Variant in data.get("codex", []):
		if HenchDb.get_species(str(id)) != null:
			codex.register(str(id))
	var row: Variant = data.get("mix_mastery", {})
	mastery.load_dict(row if row is Dictionary else {})
	if progress != null:
		var player: Variant = data.get("player", {})
		progress.load_dict(player if player is Dictionary else {})
	wallet.gold = maxi(int(data.get("gold", 0)), 0)
	wallet.core_shards = {}
	var shards: Variant = data.get("core_shards", {})
	if shards is Dictionary:
		for id: Variant in shards:
			var count := int(shards[id])
			if count > 0 and HenchDb.get_species(str(id)) != null:
				wallet.core_shards[str(id)] = count
	wallet.exp_shards = maxi(int(data.get("exp_shards", 0)), 0)
	wallet.changed.emit()
	return dropped


## 저장된 사냥 방식. 없거나 이상하면 처음 방식(GameConfig.START_CONTROL_MODE).
static func control_mode(data: Dictionary) -> AutoControl.Mode:
	var mode := int(data.get("control_mode", GameConfig.START_CONTROL_MODE))
	if mode < 0 or mode >= AutoControl.Mode.size():
		return GameConfig.START_CONTROL_MODE
	return mode as AutoControl.Mode

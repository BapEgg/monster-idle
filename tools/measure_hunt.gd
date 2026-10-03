extends SceneTree
## 하루 처치 수 측정(밸런스 1차, 기획서 8장 "드랍률 = 하루 목표 ÷ 하루 처치 수"의 처치 수).
## 메인 장면을 풀오토로 게임 시간 N분 돌려 자동 시간당 처치 수를 재고, 하루(24시간 방치) 처치 수와
## 그 값으로 거꾸로 계산한 확률(Balance)을 출력한다. 잰 값은 GameConfig.MEASURED_DAILY_KILLS에 옮겨 적는다.
## 실행(창 없이, 한 프레임 = 1/60초로 고정해 빨리 돈다):
##   <Godot 콘솔> --headless --fixed-fps 60 --path <프로젝트> --script res://tools/measure_hunt.gd -- --minutes=30
## 사용자의 진짜 저장(user://save.json)은 건드리지 않는다(따로 쓰는 파일을 지우고 시작한다).

const MAIN_SCENE := "res://scenes/main/main.tscn"
const MEASURE_SAVE_PATH := "user://measure_save.json"
const DEFAULT_MINUTES := 30.0
## 이만큼 지난 뒤부터 잰다(처음에 야생이 흩어져 있는 동안은 빼고)
const WARMUP_SECONDS := 30.0
## 중간 경과를 찍는 간격(게임 시간 초)
const REPORT_EVERY_SECONDS := 300.0


func _initialize() -> void:
	var store := LocalSaveStore.new(MEASURE_SAVE_PATH)
	store.erase()
	var main: Node = load(MAIN_SCENE).instantiate()
	main.set("save_store", store)
	root.add_child(main)
	_run.call_deferred(main, store)


func _run(main: Node, store: LocalSaveStore) -> void:
	var minutes := DEFAULT_MINUTES
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--minutes="):
			minutes = float(arg.get_slice("=", 1))
	var player: Player = main.get_node("Field/Objects/Player")
	player.control.mode = AutoControl.Mode.FULL_AUTO
	var ticks := Engine.physics_ticks_per_second
	for i in roundi(WARMUP_SECONDS * ticks):
		await physics_frame
	var hunt := HuntLog.new()  # 데우기 뒤부터 따로 센다
	var kills_before: int = main.get("kills")
	var total := roundi(minutes * 60.0 * ticks)
	for i in total:
		await physics_frame
		hunt.add_time(1.0 / ticks, false)
		if (i + 1) % roundi(REPORT_EVERY_SECONDS * ticks) == 0:
			print("  %d분: 처치 %d" % [roundi((i + 1) / float(ticks) / 60.0), int(main.get("kills")) - kills_before])
	var kills: int = int(main.get("kills")) - kills_before
	for k in kills:
		hunt.add_kill(false)
	var per_hour := hunt.kills_per_hour(false)
	var daily := hunt.daily_kills_estimate()
	print("측정: 게임 시간 %.0f분 풀오토 → 처치 %d마리, 시간당 %.1f마리, 하루(24시간) %.0f마리" % [minutes, kills, per_hour, daily])
	var chances := Balance.chances_for(daily)
	print("이 값으로 계산한 확률: 코어 %.3f%% · 빛나는 코어(떨어진 코어 중) %.2f%% · 변이 %.4f%%" % [
		chances["core"] * 100.0, chances["shining"] * 100.0, chances["variant"] * 100.0])
	store.erase()
	quit(0)

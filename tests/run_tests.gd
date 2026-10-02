extends SceneTree
## 순수 함수 테스트 실행기. tests/test_*.gd 를 모두 돌린다.
## 실행: <Godot 콘솔> --headless --path <프로젝트> --script res://tests/run_tests.gd


func _initialize() -> void:
	var checks := 0
	var failures := PackedStringArray()
	for path in _suite_paths():
		var suite = load(path).new()
		for method in suite.get_method_list():
			var method_name: String = method["name"]
			if method_name.begins_with("test_"):
				suite.current_test = "%s · %s" % [path.get_file(), method_name]
				suite.call(method_name)
		checks += suite.checks
		failures.append_array(suite.failures)
	for failure in failures:
		printerr("실패: ", failure)
	print("테스트: 확인 %d개, 실패 %d개" % [checks, failures.size()])
	quit(1 if failures.size() > 0 else 0)


func _suite_paths() -> PackedStringArray:
	var paths := PackedStringArray()
	for file in DirAccess.get_files_at("res://tests"):
		if file.begins_with("test_") and file.ends_with(".gd"):
			paths.append("res://tests/" + file)
	return paths

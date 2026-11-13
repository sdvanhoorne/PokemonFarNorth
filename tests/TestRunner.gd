extends Node
## Runs every test_* method in res://tests/test_*.gd and exits with
## code 0 (all passed) or 1 (any failure).
##
## Run all:      Godot --headless --path . res://tests/TestRunner.tscn
## Run a subset: Godot --headless --path . res://tests/TestRunner.tscn -- --filter=damage

const TESTS_DIR := "res://tests"

func _ready() -> void:
	var filter := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--filter="):
			filter = arg.trim_prefix("--filter=")

	var passed := 0
	var failed := 0

	for file_name in DirAccess.get_files_at(TESTS_DIR):
		if not (file_name.begins_with("test_") and file_name.ends_with(".gd")):
			continue
		if filter != "" and not file_name.contains(filter):
			continue

		var script: GDScript = load("%s/%s" % [TESTS_DIR, file_name])
		for method in script.get_script_method_list():
			var method_name: String = method["name"]
			if not method_name.begins_with("test_"):
				continue

			var test_case: TestCase = script.new()
			test_case.call(method_name)

			if test_case.failures.is_empty():
				passed += 1
				print("PASS  %s :: %s" % [file_name, method_name])
			else:
				failed += 1
				print("FAIL  %s :: %s" % [file_name, method_name])
				for failure in test_case.failures:
					print("        - %s" % failure)

	print("\n%d passed, %d failed" % [passed, failed])
	get_tree().quit(1 if failed > 0 else 0)

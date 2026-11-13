extends TestCase
## Catches calls to autoload methods that don't exist (issue #4: BattleManager.return_to_world).
## Scans every script under res://scripts for `AutoloadName.method(` and checks the method exists.

func test_every_autoload_method_call_exists() -> void:
	var root := (Engine.get_main_loop() as SceneTree).root
	var autoloads: Array[String] = []
	for property in ProjectSettings.get_property_list():
		var setting: String = property["name"]
		if setting.begins_with("autoload/"):
			autoloads.append(setting.trim_prefix("autoload/"))
	check(not autoloads.is_empty(), "found autoloads in project.godot")

	var call_pattern := RegEx.create_from_string(
		"\\b(" + "|".join(autoloads) + ")\\.([A-Za-z_]\\w*)\\s*\\(")

	for path in _script_paths("res://scripts"):
		var source := FileAccess.get_file_as_string(path)
		for line_index in source.split("\n").size():
			var line: String = source.split("\n")[line_index]
			if line.strip_edges().begins_with("#"):
				continue
			for found in call_pattern.search_all(line):
				var autoload := root.get_node_or_null(found.get_string(1))
				var method := found.get_string(2)
				if autoload != null and not autoload.has_method(method):
					failures.append("%s:%d calls %s.%s(), which doesn't exist" % [
						path, line_index + 1, found.get_string(1), method])

func _script_paths(dir: String) -> Array[String]:
	var paths: Array[String] = []
	for file_name in DirAccess.get_files_at(dir):
		if file_name.ends_with(".gd"):
			paths.append(dir.path_join(file_name))
	for sub_dir in DirAccess.get_directories_at(dir):
		paths.append_array(_script_paths(dir.path_join(sub_dir)))
	return paths

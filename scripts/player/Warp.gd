extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body.name != "Player":
		return

	if has_meta("target_scene"):
		if has_meta("target_scene"):
			var scene_path = get_meta("target_scene")
			var packed_scene = load(scene_path)
			if packed_scene is PackedScene:
				var spawn_point = get_meta("spawn_point")
				var world = get_tree().root.get_node("World")
				world.load_map(packed_scene, spawn_point)
			else:
				push_error("Failed to load scene at: %s" % scene_path)

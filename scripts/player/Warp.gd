extends Area2D

@onready var CollisionShape: CollisionShape2D = $CollisionShape2D
var horizontal: bool = true
var length: int

func _ready(): 
	var width = CollisionShape.shape.get_rect().size.x
	var height = CollisionShape.shape.get_rect().size.y
	if(width < height):
		horizontal = false
		length = height / GlobalConstants.TileSize
	else:
		horizontal = true
		length = width / GlobalConstants.TileSize

func _on_body_entered(body: Node2D) -> void:
	if body.name != "Player":
		return
		
	if has_meta("target_scene"):
		if has_meta("target_scene"):
			var scene_path = get_meta("target_scene")
			var packed_scene = load(scene_path)
			if packed_scene is PackedScene:
				var local_offset : Vector2 = (body.global_position - global_position) / GlobalConstants.TileSize
				var spawn_point = get_meta("spawn_point")
				var world = get_tree().root.get_node("World")
				
				var index : int
				if(horizontal):
					index = clamp(int(floor(local_offset.x)), 0, length - 1)
				else:
					index = clamp(int(floor(local_offset.y)), 0, length - 1)
				world.load_map(packed_scene, body, spawn_point, horizontal, index)
			else:
				push_error("Failed to load scene at: %s" % scene_path)

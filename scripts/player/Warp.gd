extends Area2D

@export var target_map_id: String
@export var spawn_point: String = ""
@onready var CollisionShape: CollisionShape2D = $CollisionShape2D
var horizontal: bool = true
var length: int

func _ready(): 
	var width = CollisionShape.shape.get_rect().size.x
	var height = CollisionShape.shape.get_rect().size.y
	if(width < height):
		horizontal = false
		length = height / 20
	else:
		horizontal = true
		length = width / 20

func _on_body_entered(body: Node2D) -> void:
	if body.name != "Player":
		return

	var packed_scene := MapRegistry.get_map(target_map_id) 

	if packed_scene == null:
		return
	
	var body_position := body.global_position
	var local_offset: Vector2 = (body_position - global_position) / GlobalConstants.TileSize

	var index: int
	if horizontal:
		index = int(local_offset.x)
	else:
		index = int(local_offset.y)

	var world := get_tree().root.get_node("World")
	world.load_map(packed_scene, body, spawn_point, horizontal, index)

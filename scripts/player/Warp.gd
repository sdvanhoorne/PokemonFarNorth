extends Area2D

@export var target_map_id: String
@export var spawn_point: String = ""
@onready var CollisionShape: CollisionShape2D = $CollisionShape2D
var horizontal: bool = true
var length: int

func _ready(): 
	# set length or width of warp area
	var width = CollisionShape.shape.get_rect().size.x
	var height = CollisionShape.shape.get_rect().size.y
	if(width < height):
		horizontal = false
		length = height / 20
	else:
		horizontal = true
		length = width / 20

func _on_body_entered(body: Node2D) -> void:
	# don't care about non players
	if body.name != "Player":
		return

	# make sure target scene is valid
	var packed_scene := MapRegistry.get_map(target_map_id) 
	if packed_scene == null:
		return
	
	var offset = get_warp_offset(body.global_position)
	var world := get_tree().root.get_node("World")
	world.load_map(packed_scene, body, spawn_point, horizontal, offset)
	
func get_warp_offset(player_position: Vector2) -> int:
	var local_offset: Vector2 = (player_position - global_position) / GlobalConstants.TileSize

	var warp_offset: int
	if horizontal:
		warp_offset = int(local_offset.x)
	else:
		warp_offset = int(local_offset.y)
	return warp_offset

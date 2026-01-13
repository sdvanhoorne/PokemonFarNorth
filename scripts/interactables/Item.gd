extends Interactable
class_name OverworldItem

@export var item_id: String = "potion"
@export var amount: int = 1
@export var message: String = "You found a Potion!"
@export var unique_id: String = ""  # e.g. "route1_item_01"

@onready var area: Area2D = $Area2D

var _picked_up := false

func _do_interact(_player: Node) -> void:
	if _picked_up:
		return
	_picked_up = true
	
	await DialogueManager.say(
		PackedStringArray([message]),
		{
			"lock_input": true,
			"require_input": true
		}
	)

	queue_free()

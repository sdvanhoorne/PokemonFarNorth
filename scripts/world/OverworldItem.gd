extends Node2D
class_name OverworldItem

@export var item_id: String = "potion"
@export var amount: int = 1
@export var message: String = "You found a Potion!"
@export var unique_id: String = ""  # e.g. "route1_item_01"

@onready var area: Area2D = $Area2D

var _picked_up := false

func interact(_player: Node = null) -> void:
	if _picked_up:
		return
	_picked_up = true

	# Show pickup message
	await DialogueManager.print_lines([message])
	await DialogueManager.hide_message_box()

	# Add to inventory
	# Inventory.add_item(item_id, amount)

	# Persist removal
	# if unique_id != "":
	#	GameState.set_flag("picked_" + unique_id, true)

	queue_free()

extends Interactable
class_name NpcInteractable

@export var npc: NodePath   # points to the owning NPC

func _do_interact(player: Node) -> void:
	var npc_node := get_node(npc)
	if npc_node:
		await npc_node.on_talk(player)

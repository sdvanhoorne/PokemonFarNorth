extends RayCast2D

class_name InteractRay

func _try_interact() -> void:
	_update_interact_ray()
	force_raycast_update()

	if not is_colliding():
		return

	var hit := get_collider()
	var node := hit as Node
	
	# fix later? better interact function finding?
	# for now just check first if the node has the interactable as a child
	if(node.has_node("Interactable")):
		node = node.get_node("Interactable")

	while node and not node.has_method("interact"):
		node = node.get_parent()

	if node:
		node.interact(self)

func _update_interact_ray() -> void:
	target_position = get_parent().facing * GlobalConstants.tile_size

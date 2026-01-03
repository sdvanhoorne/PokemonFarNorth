extends Interactable
class_name Sign

@export_multiline var text: String = "..."

func _do_interact(_player: Node) -> void:
	await DialogueManager.start_dialogue([text])

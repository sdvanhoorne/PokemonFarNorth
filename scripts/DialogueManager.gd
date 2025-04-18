extends Node
var dialogue_box: Node = null

func _ready():
	dialogue_box = get_node_or_null("/root/World/CanvasLayer/DialogueBox")
	
func print_lines(lines: PackedStringArray):
	var text_box = dialogue_box.get_node("DialogueText")
	text_box.text = ""
	show_dialogue_box()
	for line in lines:
		for character in line:
			text_box.append_text(character)
			await get_tree().process_frame

func show_dialogue_box():
	dialogue_box.visible = true
	
func hide_dialogue_box():
	dialogue_box.visible = false

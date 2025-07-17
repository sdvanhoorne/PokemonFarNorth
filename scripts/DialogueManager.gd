extends Node
var message_box: Node = null
const text_speed = 0.01
	
func set_message_box(box: Node):
	message_box = box
	
func print_lines(messageBox: Node, lines: PackedStringArray):
	var message = messageBox.get_node("Message")
	message.text = ""
	messageBox.visible = true
	for line in lines:
		for character in line:
			message.append_text(character)
			await get_tree().create_timer(text_speed).timeout
		message.append_text(" ")

func show_message_box():
	message_box.visible = true
	
func hide_message_box():
	message_box.visible = false

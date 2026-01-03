extends Node

signal advance_requested

var message_box: Node = null
const text_speed := 0.01

var _active := false
var _typing := false

func _ready() -> void:
	# Ensure this node can receive unhandled input.
	set_process_unhandled_input(true)

func start_dialogue(lines: PackedStringArray) -> void:
	# Public entrypoint (call this instead of print_lines directly)
	if _active:
		return

	_active = true
	GameState.lock_gameplay_input()
	show_message_box()

	# Run the dialogue asynchronously
	await _run_lines(lines)

	hide_message_box()
	GameState.unlock_gameplay_input()
	_active = false

func _run_lines(lines: PackedStringArray) -> void:
	var message: RichTextLabel = message_box.get_node("Message")
	message.text = ""

	for line in lines:
		await _type_line(message, line)
		await _wait_for_interact()  # <- require player input to proceed

func _type_line(message: RichTextLabel, line: String) -> void:
	_typing = true
	message.text = ""

	for character in line:
		message.append_text(character)
		await get_tree().create_timer(text_speed).timeout

	_typing = false

func _wait_for_interact() -> void:
	# Wait until the user presses interact. If you want "press once to skip typing",
	# see the optional improvement below.
	await advance_requested

func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return

	if event.is_action_pressed("interact"):
		# Prevent Player (or anything else) from seeing this interact press.
		get_viewport().set_input_as_handled()

		# If we're typing, you can choose to instantly finish the line instead of advancing.
		# Right now, we just request advance (so player can mash to skip pauses).
		emit_signal("advance_requested")

func show_message_box() -> void:
	message_box.visible = true

func hide_message_box() -> void:
	message_box.visible = false

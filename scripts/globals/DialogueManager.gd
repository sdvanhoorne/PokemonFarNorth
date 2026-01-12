# DialogueManager.gd (Autoload)
extends Node

signal advance_requested

@export var text_speed := 0.01
@export var message_box: CanvasItem # assign your overworld message box by default

var _active := false
var _typing := false
var _skip_typing := false

# Each job: { "lines": PackedStringArray, "opts": Dictionary, "done": Signal/Callable }
var _queue: Array[Dictionary] = []

func _ready() -> void:
	set_process_unhandled_input(true)

# --- Public API -------------------------------------------------------------

# Fire-and-forget enqueue (useful for overworld triggers, etc.)
func push(lines: PackedStringArray, opts: Dictionary = {}) -> void:
	_enqueue_job(lines, opts, null)

# Awaitable enqueue (perfect for battle flow)
func say(lines: PackedStringArray, opts: Dictionary = {}) -> void:
	var done := SignalAwaiter.new()
	add_child(done) # so it can emit and free itself safely
	_enqueue_job(lines, opts, done)
	await done.completed

# Optional convenience for single line
func say_line(line: String, opts: Dictionary = {}) -> void:
	await say(PackedStringArray([line]), opts)

# --- Queue internals --------------------------------------------------------

func _enqueue_job(lines: PackedStringArray, opts: Dictionary, done: SignalAwaiter) -> void:
	_queue.append({
		"lines": lines,
		"opts": opts,
		"done": done
	})

	if not _active:
		_process_queue()

func _process_queue() -> void:
	_active = true

	while _queue.size() > 0:
		var job: Dictionary = _queue.pop_front()
		var lines: PackedStringArray = job["lines"]
		var opts: Dictionary = _merge_defaults(job["opts"])
		var done: SignalAwaiter = job["done"]

		var prev_box := message_box
		if opts.has("box") and opts["box"] != null:
			message_box = opts["box"]

		# Input locking is contextual:
		# - overworld: lock gameplay
		# - battle: you usually pass lock_input=false and lock your menu separately
		if opts.lock_input:
			opts.lock_callable.call()

		show_message_box()

		await _run_lines(lines, opts)

		hide_message_box()

		if opts.lock_input:
			opts.unlock_callable.call()

		message_box = prev_box

		if done != null:
			done.finish()

	_active = false

func _merge_defaults(opts: Dictionary) -> Dictionary:
	# Defaults tuned for overworld usage.
	# Battle calls should typically pass:
	# { "lock_input": false, "box": BattleUI.get_node("BattleMessageBox") }
	var out := {
		"require_input": true,
		"auto_advance_time": 0.0, # used if require_input=false
		"lock_input": true,
		"lock_callable": Callable(GameState, "lock_gameplay_input"),
		"unlock_callable": Callable(GameState, "unlock_gameplay_input"),
		"box": null,
	}
	for k in opts.keys():
		out[k] = opts[k]
	return out

# --- Dialogue playback ------------------------------------------------------

func _run_lines(lines: PackedStringArray, opts: Dictionary) -> void:
	var message: RichTextLabel = message_box.get_node("Message")
	message.text = ""

	for line in lines:
		await _type_line(message, line)

		if opts.require_input:
			await _wait_for_interact()
		else:
			var t := float(opts.auto_advance_time)
			if t > 0.0:
				await get_tree().create_timer(t).timeout

func _type_line(message: RichTextLabel, line: String) -> void:
	_typing = true
	_skip_typing = false
	message.text = ""

	for c in line:
		if _skip_typing:
			message.text = line
			break
		message.append_text(c)
		await get_tree().create_timer(text_speed).timeout

	_typing = false

func _wait_for_interact() -> void:
	await advance_requested

# --- Input handling ---------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return

	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()

		# UX: first press completes typing, second advances.
		if _typing:
			_skip_typing = true
			return

		emit_signal("advance_requested")

# --- UI helpers -------------------------------------------------------------

func show_message_box() -> void:
	if message_box:
		message_box.visible = true

func hide_message_box() -> void:
	if message_box:
		message_box.visible = false

# --- Helper node to provide an awaitable signal ----------------------------

class SignalAwaiter extends Node:
	signal completed

	func finish() -> void:
		emit_signal("completed")
		queue_free()

extends Control

@onready var map_name_label: RichTextLabel = $MapNameLabel

var _map_name_tween: Tween
var _map_name_anim_token := 0

func show_map_name_card(text: String, hold_seconds: float = 3.0) -> void:
	_map_name_anim_token += 1
	var my_token := _map_name_anim_token

	# Kill any previous animation so warps don't stack
	if _map_name_tween and _map_name_tween.is_running():
		_map_name_tween.kill()

	map_name_label.text = text
	print("Showing map name: %s" % text)
	visible = true

	# Positions (in pixels) relative to top-left of the viewport
	# "hidden" = above the screen; "shown" = slightly down from top.
	var shown_pos := Vector2(16, 16)
	var hidden_pos := Vector2(16, size.y - 40)

	# Start hidden (instant)
	position = hidden_pos
	modulate.a = 1.0

	_map_name_tween = create_tween()
	_map_name_tween.set_trans(Tween.TRANS_QUAD)
	_map_name_tween.set_ease(Tween.EASE_OUT)

	# Slide down
	_map_name_tween.tween_property($".", "position", shown_pos, 0.35)

	# Hold (using timer so we can cancel cleanly if another warp happens)
	await get_tree().create_timer(hold_seconds).timeout
	if my_token != _map_name_anim_token:
		return

	# Slide up
	var t2 := create_tween()
	t2.set_trans(Tween.TRANS_QUAD)
	t2.set_ease(Tween.EASE_IN)
	t2.tween_property($".", "position", hidden_pos, 0.35)

	await t2.finished
	if my_token != _map_name_anim_token:
		return

	visible = false

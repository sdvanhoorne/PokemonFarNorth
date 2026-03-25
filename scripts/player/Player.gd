extends CharacterBody2D
class_name Player

@onready var interact_ray: RayCast2D = $InteractRay
@onready var movement_controller: MovementController = $MovementController
@onready var animation_controller: CharacterAnimationController = $CharacterAnimationController

func _ready() -> void:
	movement_controller.snap_to_grid()
	movement_controller.moved_to_tile.connect(_on_moved_to_tile)

func _on_moved_to_tile(new_global_pos: Vector2) -> void:
	check_for_encounter(new_global_pos)

func _physics_process(delta: float) -> void:
	var dir := Vector2.ZERO
	if Input.is_action_pressed("ui_up"):
		dir = Vector2.UP
	elif Input.is_action_pressed("ui_down"):
		dir = Vector2.DOWN
	elif Input.is_action_pressed("ui_left"):
		dir = Vector2.LEFT
	elif Input.is_action_pressed("ui_right"):
		dir = Vector2.RIGHT

	var want_sprint := Input.is_action_pressed("sprint")

	# Keep desired input updated every frame, even during a committed step,
	# so releasing the key stops chaining after the current tile finishes.
	if GameState.gameplay_input_enabled:
		if dir != Vector2.ZERO:
			movement_controller.set_desired_input(dir, want_sprint)
		else:
			movement_controller.clear_input()
	else:
		# Let current tile finish, but do not allow chaining into another tile.
		movement_controller.clear_input()

	movement_controller.tick(delta)

	animation_controller.play_animation(
		movement_controller.get_move_state(),
		movement_controller.get_animation_direction()
	)

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		interact_ray._try_interact()

func check_for_encounter(pos: Vector2) -> void:
	var current_map = get_parent().get_parent()
	if current_map == null:
		return

	var encounter_layer = current_map.get_node_or_null("EncounterLayer")
	if encounter_layer == null:
		return

	EncounterManager.check_for_encounter_at_position(
		pos,
		movement_controller.facing_direction,
		encounter_layer
	)

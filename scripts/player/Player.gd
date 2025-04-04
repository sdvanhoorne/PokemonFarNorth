extends CharacterBody2D
@onready var visuals = $Sprite2D
@onready var _animation_player = $SpriteAnimation

const TILE_SIZE = 16
const MOVE_TIME = 0.1  # Time it takes to move one tile
var facing_input = Vector2.ZERO
var hold_timer = 0.0
const HOLD_THRESHOLD = 0.03
var is_moving = false
var target_position = Vector2.ZERO

func _ready():
	global_position = global_position.snapped(Vector2(TILE_SIZE, TILE_SIZE)) # ✅ Ensure alignment
	target_position = global_position

func _physics_process(delta):
	if is_moving:
		# Continue moving toward target
		var direction = (target_position - global_position).normalized()
		velocity = direction * (TILE_SIZE / MOVE_TIME)
		move_and_slide()

		if global_position.distance_to(target_position) < 1:
			global_position = target_position.snapped(Vector2(TILE_SIZE, TILE_SIZE))
			is_moving = false
			velocity = Vector2.ZERO
			check_for_encounter()
		return

	var input = Vector2.ZERO

	if Input.is_action_pressed("ui_up"):
		input.y -= 1
		_animation_player.play("move_up")
	elif Input.is_action_pressed("ui_down"):
		input.y += 1
		_animation_player.play("move_down")
	elif Input.is_action_pressed("ui_left"):
		input.x -= 1
		_animation_player.play("move_left")
	elif Input.is_action_pressed("ui_right"):
		input.x += 1
		_animation_player.play("move_right")

	if input != Vector2.ZERO:
		input = input.normalized()
		
		# If new direction is different, update facing direction instantly
		if input != facing_input:
			facing_input = input
			hold_timer = 0.0
			visuals.update_direction(facing_input)
		else:
			hold_timer += delta
			if hold_timer >= HOLD_THRESHOLD:
				var offset = input * TILE_SIZE
				if !test_move(global_transform, offset):
					target_position = global_position + offset
					is_moving = true
	else:
		# Reset if no direction held
		facing_input = Vector2.ZERO
		hold_timer = 0.0
		_animation_player.stop()

func check_for_encounter():
	var current_map = get_parent().current_map
	if(current_map == null): # no map
		return
	var encounter_layer = current_map.get_node("EncounterLayer")
	if(encounter_layer == null):
		return
	EncounterManager.check_for_encounter_at_position(global_position, facing_input, encounter_layer)

extends CharacterBody2D
@onready var _animation_player = $SpriteAnimation

const TILE_SIZE = 16
const MOVE_TIME = .17 # Time it takes to move one tile
var facing_input = Vector2.ZERO
var hold_timer = 0.0
const HOLD_THRESHOLD = 0.03
var is_moving = false
var target_position = Vector2.ZERO
var sprinting = false
var sprint_multipier = 2
var facing_direction = "down"

func _ready():
	# align player to grid
	global_position = global_position.snapped(Vector2(TILE_SIZE, TILE_SIZE)) 
	target_position = global_position

func _physics_process(delta):
	if is_moving:
		# Continue moving toward target
		var direction = (target_position - global_position).normalized()
		velocity = Vector2.ZERO
		velocity = direction * (TILE_SIZE / MOVE_TIME)
		if(sprinting):
			velocity = velocity * sprint_multipier
		move_and_slide()
		
		if abs(global_position.distance_to(target_position)) < (velocity.length() / (TILE_SIZE / MOVE_TIME)):
			global_position = target_position.snapped(Vector2(TILE_SIZE, TILE_SIZE))
			is_moving = false
			velocity = Vector2.ZERO
			check_for_encounter()
		return

	var input = Vector2.ZERO

	var move_state = get_move_state()
	if Input.is_action_pressed("ui_up"):
		input.y -= 1
		facing_direction = "up"
	elif Input.is_action_pressed("ui_down"):
		input.y += 1
		facing_direction = "down"
	elif Input.is_action_pressed("ui_left"):
		input.x -= 1
		facing_direction = "left"
	elif Input.is_action_pressed("ui_right"):
		input.x += 1
		facing_direction = "right"
	_animation_player.play(move_state + "_" + facing_direction)
		
	# if there is movement input
	if input != Vector2.ZERO:
		input = input.normalized()
		
		if(Input.is_action_pressed("sprint")):
			sprinting = true
		else:
			sprinting = false
		
		# If new direction is different, update facing direction instantly
		if input != facing_input:
			facing_input = input
			hold_timer = 0.0
		else:
			hold_timer += delta
			if hold_timer >= HOLD_THRESHOLD:
				var offset = input * TILE_SIZE
				if !test_move(global_transform, offset):
					target_position = global_position + offset
					is_moving = true
	
	# no movement input
	else:
		# Reset if no direction held
		facing_input = Vector2.ZERO
		hold_timer = 0.0
		_animation_player.play("idle_" + facing_direction)

func get_move_state() -> String:
	if(facing_input == Vector2.ZERO):
		return "idle"
	elif(sprinting):
		return "sprint" 
	else:
		return "move"

func check_for_encounter():
	var current_map = get_parent().get_parent()
	if(current_map == null): # no map
		return
	var encounter_layer = current_map.get_node("EncounterLayer")
	if(encounter_layer == null):
		return
	EncounterManager.check_for_encounter_at_position(global_position, facing_input, encounter_layer)

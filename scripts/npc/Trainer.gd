extends Npc
class_name Trainer

@onready var sight_ray: SightRay = $SightRay
@onready var alert_animation: AnimatedSprite2D = $AlertAnimation

var is_engaging := false
var has_battled := false
var player_ref: Player
var portrait: Texture2D

var party: Array[Pokemon] = []
var trainer_class: String
var intro_lines: Array[String] = []
var outro_lines_win: Array[String] = []
var outro_lines_lose: Array[String] = []

func _ready() -> void:
	super()
	sight_ray.player_spotted.connect(_on_player_spotted)
	party = TrainerDatabase.get_trainer_pokemon(npc_id)
	intro_lines = Array(dialogue.get("battle_intro", []), TYPE_STRING, "", null)
	outro_lines_win = Array(dialogue.get("after_battle_win", []), TYPE_STRING, "", null)
	outro_lines_lose = Array(dialogue.get("after_battle_lose", []), TYPE_STRING, "", null)
	trainer_class = TrainerDatabase.get_trainer_class(npc_id)
	portrait = Paths.load_sprite(Paths.join(Paths.TRAINER_BATTLE_SPRITES, trainer_class))

func _on_player_spotted(p: Node2D) -> void:
	if has_battled or is_engaging:
		return
	if not p is Player:
		return

	is_engaging = true
	player_ref = p as Player

	# Prevent repeated triggers immediately.
	sight_ray.disarm()

	# Lock new gameplay input right away,
	# but let the player's committed step finish.
	GameState.lock_gameplay_input()

	if player_ref.movement_controller.is_moving:
		var moved_signal := player_ref.movement_controller.moved_to_tile
		if not moved_signal.is_connected(_on_player_finished_step):
			moved_signal.connect(_on_player_finished_step, CONNECT_ONE_SHOT)
	else:
		_on_player_finished_step(player_ref.global_position)

func _on_player_finished_step(_new_global_pos: Vector2) -> void:
	# Make sure the player is fully snapped to the destination tile.
	player_ref.movement_controller.stop()
	player_ref.movement_controller.snap_to_grid()
	player_ref.movement_controller.clear_input()

	await play_alert()

	await _walk_to_player()
	
	await DialogueManager.say(dialogue["before_battle"],{
		"lock_input": true,
		"require_input": true
	})
	
	await BattleManager.start_trainer_battle(
		party,
		player_ref.global_position,
		player_ref.movement_controller.facing,
		BattleTrainerData.from_trainer(self)
		)
	
func _walk_to_player() -> void:
	while global_position.distance_to(player_ref.global_position) > GlobalConstants.tile_size:
		var delta := player_ref.global_position - global_position
		var step_dir := delta.sign()

		if not movement_controller.request_step(step_dir):
			break

		await movement_controller.moved_to_tile

func play_alert() -> void:
	alert_animation.visible = true
	alert_animation.play("alert")

	var end_pos := Vector2(8, -24)
	var start_pos := Vector2(8, -16)

	alert_animation.position = start_pos
	alert_animation.modulate.a = 1.0
	var slow := 1.0 # 1.0 = normal, 4.0 = 4x slower

	var t := create_tween()
	t.set_trans(Tween.TRANS_BACK)
	t.set_ease(Tween.EASE_OUT)
	t.tween_property(alert_animation, "position", end_pos, 0.18 * slow)
	t.tween_property(alert_animation, "position", end_pos + Vector2(0, 2), 0.06 * slow).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(alert_animation, "position", end_pos, 0.06 * slow).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_interval(0.4 * slow)
	t.tween_property(alert_animation, "modulate:a", 0.0, 0.12 * slow)
	t.tween_callback(func(): alert_animation.visible = false)

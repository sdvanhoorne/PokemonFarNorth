extends "res://scripts/npc/Npc.gd"

@export var team = []  
@export var battle_trigger_range = 100 
@export var defeated = false

func _ready():
	pass  # Maybe face player or idle until provoked

func _process(delta):
	if not defeated and is_player_in_range():
		initiate_battle()

func is_player_in_range() -> bool:
	# get player from SortY
	var player = get_parent().get_node("Player") 
	if player and global_position.distance_to(player.global_position) <= battle_trigger_range:
		return true
	return false

func initiate_battle():
	# Lock the player, face the trainer toward them
	# Call your BattleManager to start a battle
	BattleManager.start_trainer_battle(self)
	defeated = true  # Prevent rematching immediately

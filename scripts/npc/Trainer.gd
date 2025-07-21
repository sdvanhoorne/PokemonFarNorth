extends "res://scripts/npc/Npc.gd"

@export var team = []  
@export var battle_trigger_range = 100 
@export var defeated = false

func _ready():
	pass  # Maybe face player or idle until provoked

func _process(delta):
	if not defeated and player_in_range:
		initiate_battle()

func initiate_battle():
	# Lock the player, face the trainer toward them
	# Call your BattleManager to start a battle
	face_toward(player_ref.global_position)
	var orientation = player_ref.global_position - global_position
	BattleManager.start_battle(team, global_position, orientation,                                                                                                                                                                                                                                                                                                                   )
	defeated = true  # Prevent rematching immediately

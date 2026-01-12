extends Node2D
@onready var BattleUI: BattleUI = $BattleUI
var rng = RandomNumberGenerator.new()
var EnemyPokemon = []

func _ready():
	PlayerInventory.get_party()
	BattleUI.load_player_pokemon(PlayerInventory.PartyPokemon[0])
	BattleUI.load_enemy_pokemon(EnemyPokemon[0])
	BattleUI.hide_moves()
	BattleUI.hide_battle_options()
	DialogueManager.message_box = BattleUI.messageBox
	await DialogueManager.start_dialogue([("A wild %s appeared!" % EnemyPokemon[0].base_data.name)])
	await DialogueManager.start_dialogue(["What will you do?"])
	BattleUI.show_battle_options()
	
func end_battle() -> void:
	PlayerInventory.write_party()
	BattleManager.return_to_world()

func _on_fight_pressed() -> void:	
	BattleUI.show_moves()

func _on_move_0_pressed() -> void:
	process_turn(0)

func _on_move_1_pressed() -> void:
	process_turn(1)
	
func _on_move_2_pressed() -> void:
	process_turn(2)

func _on_move_3_pressed() -> void:
	process_turn(3)

func process_turn(move_index: int):
	var player_pokemon = PlayerInventory.PartyPokemon[0]
	var enemy_pokemon = EnemyPokemon[0]
	BattleUI.hide_battle_options()
	var player_move = player_pokemon.moves[move_index]
	var enemy_move = MoveDatabase.get_move_by_name(determine_enemy_move())
	
	# Check speed for priority and process moves
	if(player_pokemon.battle_stats.speed >= enemy_pokemon.battle_stats.speed):
		await process_move(player_move, player_pokemon, enemy_pokemon, true)
		if await check_faint(enemy_pokemon, true): 
			return
		await process_move(enemy_move, enemy_pokemon, player_pokemon, false)
		if await check_faint(player_pokemon, false):
			return
	else:
		await process_move(enemy_move, enemy_pokemon, player_pokemon, false)
		if await check_faint(player_pokemon, false):
			return
		await process_move(player_move, player_pokemon, enemy_pokemon, true)
		if await check_faint(enemy_pokemon, true):
			return
	
	# TODO process poison, burn, any other damage over time
	# TODO and check again if a pokemon has fainted
	
	BattleUI.show_battle_options()
	
func determine_enemy_move() -> String:
	var enemy_moves = EnemyPokemon[0].get("move_names")
	var roll = rng.randi_range(0, enemy_moves.size()-1)
	var enemy_move = enemy_moves[roll]
	return enemy_move
	
func process_move(move: Move, attacking_pokemon: Pokemon, defending_pokemon: Pokemon, isPlayerAttacking: bool):	
	await DialogueManager.start_dialogue([attacking_pokemon.base_data.name + " used " + move.name])
	
	# process each move type differently 
	var moveCategory = move.category
	if(moveCategory == "Physical" or moveCategory == "Special"):
		var damage = DamageCalculation.get_damage(move, attacking_pokemon, defending_pokemon)
		await process_damage(damage, defending_pokemon, isPlayerAttacking)
	elif(moveCategory == "Status"):
		await process_status(move, attacking_pokemon, defending_pokemon)	
	elif(moveCategory == "StatChange"):
		await process_stat_change(move, attacking_pokemon, defending_pokemon)		
		
func process_damage(damage: int, defending_pokemon: Pokemon, isPlayerAttacking: bool):
	# might be a better way than "isPlayerAttacking"
	defending_pokemon.current_hp -= damage
	BattleUI.update_health_bar(damage, defending_pokemon, isPlayerAttacking)
		
func check_faint(pokemon: Pokemon, isPlayer: bool) -> bool:
	if(pokemon.current_hp <= 0):
		await DialogueManager.start_dialogue([pokemon.base_data.name + " fainted"])
		if(isPlayer):
			BattleUI.unload_enemy_pokemon()
			# give xp
			var xp_gain = pokemon.calculate_xp_given()
			PlayerInventory.PartyPokemon[0].add_xp(xp_gain)
			# show xp bar increase, wait 2 sec for now
			await Helpers.wait(2)
			EnemyPokemon.pop_front()
			if(EnemyPokemon.size() > 0):
				# TODO enemy uses next pokemon
				BattleUI.load_enemy_pokemon(EnemyPokemon[0])
			else:
				# TODO enemy out of pokemon
				end_battle()
		elif(!isPlayer):
			# use next pokemon?
			BattleUI.unload_player_pokemon()
			PlayerInventory.PartyPokemon.pop_front()
			if(PlayerInventory.PartyPokemon.size() > 0):
				# want to use your next pokemon?
				BattleUI.load_player_pokemon(PlayerInventory.PartyPokemon[0])
			else:
				end_battle()
		return true
	return false

func process_status(move: Move, attacking_pokemon: Pokemon, defending_pokemon: Pokemon):
	var status_type = move.status
	var target = move.target
	if(target == "Self"):
		attacking_pokemon.status = status_type
	elif (target == "Enemy"):
		defending_pokemon.status = status_type
	
func process_stat_change(move: Move, attacking_pokemon: Pokemon, defending_pokemon: Pokemon) -> void:
	var affected_pokemon = attacking_pokemon if move.target == "Self" else defending_pokemon	
	var current_value = affected_pokemon.battle_stats.get(move.target_stat)
	affected_pokemon.battle_stats.set(move.target_stat, current_value * move.stat_multiplier)

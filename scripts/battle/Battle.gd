extends Node2D
@onready var messageBox = $BattleUI/MessageBox
@onready var PartyUI = $PartyUI/Party
@onready var BattleOptions = $BattleUI/BattleOptions
@onready var EnemyPokemonContainer = $BattleUI/EnemyPokemonUI/EnemyPokemon
@onready var PlayerPokemonContainer = $BattleUI/PlayerPokemonUI/PlayerPokemon
var rng = RandomNumberGenerator.new()
var EnemyPokemon = []

func _ready():
	load_pokemon(PlayerPokemonContainer, PlayerInventory.PartyPokemon[0])
	load_pokemon(EnemyPokemonContainer, EnemyPokemon[0])
	
	messageBox.get_node("PokemonMoves").visible = false
	BattleOptions.visible = false
	await print_dialogue([("A wild %s appeared!" % EnemyPokemon[0].base_data.name)])
	show_prompt()
	
func show_prompt():
	await print_dialogue(["What will you do?"])
	BattleOptions.visible = true

func load_pokemon(node: Node2D, pokemon: Pokemon):
	var sprite = node.get_node("SpriteArea").get_node("Sprite")
	sprite.texture = load("res://assets/pokemon/ai/" + pokemon.base_data.name + ".png")	
	var nameLabel = node.get_node("Info/Name")
	nameLabel.text = pokemon.base_data.name
	var levelLabel = node.get_node("Info/Level")
	levelLabel.text = str(pokemon.level)
	var healthBar = node.get_node("Info/HealthBar")
	healthBar.max_value = pokemon.battle_stats.hp
	healthBar.value = pokemon.battle_stats.hp
	
	foreach(var move_id in pokemon.move_ids):
		pokemon.moves.append(Move.new(move_id))
	node.set_meta("pokemon", pokemon)
	
func unload_pokemon(node: Node2D):
	var infoArea = node.get_node("SpriteArea")
	var sprite = infoArea.get_node("Sprite")
	sprite.texture = null
	# show fainting animation?
	var info = node.get_node("Info")
	info.visible = false
	
func _on_run_pressed() -> void:
	BattleOptions.visible = false
	await print_dialogue(["You ran away..."])
	end_battle()
	
func end_battle() -> void:
	BattleManager.return_to_world()

func _on_fight_pressed() -> void:	
	show_moves()
	
func show_moves():
	messageBox.get_node("Message").visible = false
	messageBox.get_node("PokemonMoves").visible = true
	set_move(0)
	set_move(1)
	set_move(2)
	set_move(3)
	
func set_move(i: int):
	var moves = PlayerInventory.PartyPokemon[0].moves
	if i >= moves.size():
		return
	var move_button = messageBox.get_node("PokemonMoves").get_node("Move" + str(i))	
	var pokemon_move = moves[i]
	if(pokemon_move == null):
		move_button.text = ""
	move_button.text = pokemon_move

func show_dialogue():
	messageBox.get_node("PokemonMoves").visible = false
	messageBox.get_node("Message").visible = true

func _on_move_0_pressed() -> void:
	var moveName = messageBox.get_node("PokemonMoves").get_node("Move0").text
	process_turn(moveName)

func _on_move_1_pressed() -> void:
	var moveName = messageBox.get_node("PokemonMoves").get_node("Move1").text
	process_turn(moveName)
	
func _on_move_2_pressed() -> void:
	var moveName = messageBox.get_node("PokemonMoves").get_node("Move2").text
	process_turn(moveName)

func _on_move_3_pressed() -> void:
	var moveName = messageBox.get_node("PokemonMoves").get_node("Move3").text
	process_turn(moveName)

func process_turn(moveName: String):
	BattleOptions.visible = false
	var playerMove = get_move(moveName)
	var enemyMove = get_move(determine_enemy_move())
	
	# Check speed for priority and process moves
	var playerPokemon = PlayerInventory.PartyPokemon[0]
	var enemyPokemon = EnemyPokemon[0]
	if(playerPokemon.BattleStats.Speed >= enemyPokemon.BattleStats.Speed):
		await process_move(playerMove, playerPokemon, enemyPokemon, true)
		if await check_faint(enemyPokemon, true): 
			return
		await process_move(enemyMove, enemyPokemon, playerPokemon, false)
		if await check_faint(playerPokemon, false):
			return
	else:
		await process_move(enemyMove, enemyPokemon, playerPokemon, false)
		if await check_faint(playerPokemon, false):
			return
		await process_move(playerMove, playerPokemon, enemyPokemon, true)
		if await check_faint(enemyPokemon, true):
			return
	
	# TODO process poison, burn, any other damage over time
	# TODO and check again if a pokemon has fainted
	show_prompt()
	
func determine_enemy_move() -> String:
	var enemy_moves = EnemyPokemon[0].get("Moves")
	var roll = rng.randi_range(0, enemy_moves.size()-1)
	var enemy_move = enemy_moves[roll]
	return enemy_move
	
func process_move(move: Move, attackingPokemon: Pokemon, defendingPokemon: Pokemon, isPlayerAttacking: bool):	
	await print_dialogue([attackingPokemon.Name + " used " + move.Name])
	
	# process each move type differently 
	var moveCategory = move.Category
	if(moveCategory == "Physical" or moveCategory == "Special"):
		var damage = DamageCalculation.get_damage(move, attackingPokemon, defendingPokemon)
		process_damage(damage, attackingPokemon, defendingPokemon, isPlayerAttacking)
	elif(moveCategory == "Status"):
		process_status(move, attackingPokemon, defendingPokemon)	
	elif(moveCategory == "StatChange"):
		process_stat_change(move, attackingPokemon, defendingPokemon)		
		
func process_damage(damage: int, attackingPokemon: Pokemon, defendingPokemon: Pokemon, isPlayerAttacking: bool):
	# might be a better way than "isPlayerAttacking"
	defendingPokemon.Current_Hp -= damage
	var damagedPokemonContainer
	if(isPlayerAttacking):
		damagedPokemonContainer = EnemyPokemonContainer
	else:
		damagedPokemonContainer = PlayerPokemonContainer
	var healthBar = damagedPokemonContainer.get_node("Info/HealthBar")
	healthBar.value = defendingPokemon.Current_Hp
		
func check_faint(pokemon: Pokemon, isPlayer: bool) -> bool:
	if(pokemon.Current_Hp <= 0):
		await print_dialogue([pokemon.Name + " fainted"])
			
		# end battle for now, 
		# TODO need to check if player or enemy has more pokemon
		end_battle()
		return true
	return false

func process_status(move: Move, attackingPokemon: Pokemon, defendingPokemon: Pokemon):
	var statusType = move.Status
	var target = move.Target
	if(target == "Self"):
		attackingPokemon.Status = statusType
	elif (target == "Enemy"):
		defendingPokemon.Status = statusType
	
func process_stat_change(move: Move, attacking_pokemon: Pokemon, defending_pokemon: Pokemon) -> void:
	var affected_pokemon = attacking_pokemon if move.Target == "Self" else defending_pokemon	
	var current_value = affected_pokemon.BattleStats.get(move.Target_Stat)
	affected_pokemon.BattleStats.set(move.Target_Stat, current_value * move.Stat_Multiplier)
		
func print_dialogue(message: PackedStringArray):
	show_dialogue()
	DialogueManager.print_lines(messageBox, message)
	await get_tree().process_frame
	await Helpers.wait(2)

func _on_switch_pressed() -> void:
	show_party()
	
func show_party():
	PartyUI.visible = true
	
func hide_party():
	PartyUI.visible = false

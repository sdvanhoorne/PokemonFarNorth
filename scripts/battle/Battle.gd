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
	
	for move_id in pokemon.move_ids:
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
	# might want to set an active pokemon 
	var moves = PlayerInventory.PartyPokemon[0].moves
	if i >= moves.size():
		return
	var move_button = messageBox.get_node("PokemonMoves").get_node("Move" + str(i))	
	var pokemon_move = moves[i]["name"]
	if(pokemon_move == null):
		move_button.text = ""
	move_button.text = pokemon_move

func show_dialogue():
	messageBox.get_node("PokemonMoves").visible = false
	messageBox.get_node("Message").visible = true

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
	
	BattleOptions.visible = false
	var player_move = player_pokemon.moves[move_index]
	var enemy_move = Move.new(determine_enemy_move())
	
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
	show_prompt()
	
func determine_enemy_move() -> int:
	var enemy_moves = EnemyPokemon[0].get("move_ids")
	var roll = rng.randi_range(0, enemy_moves.size()-1)
	var enemy_move = enemy_moves[roll]
	return enemy_move
	
func process_move(move: Move, attacking_pokemon: Pokemon, defending_pokemon: Pokemon, isPlayerAttacking: bool):	
	await print_dialogue([attacking_pokemon.base_data.name + " used " + move.name])
	
	# process each move type differently 
	var moveCategory = move.category
	if(moveCategory == "Physical" or moveCategory == "Special"):
		var damage = DamageCalculation.get_damage(move, attacking_pokemon, defending_pokemon)
		process_damage(damage, defending_pokemon, isPlayerAttacking)
	elif(moveCategory == "Status"):
		process_status(move, attacking_pokemon, defending_pokemon)	
	elif(moveCategory == "StatChange"):
		process_stat_change(move, attacking_pokemon, defending_pokemon)		
		
func process_damage(damage: int, defending_pokemon: Pokemon, isPlayerAttacking: bool):
	# might be a better way than "isPlayerAttacking"
	defending_pokemon.current_hp -= damage
	var damagedPokemonContainer
	if(isPlayerAttacking):
		damagedPokemonContainer = EnemyPokemonContainer
	else:
		damagedPokemonContainer = PlayerPokemonContainer
	var healthBar = damagedPokemonContainer.get_node("Info/HealthBar")
	healthBar.value = defending_pokemon.current_hp
		
func check_faint(pokemon: Pokemon, isPlayer: bool) -> bool:
	if(pokemon.current_hp <= 0):
		await print_dialogue([pokemon.base_data.name + " fainted"])
			
		# end battle for now, 
		# TODO need to check if player or enemy has more pokemon
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
	var current_value = affected_pokemon.BattleStats.get(move.target_stat)
	affected_pokemon.BattleStats.set(move.target_stat, current_value * move.stat_multiplier)
		
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

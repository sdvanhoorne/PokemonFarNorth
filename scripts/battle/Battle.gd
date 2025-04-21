extends Node2D
@onready var messageBox = $BattleUI/MessageBox
@onready var PartyUI = $PartyUI/Party
@onready var EnemyPokemonContainer = $BattleUI/EnemyPokemonUI/EnemyPokemon
@onready var PlayerPokemonContainer = $BattleUI/PlayerPokemonUI/PlayerPokemon
var rng = RandomNumberGenerator.new()
var EnemyPokemon = []

func _ready():
	EnemyPokemon.append(BattleManager.wild_pokemon)
	load_pokemon(PlayerPokemonContainer, PlayerInventory.PartyPokemon[0])
	load_pokemon(EnemyPokemonContainer, EnemyPokemon[0])
	
	messageBox.get_node("PokemonMoves").visible = false
	messageBox.get_node("Message").text = ("A wild %s appeared!" % EnemyPokemon[0].Name)
	Helpers.wait(2)
	show_prompt()
	
func show_prompt():
	messageBox.get_node("Message").text = ("What will you do?")

func load_pokemon(node: Node2D, pokemon: Pokemon):
	var sprite = node.get_node("SpriteArea").get_node("Sprite")
	sprite.texture = load("res://assets/pokemon/ai/" + pokemon.Name + ".png")	
	var nameLabel = node.get_node("Info/Name")
	nameLabel.text = pokemon.Name
	var levelLabel = node.get_node("Info/Level")
	levelLabel.text = str(pokemon.Level)
	var healthBar = node.get_node("Info/HealthBar")
	healthBar.max_value = pokemon.BattleStats.Hp
	healthBar.value = pokemon.Current_Hp
	node.set_meta("pokemon", pokemon)
	
func unload_pokemon(node: Node2D):
	var infoArea = node.get_node("SpriteArea")
	var sprite = infoArea.get_node("Sprite")
	sprite.texture = null
	# show fainting animation?
	var info = node.get_node("Info")
	info.visible = false
	
func _on_run_pressed() -> void:
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
	var moves = PlayerInventory.PartyPokemon[0].Moves
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
	if moveName == "" or null:
		return
	show_dialogue()
	var playerMove = get_move(moveName)
	var enemyMove = get_move(get_enemy_move())
	
	# Check speed for priority and process moves
	var playerLead = PlayerInventory.PartyPokemon[0]
	if(playerLead.BattleStats.Speed >= EnemyPokemon[0].BattleStats.Speed):
		process_move(playerMove, playerLead, EnemyPokemon[0], true)
		Helpers.wait(1)
		process_move(enemyMove, EnemyPokemon[0], playerLead, false)
	else:
		process_move(enemyMove, EnemyPokemon[0], playerLead, false)
		Helpers.wait(1)
		process_move(playerMove, playerLead, EnemyPokemon[0], true)
	Helpers.wait(1)
	
	show_prompt()
	
func get_move(moveName: String) -> Move:
	var moveData = FileAccess.open("res://data/moves.json", FileAccess.READ)
	var move = Move.new(moveName, JSON.parse_string(moveData.get_as_text())[moveName])
	return move
	
func get_enemy_move() -> String:
	var enemy_moves = EnemyPokemon[0].get("Moves")
	var roll = rng.randi_range(0, enemy_moves.size()-1)
	var enemy_move = enemy_moves[roll]
	return enemy_move
	
func process_move(move: Move, attackingPokemon: Pokemon, defendingPokemon: Pokemon, isPlayerAttacking: bool):	
	var name = move.Name
	print_dialogue(attackingPokemon.Name + " used " + move.Name)
	
	# process each move type differently 
	var moveCategory = move.Category
	if(moveCategory == "Physical" or moveCategory == "Special"):
		var damage = DamageCalculation.get_damage(move, attackingPokemon, defendingPokemon)
		process_damage(damage, attackingPokemon, defendingPokemon, isPlayerAttacking)
	elif(moveCategory == "Status"):
		process_status(move, attackingPokemon, defendingPokemon)	
	elif(moveCategory == "StatChange"):
		process_stat_change(move, attackingPokemon, defendingPokemon)		
	Helpers.wait(1)
		
func process_damage(damage: int, attackingPokemon: Pokemon, defendingPokemon: Pokemon, isPlayerAttacking: bool):
	defendingPokemon.Current_Hp -= damage
	var damagedPokemonContainer
	if(isPlayerAttacking):
		damagedPokemonContainer = EnemyPokemonContainer
	else:
		damagedPokemonContainer = PlayerPokemonContainer
	var healthBar = damagedPokemonContainer.get_node("Info/HealthBar")
	healthBar.value = defendingPokemon.Current_Hp

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
		
func print_dialogue(message: String):
	show_dialogue()
	messageBox.get_node("Message").text = message
	await get_tree().process_frame

func _on_switch_pressed() -> void:
	show_party()
	
func show_party():
	PartyUI.visible = true
	
func hide_party():
	PartyUI.visible = false

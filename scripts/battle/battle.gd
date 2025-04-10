extends Node2D
@onready var messageBox = $MessageBox
@onready var PartyUI = $Party
@onready var EnemyPokemonContainer = $EnemyPokemon
@onready var PlayerPokemonContainer = $PlayerPokemon
var rng = RandomNumberGenerator.new()
var EnemyPokemon = []

func _ready():
	EnemyPokemon.append(BattleManager.wild_pokemon)
	load_pokemon(PlayerPokemonContainer, PlayerInventory.PartyPokemon[0])
	load_pokemon(EnemyPokemonContainer, EnemyPokemon[0])
	
	messageBox.get_node("PokemonMoves").visible = false
	messageBox.get_node("Message").text = ("A wild %s appeared!" % EnemyPokemon[0].get("name"))
	Helpers.wait(2)
	show_prompt()
	
func show_prompt():
	messageBox.get_node("Message").text = ("What will you do?")

func load_pokemon(node: Node2D, pokemon: Pokemon):
	var sprite = node.get_node("SpriteArea").get_node("Sprite")
	sprite.texture = load("res://assets/pokemon/ai/" + pokemon.name + ".png")	
	var nameLabel = node.get_node("Info/Name")
	nameLabel.text = pokemon.name
	var levelLabel = node.get_node("Info/Level")
	levelLabel.text = str(pokemon.level)
	var healthBar = node.get_node("Info/HealthBar")
	healthBar.max_value = pokemon.hp
	healthBar.value = pokemon.current_hp
	node.set_meta("pokemon", pokemon)
	
func unload_pokemon(node: Node2D):
	var infoArea = node.get_node("SpriteArea")
	var sprite = infoArea.get_node("Sprite")
	sprite.texture = null
	# show fainting animation?
	var info = node.get_node("Info")
	info.visible = false
	
func _on_run_pressed() -> void:
	print("You ran away...")
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
	if moveName == "" or null:
		return
	show_dialogue()
	# player always wins speed tie
	var playerLead = PlayerInventory.PartyPokemon[0]
	show_dialogue()
	if(playerLead.speed >= EnemyPokemon[0].speed):
		process_move(moveName, playerLead, EnemyPokemon[0], true)
		await get_tree().create_timer(1).timeout
		process_move(moveName, EnemyPokemon[0], playerLead, false)
	else:
		process_move(moveName, EnemyPokemon[0], playerLead, false)
		await get_tree().create_timer(1).timeout
		process_move(moveName, playerLead, EnemyPokemon[0], true)
	await get_tree().create_timer(1).timeout
	show_prompt()
	
func get_enemy_move() -> String:
	var enemy_moves = BattleManager.wild_pokemon.get("moves")
	var roll = rng.randi_range(0, enemy_moves.size()-1)
	var enemy_move = enemy_moves[roll]
	return enemy_move
	
func process_move(moveName: String, attackingPokemon: Pokemon, defendingPokemon: Pokemon, isPlayerAttacking: bool):	
	print(attackingPokemon.name + " used " + moveName)
	print_dialogue(attackingPokemon.name + " used " + moveName)
	var moveData = FileAccess.open("res://data/moves.json", FileAccess.READ)
	var move = Move.new(JSON.parse_string(moveData.get_as_text())[moveName])
	if(move.category == "Physical" or "Special"):
		var damage = DamageCalculation.get_damage(move, attackingPokemon, defendingPokemon)
		process_damage(damage, attackingPokemon, defendingPokemon, isPlayerAttacking)
	await get_tree().create_timer(1).timeout
		
func process_damage(damage: int, attackingPokemon: Pokemon, defendingPokemon: Pokemon, isPlayerAttacking: bool):
	defendingPokemon.current_hp -= damage
	var damagedPokemonContainer
	if(isPlayerAttacking):
		damagedPokemonContainer = EnemyPokemonContainer
	else:
		damagedPokemonContainer = PlayerPokemonContainer
	var healthBar = damagedPokemonContainer.get_node("Info/HealthBar")
	healthBar.value = defendingPokemon.current_hp
	print(defendingPokemon.name + " took " + str(damage) + " damage from " + attackingPokemon.name)
	print(defendingPokemon.name + " now has " + str(healthBar.value) + " health")
	if(defendingPokemon.current_hp <= 0):
		print_dialogue(defendingPokemon.name + " fainted")
		print(defendingPokemon.name + " fainted")
		await get_tree().create_timer(1).timeout
		if(isPlayerAttacking):
			unload_pokemon(EnemyPokemonContainer)
			await get_tree().create_timer(1).timeout
			# faint enemy pokemon
			# dget xp / check for level up
			end_battle()
		else:
			unload_pokemon(PlayerPokemonContainer)
			await get_tree().create_timer(1).timeout
			# faint player pokemon / maybe the pokemon class should
			# be attached to the battle and then saved back to party

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

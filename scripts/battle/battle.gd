extends Node2D
@onready var messageBox = $MessageBox
@onready var PartyUI = $Party
@onready var EnemyPokemonContainer = $EnemyPokemonContainer
@onready var PlayerPokemonContainer = $PlayerPokemonContainer
const Move = preload("res://scripts/moves/Move.gd")
var rng = RandomNumberGenerator.new()
var EnemyPokemons = []

func _ready():
	EnemyPokemons.append(BattleManager.wild_pokemon)
	load_player_pokemon(PlayerInventory.PartyPokemon[0].name)
	load_enemy_pokemon()
	
	messageBox.get_node("PokemonMoves").visible = false
	messageBox.get_node("Message").text = ("A wild %s appeared!" % EnemyPokemons[0].get("name"))
	Helpers.wait(2)
	show_prompt()
	
func show_prompt():
	messageBox.get_node("Message").text = ("What will you do?")

func load_player_pokemon(name: String):
	PlayerPokemonContainer.get_node("PlayerPokemonSprite").texture = load("res://assets/pokemon/ai/" + name + ".png")	
	PlayerPokemonContainer.get_node("PlayerPokemonInfo/Name").text = name
	
func load_enemy_pokemon():	
	var name = EnemyPokemons[0].get("name")
	print("A wild %s appeared!" % name)
	EnemyPokemonContainer.get_node("EnemyPokemonSprite").texture = load("res://assets/pokemon/ai/" + name + ".png")
	EnemyPokemonContainer.get_node("EnemyPokemonInfo/Name").text = name
	
func _on_run_pressed() -> void:
	print("You ran away...")
	BattleManager.return_to_world()

# func update_health(healthBar: TextureProgressBar, healthCurrent: int, healthMax: int):
	# healthBar.value = healthCurrent / healthMax

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
	if(playerLead.speed >= EnemyPokemons[0].speed):
		process_move(moveName, playerLead, EnemyPokemons[0])
		process_move(moveName, EnemyPokemons[0], playerLead)
	else:
		process_move(moveName, EnemyPokemons[0], playerLead)
		process_move(moveName, playerLead, EnemyPokemons[0])
	show_prompt()
	
func get_enemy_move() -> String:
	var enemy_moves = BattleManager.wild_pokemon.get("moves")
	var roll = rng.randi_range(0, enemy_moves.size()-1)
	var enemy_move = enemy_moves[roll]
	return enemy_move
	
func process_move(moveName: String, attackingPokemon: Pokemon, defendingPokemon: Pokemon):
	print(attackingPokemon.name + " used " + moveName)
	print_move(attackingPokemon.name, moveName)
	await get_tree().create_timer(1).timeout
	var moveData = FileAccess.open("res://data/moves.json", FileAccess.READ)
	var move = Move.new(JSON.parse_string(moveData.get_as_text())[moveName])
	if(move.category == "Physical" or "Special"):
		var damage = DamageCalculation.get_damage(move, attackingPokemon, defendingPokemon)
	
func process_damage(damage: int, attackingPokemon: Pokemon, defendingPokemon: Pokemon):
	defendingPokemon.current_hp -= damage
	print(defendingPokemon.name + " took " + damage + " damage from " + attackingPokemon.name)
	if(defendingPokemon.current_hp <= 0):
		print(defendingPokemon.name + " fainted")
		# un load 

func print_move(pokemonName: String, move: String):
	messageBox.get_node("Message").text = pokemonName + " used " + move	

func _on_switch_pressed() -> void:
	show_party()
	
func show_party():
	PartyUI.visible = true
	
func hide_party():
	PartyUI.visible = false

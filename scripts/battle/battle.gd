extends Node2D
@onready var messageBox = $MessageBox
@onready var Party = $Party
@onready var EnemyPokemonContainer = $EnemyPokemonContainer
@onready var PlayerPokemonContainer = $PlayerPokemonContainer
var rng = RandomNumberGenerator.new()
var PlayerPokemons = []
var EnemyPokemons = []

func _ready():
	PlayerPokemons = PlayerInventory.get_party()
	EnemyPokemons.append(BattleManager.wild_pokemon)
	load_player_pokemon(PlayerPokemons[0].get("name"))
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
	var move_button = messageBox.get_node("PokemonMoves").get_node("Move" + str(i))
	var pokemon_move = PlayerPokemons[0].get("moves")[i]
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
	if(PlayerPokemons[0].get("speed") >= EnemyPokemons[0].get("speed")):		
		process_player_move(moveName)
		process_enemy_move()
	else:
		process_enemy_move()
		process_player_move(moveName)
	show_prompt()
	
func get_enemy_move() -> String:
	var enemy_moves = BattleManager.wild_pokemon.get("moves")
	var roll = rng.randi_range(0, enemy_moves.size()-1)
	var enemy_move = enemy_moves[roll]
	return enemy_move
	
# process move could be a single function =================
func process_player_move(moveName: String):
	print("Begin player move")
	print_move(PlayerPokemons[0].get("name"), moveName)
	await get_tree().create_timer(1).timeout
	# process player move
	
	
func process_enemy_move():
	print("Begin enemy move")
	print_move(EnemyPokemons[0].get("name"), get_enemy_move())
	await get_tree().create_timer(1).timeout
	# process enemy move
	
# ===========================================================
	
func print_move(pokemonName: String, move: String):
	messageBox.get_node("Message").text = pokemonName + " used " + move
	

func _on_switch_pressed() -> void:
	show_party()
	
func show_party():
	Party.visible = true
	
func hide_party():
	Party.visible = false

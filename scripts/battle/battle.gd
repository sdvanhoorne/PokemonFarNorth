extends Node2D
@onready var messageBox = $MessageBox
@onready var EnemyPokemonContainer = $EnemyPokemonContainer
@onready var PlayerPokemonContainer = $PlayerPokemonContainer

func _ready():
	var wild = BattleManager.wild_pokemon
	load_player_pokemon()
	load_enemy_pokemon(wild)
	
	
	messageBox.get_node("PokemonMoves").visible = false
	messageBox.get_node("Message").text = ("A wild %s appeared!" % wild["name"])
	Helpers.wait(2)
	messageBox.get_node("Message").text = ("What will you do?")
	
func load_player_pokemon():
	var player_pokemon = PlayerInventory.get_lead()
	PlayerPokemonContainer.get_node("PlayerPokemonSprite").texture = load("res://assets/pokemon/ai/" + player_pokemon["name"] + ".png")	
	PlayerPokemonContainer.get_node("PlayerPokemonInfo/Name").text = player_pokemon["name"]
	
func load_enemy_pokemon(wild: Dictionary):	
	print("A wild %s appeared!" % wild["name"])
	EnemyPokemonContainer.get_node("EnemyPokemonSprite").texture = load("res://assets/pokemon/ai/" + wild["name"] + ".png")
	EnemyPokemonContainer.get_node("EnemyPokemonInfo/Name").text = wild["name"]
	
func _on_run_pressed() -> void:
	BattleManager.return_to_world()

func update_health(healthBar: TextureProgressBar, healthCurrent: int, healthMax: int):
	healthBar.value = healthCurrent / healthMax

func _on_fight_pressed() -> void:	
	show_moves()
	
func show_moves():
	messageBox.get_node("Message").visible = false
	messageBox.get_node("PokemonMoves").visible = true
	var pokemonMoves = messageBox.get_node("PokemonMoves")
	var moveOneButton = pokemonMoves.get_node("Move1")
	messageBox.get_node("PokemonMoves").get_node("Move1").text = PlayerInventory.get_lead()["moves"][1] or ""
	messageBox.get_node("PokemonMoves").get_node("Move2").text = PlayerInventory.get_lead()["moves"][2] or ""
	messageBox.get_node("PokemonMoves").get_node("Move3").text = PlayerInventory.get_lead()["moves"][3] or ""
	messageBox.get_node("PokemonMoves").get_node("Move4").text = PlayerInventory.get_lead()["moves"][4] or ""

func show_dialogue():
	messageBox.get_node("PokemonMoves").visible = false
	messageBox.get_node("Message").visible = true

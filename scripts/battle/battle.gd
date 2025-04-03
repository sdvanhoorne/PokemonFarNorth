extends Node2D
@onready var messageBox = $MessageBox/Message
@onready var EnemyPokemonContainer = $EnemyPokemonContainer
@onready var PlayerPokemonContainer = $PlayerPokemonContainer

func _ready():
	var wild = BattleManager.wild_pokemon
	print("A wild %s appeared!" % wild["name"])
	
	var player_pokemon = PlayerInventory.get_lead()
	
	PlayerPokemonContainer.get_node("PlayerPokemonSprite").texture = load("res://assets/pokemon/ai/" + player_pokemon["name"] + ".png")	
	PlayerPokemonContainer.get_node("PlayerPokemonInfo/Name").text = player_pokemon["name"]
	EnemyPokemonContainer.get_node("EnemyPokemonSprite").texture = load("res://assets/pokemon/ai/" + wild["name"] + ".png")
	EnemyPokemonContainer.get_node("EnemyPokemonInfo/Name").text = wild["name"]

	messageBox.clear()
	messageBox.add_text("A wild %s appeared!" % wild["name"])
	
func _on_run_pressed() -> void:
	BattleManager.return_to_world()

func update_health(healthBar: TextureProgressBar, healthCurrent: int, healthMax: int):
	healthBar.value = healthCurrent / healthMax

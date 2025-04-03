extends Node2D
@onready var messageBox = $MessageBox/Message
@onready var EnemyPokemonContainer = $EnemyPokemonContainer

func _ready():
	var wild = BattleManager.wild_pokemon
	print("A wild %s appeared!" % wild["name"])
	
	EnemyPokemonContainer.get_node("EnemyPokemonSprite").texture = load("res://assets/pokemon/ai/" + wild["name"] + ".png")
	
	messageBox.clear()
	messageBox.add_text("A wild %s appeared!" % wild["name"])
	
func _on_run_pressed() -> void:
	BattleManager.return_to_world()

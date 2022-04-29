extends Control



# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var Game # The node representing the game
var Turn_Count_Text # The node holding the turn count text


# Called when the node enters the scene tree for the first time.
func _ready():
	Game = get_parent()
	Turn_Count_Text = get_node("TurnCount")

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_NextTurnButton_pressed() -> void:
	print('Next Turn Button Pressed!')
	Game.turn += 1
	print(Game.turn)
	# get_node("NextMonthButton").set_position(Vector2(260, 20))
	update_turn_display()
	Game.place_building(0, 0)
	Game.on_next_turn()
	
func update_turn_display() -> void:
	Turn_Count_Text.text = "Month " + str(Game.turn)

extends Control
class_name SidebarX

onready var grid : Node2D = $"../../Grid"

var game : Game # The node representing the game
var Turn_Count_Text # The node holding the turn count text

var show_resources : Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	game = get_parent().get_parent()
	Turn_Count_Text = get_node("TurnCount")

	# TODO: tutorial progression
	for resource in GameData.ResourceType.values():
		show_resources[resource] = true

func _on_NextTurnButton_pressed() -> void:
	update_turn_display()
	game.on_next_turn()
	game.place_building(-GameStats.grid_size / 2 * GameData.SQUARE_SIZE, -GameStats.grid_size / 2 * GameData.SQUARE_SIZE)
	if game.turn % 5 == 0:
		grid.set_grid_size(GameStats.grid_size + 6)

"""
	Updates the text displaying the turn count
"""
func update_turn_display() -> void:
	Turn_Count_Text.text = "Month " + str(game.turn)

"""
	Updates the text displaying the resource counts
"""
func update_displays() -> void:
	pass

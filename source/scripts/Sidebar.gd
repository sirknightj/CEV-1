extends Control
class_name SidebarX

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var game : Game # The node representing the game
var Turn_Count_Text # The node holding the turn count text
var Resource_Label_Text  # The text displayed next to each resource count
var Resource_Amount_Text # The text displaying the number of each resource

var show_resources : Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	game = get_parent()
	Turn_Count_Text = get_node("TurnCount")
	Resource_Label_Text = get_node("ResourceLabel")
	Resource_Amount_Text = get_node("ResourceCounts")

	# TODO: tutorial progression
	for resource in GameData.ResourceType.values():
		show_resources[resource] = true

func _on_NextTurnButton_pressed() -> void:
	update_turn_display()
	game.on_next_turn()
	game.place_building(0, 0)

"""
	Updates the text displaying the turn count
"""
func update_turn_display() -> void:
	Turn_Count_Text.text = "Month " + str(game.turn)

"""
	Updates the text displaying the resource counts
"""
func update_displays() -> void:
	var label_text : String = ""
	var count_text = ""

	var resources : GameObjs.Resources = game.resources
	for resource_type in GameData.ResourceType.values():
		if show_resources[resource_type]:
			label_text += str(GameData.ResourceType.keys()[resource_type].capitalize()) + ":\n"
			count_text += str(resources.get_reserve(resource_type)) + " (+" + str(resources.get_income(resource_type)) + ", -" + str(resources.get_expense(resource_type)) + ")\n"

	label_text.strip_edges()
	count_text.strip_edges()
	Resource_Label_Text.text = label_text
	Resource_Amount_Text.text = count_text

extends Control



# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var Game # The node representing the game
var Turn_Count_Text # The node holding the turn count text
var Resource_Label_Text  # The text displayed next to each resource count
var Resource_Amount_Text # The text displaying the number of each resource

var show_water : bool
var show_food : bool
var show_electricity : bool
var show_metal : bool
var show_oxygen : bool
var show_science : bool


# Called when the node enters the scene tree for the first time.
func _ready():
	Game = get_parent()
	Turn_Count_Text = get_node("TurnCount")
	Resource_Label_Text = get_node("ResourceLabel")
	Resource_Amount_Text = get_node("ResourceCounts")
	
	# TODO: progression
	show_water = true
	show_food = true
	show_electricity = true
	show_metal = true
	show_oxygen = true
	show_science = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_NextTurnButton_pressed() -> void:
	print('Next Turn Button Pressed!')
	print(Game.turn)
	# get_node("NextMonthButton").set_position(Vector2(260, 20))
	update_turn_display()
	Game.place_building(0, 0)
	Game.on_next_turn()

"""
	Updates the text displaying the turn count
"""
func update_turn_display() -> void:
	Turn_Count_Text.text = "Month " + str(Game.turn)

"""
	Updates the text displaying the resource counts
"""
func update_displays() -> void:
	var label_text : String = ""
	var count_text = ""
	
	if show_water:
		label_text += "Water:\n"
		count_text += str(Game.water) + " (+" + str(Game.water_income) + ", -" + str(Game.water_expense) + ")\n"
	if show_food:
		label_text += "Food:\n"
		count_text += str(Game.food) + " (+" + str(Game.food_income) + ", -" + str(Game.food_expense) + ")\n"
	if show_oxygen:
		label_text += "Water:\n"
		count_text += str(Game.oxygen) + " (+" + str(Game.oxygen_income) + ", -" + str(Game.oxygen_expense) + ")\n"
	if show_metal:
		label_text += "Metal:\n"
		count_text += str(Game.metal) + " (+" + str(Game.metal_income) + ", -" + str(Game.metal_expense) + ")\n"
	if show_electricity:
		label_text += "Electricity:\n"
		count_text += str(Game.electricity) + " (+" + str(Game.electricity_income) + ", -" + str(Game.electricity_expense) + ")\n"
	if show_water:
		label_text += "Science:\n"
		count_text += str(Game.science) + " (+" + str(Game.science_income) + ", -" + str(Game.science_expense) + ")\n"
	
	label_text += "Population:\n"
	count_text += str(Game.people) + " (+" + str(Game.people_income) + ")\n"
	
	label_text.strip_edges()
	count_text.strip_edges()
	Resource_Label_Text.text = label_text
	Resource_Amount_Text.text = count_text

extends Node2D

var turn       # the current turn
var population # the current population
var _turn_count_text # the text holder object that displays "Turn: 69"

# note: we need income/expense to be seperate so that we can pass that into the graph
var food : int          # the amount of food we have on turn
var food_income : int   # the amount of food we gain on the next turn
var food_expense : int  # the amount of food we will expend on the next turn, nonnegative

var water : int          # the amount of water we have on turn
var water_income : int   # the amount of water we gain on the next turn
var water_expense : int  # the amount of water we will expend on the next turn, nonnegative

var oxygen : int          # the amount of oxygen we have on turn
var oxygen_income : int   # the amount of oxygen we gain on the next turn
var oxygen_expense : int  # the amount of oxygen we will expend on the next turn, nonnegative

var electricity : int          # the amount of electricity we have on turn
var electricity_income : int   # the amount of electricity we gain on the next turn
var electricity_expense : int  # the amount of electricity we will expend on the next turn, nonnegative

var metal : int          # the amount of metal we have on turn
var metal_income : int   # the amount of metal we gain on the next turn
var metal_expense : int  # the amount of metal we will expend on the next turn, nonnegative

var science : int          # the amount of science we have on turn
var science_income : int   # the amount of science we gain on the next turn
var science_expense : int  # the amount of science we will expend on the next turn, nonnegative

var people : int             # The number of people we have in our colony
var people_fraction : float  # The "real" number of people we have = people + people_fraction. 0 <= people_fraction < 1
var people_income : int      # the number of people we gain on the next turn

# Grid Variables
# A mutable grid_size x grid_size grid that buildings can be placed in.
# We can represent a grid square as (m, n), where (0, 0) is the top-left square,
# (0, grid_size - 1) is the top-right square, and (grid_size - 1, grid_size - 1)
# is the bottom-right square.
var width : int   # the width per square
var height : int  # the height per square
var grid_size : int   # the number of squares the width of this grid is
var buildings : Array # the buildings that we own on this grid

var SideBar : Control # the sidebar object

onready var Building = preload("res://scenes/Building.tscn")
var buildings_json = "res://assets/data/buildings.json" # file path of buildings.json
var buildings_dict : Dictionary = {} # building_name -> building

var GRID_SIZE : float = 32

# Called when the node enters the scene tree for the first time.
func _ready():
	turn = 0
	SideBar = get_node("Sidebar")
	load_buildings_json()
	
	# Set initial resources
	food = 100
	oxygen = 100
	water = 55
	metal = 60
	electricity = 50
	science = 0
	people = 25

"""
	Reads the building data from assets/data/buildings.json and loads it into
	the buildings_dict, which maps building_name -> building
"""
func load_buildings_json() -> void:
	var file = File.new()
	assert (file.file_exists(buildings_json))
	file.open(buildings_json, File.READ)
	var data = parse_json(file.get_as_text())
	for building in data:
		assert (not building.name == null)
		buildings_dict[building.name] = building
	print("Loaded the buildings: " + str(buildings_dict.keys()))
	file.close()

"""
	Handles the logic for the next turn
"""
func on_next_turn():
	print("MainGameScene.on_next_turn was called!")
	turn += 1
	
	water += (water_income - water_expense)
	food += (food_income - food_expense)
	oxygen += (oxygen_income - oxygen_expense)
	metal += (metal_income - metal_expense)
	electricity += (electricity_income - electricity_expense)
	science += (science_income - science_expense)
	
	people += people_income
	print("Population: " + str(people + people_fraction))
	calculate_people_next_turn()
	recalculate_incomes()

"""
	Place the building at the grid square (_x, _y).
"""
func place_building(_x: int, _y: int) -> void:
	# TODO: load the buildings dynamically
	
	# Testing out a farm
	# TODO: subtract / check if we can actually purchase
	# TODO: check for collisions
	var key = buildings_dict.keys()[randi() % buildings_dict.size()]
	var building_stats = buildings_dict[key]
	var shape = building_stats.shape
	var building = Building.instance()
	building.shape = shape
	building.size = GRID_SIZE
	add_child(building)
	building.set_position(Vector2(_x, _y))

"""
	Calculates the number of people we will gain on the next turn
"""
func calculate_people_next_turn() -> int:
	var result : float = people + people_fraction
	if turn < 2:
		result *= 0.05
	elif turn < 4:
		result *= 0.08
	elif turn < 5:
		result *= 0.25
	elif turn < 10:
		result *= 0.08
	elif turn < 11:
		result *= 0.15
	elif turn < 15:
		result *= 0.03
	elif turn < 20:
		result *= 0.01
	elif turn < 21:
		result *= 0.07
	elif turn < 35:
		result *= 0.01
	elif turn < 36:
		result *= 0.095
	else:
		result *= 0.025
	
	people_income = floor(result)
	people_fraction = result - people_income
	return people_income

"""
	# Calculate the total income we have
"""
func recalculate_incomes() -> void:
	var new_water_expense : int = 0
	var new_water_income : int = 0
	var new_food_expense : int = 0
	var new_food_income : int = 0
	var new_oxygen_expense : int = 0
	var new_oxygen_income : int = 0
	var new_metal_expense : int = 0
	var new_metal_income : int = 0
	var new_electricity_expense : int = 0
	var new_electricity_income : int = 0
	var new_science_expense : int = 0
	var new_science_income : int = 0

	for building in buildings:
		if building["water_effect"] < 0:
			new_water_expense -= building["water_effect"]
		else:
			new_water_income += building["water_effect"]
		if building["food_effect"] < 0:
			new_food_expense -= building["food_effect"]
		else:
			new_food_income += building["food_effect"]
		if building["oxygen_effect"] < 0:
			new_oxygen_expense -= building["oxygen_effect"]
		else:
			new_oxygen_income += building["oxygen_effect"]
		if building["metal_effect"] < 0:
			new_metal_expense -= building["metal_effect"]
		else:
			new_metal_income += building["metal_effect"]
		if building["electricity_effect"] < 0:
			new_electricity_expense -= building["electricity_effect"]
		else:
			new_electricity_income += building["electricity_effect"]
		if building["science_effect"] < 0:
			new_science_expense -= building["science_effect"]
		else:
			new_science_income += building["science_effect"]
	
	new_food_expense += 2 * people
	new_water_expense += people
	new_oxygen_expense += people

	water_expense = new_water_expense
	water_income = new_water_income
	
	food_expense = new_food_expense
	food_income = new_food_income

	oxygen_expense = new_oxygen_expense
	oxygen_income = new_oxygen_income

	metal_expense = new_metal_expense
	metal_income = new_metal_income

	electricity_expense = new_electricity_expense
	electricity_income = new_electricity_income

	science_expense = new_science_expense
	science_income = new_science_income
	
	SideBar.update_displays()

"""
	Returns the grid square the mouse is in
	Note: May return an invalid grid square when the mouse is not in the grid
"""
func getMouseSquare() -> Array:
	return [round(get_global_mouse_position()[0] / width), round(get_global_mouse_position()[1] / height)]

# called whenever the timer goes off
func _on_Timer_timeout():
	#print('Timer Called!')
	#print(getMouseSquare())
	pass

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
var Grid : Sprite # the grid object

onready var Building = preload("res://Building.tscn")
var buildings_json = "res://assets/data/buildings.json" # file path of buildings.json
var buildings_dict : Dictionary = {} # building_name -> building

# Called when the node enters the scene tree for the first time.
func _ready():
	turn = 0
	recalculate_grid_dims(15)
	SideBar = get_node("Sidebar")
	Grid = get_node("Grid")
	load_buildings_json()
	print('Got here!')

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

"""
	Place the building at the grid square (_x, _y).
"""
func place_building(_x: int, _y: int) -> void:
	# TODO: load the buildings dynamically
	var building = Building.instance()
	
	# Testing out a farm
	var building_stats = buildings_dict["Farm"]
	var shape = building_stats.shape
	building.init_shape(shape, Color(0, 0, 0), width, 0, 0)
	# building.move_building(0, 6)
	# building.rotate_building(90)
	get_parent().add_child(building)
	buildings.push_back(building_stats)
	recalculate_incomes()
	# $Grid.visible = false

"""
	Updates self.width and self.height given a new grid_size
"""
func recalculate_grid_dims(_grid_size : int) -> void:
	grid_size = _grid_size
	width = $Grid.get_transform()[0][0] / grid_size
	height = $Grid.get_transform()[1][1] / grid_size
	print("Each grid square is " + str(width) + "x" + str(height))
	# TODO: update positions of the buildings that already are on the grid

"""
	Returns a Vector2 representing the position of the grid square (_x, _y)
"""
func getGridSquareVector(_x : int, _y : int) -> Vector2:
	assert(0 <= _x and _x < grid_size and 0 <= _y and _y < grid_size)
	# TODO: check that the grid square is available
	return Vector2(width * _x, height * _y)

"""
	# Calculate the total income we have
"""
func recalculate_incomes() -> void:
	var new_water_expense : int = 0
	var new_water_income : int = 0

	for building in buildings:
		print(building["water_effect"])
		if building["water_effect"] < 0:
			new_water_expense -= building["water_effect"]
		else:
			new_water_income += building["water_effect"]

	water_expense = new_water_expense
	water_income = new_water_income
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

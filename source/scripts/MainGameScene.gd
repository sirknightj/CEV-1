extends Node2D


var turn # the current turn
var population # the current population
var _turn_count_text # the text holder object that displays "Turn: 69"

# note: we need income/expense to be seperate so that we can pass that into the graph
var water : int          # the amount of water we have on turn
var water_income : int   # the amount of water we gain on the next turn
var water_expense : int  # the amount of water we will expend on the next turn
# TODO: the other resources

# Grid Variables
# A mutable grid_size x grid_size grid that buildings can be placed in.
# We can represent a grid square as (m, n), where (0, 0) is the top-left square,
# (0, grid_size - 1) is the top-right square, and (grid_size - 1, grid_size - 1)
# is the bottom-right square.
var width : int   # the width per square
var height : int  # the height per square
var grid_size : int   # the number of squares the width of this grid is
var buildings : Array # the buildings that we own on this grid

onready var Building = preload("res://Building.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	turn = 0
	recalculate_grid_dims(15)
	print('Got here!')

"""
	Place the building at the grid square (_x, _y).
"""
func place_building(_x: int, _y: int):
	# TODO: load the buildings dynamically
	var building = Building.instance()
	# This is the farm shape
	building.init_shape([true,  true,  true,  true,  false, false, false, false, false, false,
						 true,  true,  true,  false, false, false, false, false, false, false,
						 false, false, false, false, false, false, false, false, false, false], Color(0, 0, 0))
	get_parent().add_child(building)
	building.set_position(getGridSquareVector(10, 5))
	buildings.push_back(building)
	# $Grid.visible = false

"""
	Updates self.width and self.height given a new grid_size
"""
func recalculate_grid_dims(_grid_size : int):
	grid_size = _grid_size
	width = $Grid.get_transform()[0][0] / grid_size
	height = $Grid.get_transform()[1][1] / grid_size
	print("Each grid square is " + str(width) + "x" + str(height))
	# TODO: update positions of the buildings that already are on the grid

"""
	Returns a Vector2 representing the position of the grid square (_x, _y)
"""
func getGridSquareVector(_x : int, _y : int):
	assert(0 <= _x and _x < grid_size and 0 <= _y and _y < grid_size)
	# TODO: check that the grid square is available
	return Vector2(width * _x, height * _y)

"""
	# Calculate the total income we have
"""
func recalculate_incomes():
	for building in buildings:
		print(str(building.water_effects))

"""
	Returns the grid square the mouse is in
"""
func getMouseSquare():
	return [round(get_global_mouse_position()[0] / width), round(get_global_mouse_position()[1] / height)]

# called whenever the timer goes off
func _on_Timer_timeout():
	print('Timer Called!')
	print(getMouseSquare())

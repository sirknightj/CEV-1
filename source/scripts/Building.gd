extends Node2D
class_name Building

# A generic building. All buildings will extend this.
# TODO: Restructure the code to make this load from the csv file?

# TODO: Add the building properties
var electricity_cost = 5
var water_effects = 69

# A 2D vector representing the position of this building
var pos : Vector2 = Vector2.ZERO

var color : Color

# A 1D boolean array representing a 10x3 grid of the tiles this
# building takes up. true = occupied
# Initially empty. Buildings will override this
var matrix : Array

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	

# 
"""
	Hides/unhides the blocks that make up this building
	_matrix : a 1d boolean array representing the tiles a 10x3 2d array would take up
	_color : the color that the squares should be colored
"""
func init_shape(_matrix : Array = [], _color : Color = Color(0, 0, 0)):
	print('Init was called')
	matrix = _matrix
	color = _color
	if matrix.size() == 0:
		print('Matrix was uninitialized!')
		return

	var index : int = 0
	for child in get_children():
		child.visible = matrix[index]
		child.color = color
		index += 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

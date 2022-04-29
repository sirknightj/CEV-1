extends Node2D
class_name Building

# TODO: Restructure the code to make this load from the csv file?

# TODO: Add the building properties
var electricity_cost = 5
var water_effects = 69

# The height/width of each square of this buildnig
var size

# Coordinates of the top-left corner of this building
var posx
var posy

var color : Color

# A 2D boolean array representing a grid of the tiles this
# building takes up. true = occupied
var matrix : Array

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	

"""
	Hides/unhides the blocks that make up this building
	_matrix : a 2d boolean array representing the tiles this building will occupy
			  true = the space is occupied. false = space is empty.
	_color : the color that the squares should be colored
	_size : the height/width each square of this building should be
	_gridx : the x of the (x, y) representing the top-left corner of this building
	_gridy : the y of the (x, y) representing the top-left corner of this building
"""
func init_shape(_matrix : Array = [], _color : Color = Color(0, 0, 0), _size : int = 10, _gridx : int = 0, _gridy : int = 0) -> void:
	print('Init was called')
	matrix = _matrix
	color = _color
	size = _size
	if matrix.size() == 0:
		print('Matrix was uninitialized!')
		return

	var x : int = 0
	for _x in _matrix:
		var y : int = 0
		for _y in _x:
			if _y:
				var grid_square : ColorRect = ColorRect.new()
				grid_square.color = color
				grid_square.set_position(Vector2(y * size, x * size)) # the position relative to the top-left corner of this building
				grid_square.rect_size = Vector2(size, size)
				add_child(grid_square)
			y += 1
		x += 1
	posx = _gridx
	posy = _gridy
	set_position(getGridSquareVector(posx, posy))

"""
	Rotates this building by some degrees. The top-left corner of the building does not change.
"""
func rotate_building(degrees : int) -> void:
	assert(degrees % 90 == 0)
	# The number of clockwise rotations we need to perform
	var rotations = degrees / 90
	if rotations < 0:
		rotations += 4
	
	for k in range(rotations):
		# Rotate clockwise once
		var new_matrix : Array = []
		for i in range(len(matrix[0])):
			var row = []
			for j in range(len(matrix)):
				row.append(matrix[len(matrix) - j - 1][i])
			new_matrix.append(row)
		matrix = new_matrix
	
	# Now, we delete and recreate the children
	for child in get_children():
		remove_child(child)

	var x : int = 0
	for _x in matrix:
		var y : int = 0
		for _y in _x:
			if _y:
				print(str(x) + " " + str(y))
				var grid_square : ColorRect = ColorRect.new()
				grid_square.color = color
				grid_square.set_position(Vector2(y * size, x * size)) # the position relative to the top-left corner of this building
				grid_square.rect_size = Vector2(size, size)
				add_child(grid_square)
			y += 1
		x += 1

"""
	Changes size of the squares this building is made of.
"""
func resize_building(box_size : int) -> void:
	for child in get_children():
		child.set_position(child.get_position() / size * box_size)
		child.rect_size = Vector2(box_size, box_size)
	size = box_size

"""
	Moves this building to a different (x, y). The (x, y) represent the
	new top-left position of this building on the grid.
"""
func move_building(x : int, y : int):
	posx = x
	posy = y
	set_position(getGridSquareVector(posx, posy))

"""
	Returns a Vector2 representing the position of the grid square (_x, _y)
"""
func getGridSquareVector(_x : int, _y : int) -> Vector2:
	return Vector2(size * _x, size * _y)

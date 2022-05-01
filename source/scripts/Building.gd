extends Node2D
class_name Building

enum MouseState {
	NONE,
	HOVER,
	DRAGGING
}

var _mouse_state : int = MouseState.NONE
var _mouse_enters : int = 0
var _overlapping_areas : int = 0
var _original_rot : float = 0

var _shadow : Node2D
var _original_pos : Vector2

export(Array) var shape
export(float) var size
var square_scene = preload("res://scenes/GridSquare.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	_original_pos = global_position
	_shadow = get_node("Shadow")
	init_shape()

func init_shape():
	assert(shape.size() > 0)

	var x : int = 0
	for _x in shape:
		var y : int = 0
		for _y in _x:
			if _y:
				setup_main_square(create_grid_square(x, y, self))
				setup_shadow_square(create_grid_square(x, y, _shadow))
			y += 1
		x += 1

"""
	Create a grid square
	x : The x of the (x, y) representing the top-left corner of this building
	y : The y of the (x, y) representing the top-left corner of this building
	parent : The parent node to add the grid square to as a child
"""
func create_grid_square(x : int, y : int, parent : Node):
	var grid_square : GridSquare = square_scene.instance()
	parent.add_child(grid_square)
	grid_square.set_position(Vector2(y * size + size / 2, x * size + size / 2))
	grid_square.set_sprite_size(size)
	return grid_square

"""
	Set up a grid square for the main object by connecting proper events
	grid_square : The grid square to set up
"""
func setup_main_square(grid_square : GridSquare):
	grid_square.connect("mouse_entered", self, "_on_MainSquare_mouse_entered")
	grid_square.connect("mouse_exited", self, "_on_MainSquare_mouse_exited")
	grid_square.set_collision_box_size(size)
	return grid_square

"""
	Set up a grid square for the shadow object by connecting proper events
	grid_square : The grid square to set up
"""
func setup_shadow_square(grid_square : GridSquare):
	grid_square.connect("area_entered", self, "_on_ShadowSquare_area_entered")
	grid_square.connect("area_exited", self, "_on_ShadowSquare_area_exited")
	grid_square.is_shadow_square = true
	# Smaller than the regular collision box in order to detect collisions
	# properly, otherwise it is too sensitive to the edges of blocks
	#
	# Note that even if this was 1x1 it should be fine because collision is
	# checked using the entirety of the shadow. If the entire block does not
	# fit, it will not accept that position
	grid_square.set_collision_box_size(size / 2)
	return grid_square

func building_mouse_entered():
	if (_mouse_state == MouseState.NONE):
		_mouse_state = MouseState.HOVER

func building_mouse_exited():
	if (_mouse_state == MouseState.HOVER):
		_mouse_state = MouseState.NONE

"""
	Rotate around a given point, such that the relative point on the building
	is at the same global position before and after the rotation
	rotation_position : The global position to rotate around
	rotation_angle : The angle (in radians) to rotate by
"""
func rotate_around(rotation_position : Vector2, rotation_angle : float):
	var relative = rotation_position - global_position
	var rotated = relative.rotated(rotation_angle)
	var diff = relative - rotated
	rotation += rotation_angle
	global_position += diff

"""
	Returns true if the Building is currently overlapping something, false
	otherwise
"""
func is_overlapping() -> bool:
	return _overlapping_areas != 0

func _process(_delta):
	if (_mouse_state == MouseState.HOVER):
		set_modulate(Color.aqua)
	elif (_mouse_state == MouseState.DRAGGING):
		set_modulate(Color.chartreuse)
	else:
		set_modulate(Color.white)

	if (_mouse_state == MouseState.DRAGGING):
		_shadow.visible = true
	else:
		_shadow.visible = false

func _unhandled_input(event : InputEvent):
	if (event is InputEventMouseButton
			&& event.button_index == BUTTON_LEFT):
		if (event.pressed && _mouse_state == MouseState.HOVER):
			_original_pos = global_position
			_original_rot = rotation
			_mouse_state = MouseState.DRAGGING
		elif (!event.pressed && _mouse_state == MouseState.DRAGGING):
			_mouse_state = MouseState.HOVER
			if (is_overlapping()):
				global_position = _original_pos
				rotation = _original_rot
			else:
				global_position = snapped()

	if (event is InputEventMouseMotion
			&& _mouse_state == MouseState.DRAGGING):
		global_position = global_position + event.relative
		_shadow.global_position = snapped()

	if (event.is_action_pressed("building_rotate")
			&& _mouse_state == MouseState.DRAGGING):
		rotate_around(get_global_mouse_position(), PI/2)

func _on_MainSquare_mouse_entered():
	_mouse_enters += 1
	if (_mouse_enters == 1):
		building_mouse_entered()

func _on_MainSquare_mouse_exited():
	_mouse_enters -= 1
	if (_mouse_enters == 0):
		building_mouse_exited()

func _on_ShadowSquare_area_entered(area : Area2D):
	if (area.get_parent() != _shadow
			&& area is GridSquare
			&& area.is_shadow_square):
		_overlapping_areas += 1

func _on_ShadowSquare_area_exited(area : Area2D):
	if (area.get_parent() != _shadow
			&& area is GridSquare
			&& area.is_shadow_square):
		_overlapping_areas -= 1

func snapped() -> Vector2:
	return global_position.snapped(Vector2(size, size))

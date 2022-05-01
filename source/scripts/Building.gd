extends Node2D

enum MouseState {
	NONE,
	HOVER,
	DRAGGING
}

var mouse_state : int = MouseState.NONE
var mouse_enters : int = 0

var squares : Array
export(Array) var shape
export(float) var size
var square_scene = preload("res://scenes/GridSquare.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	init_shape()

func init_shape():
	assert(shape.size() > 0)

	var x : int = 0
	for _x in shape:
		var y : int = 0
		for _y in _x:
			if _y:
				add_child(create_grid_square(x, y))
			y += 1
		x += 1

"""
	x : The x of the (x, y) representing the top-left corner of this building
	y : The y of the (x, y) representing the top-left corner of this building
"""
func create_grid_square(x : int, y : int):
	var grid_square : Area2D = square_scene.instance()
	# the position relative to the top-left corner of this building
	grid_square.set_position(Vector2(y * size, x * size))
	grid_square.get_node("Shape/Sprite").scale = Vector2(size / 64, size / 64)
	grid_square.get_node("Shape").shape.extents = Vector2(size / 2, size / 2)
	grid_square.connect("mouse_entered", self, "_on_GridSquare_mouse_entered")
	grid_square.connect("mouse_exited", self, "_on_GridSquare_mouse_exited")
	return grid_square

func _process(delta):
	if (mouse_state == MouseState.HOVER):
		set_modulate(Color.aqua)
	elif (mouse_state == MouseState.DRAGGING):
		set_modulate(Color.chartreuse)
	else:
		set_modulate(Color.white)

func _unhandled_input(event):
	if (event is InputEventMouseButton
			&& event.button_index == BUTTON_LEFT):
		if (event.pressed && mouse_state == MouseState.HOVER):
			mouse_state = MouseState.DRAGGING
		elif (!event.pressed && mouse_state == MouseState.DRAGGING):
			mouse_state = MouseState.HOVER
			snap()

	if (event is InputEventMouseMotion
			&& mouse_state == MouseState.DRAGGING):
		global_position = global_position + event.relative

	if (event.is_action_pressed("building_rotate")
			&& mouse_state == MouseState.DRAGGING):
		var relative = get_global_mouse_position() - global_position
		var rotated = relative.rotated(PI/2)
		var diff = relative - rotated
		rotation += PI/2
		global_position += diff

func building_mouse_entered():
	mouse_state = MouseState.HOVER

func building_mouse_exited():
	mouse_state = MouseState.NONE

func _on_GridSquare_mouse_entered():
	mouse_enters += 1
	if (mouse_enters == 1):
		building_mouse_entered()

func _on_GridSquare_mouse_exited():
	mouse_enters -= 1
	if (mouse_enters == 0):
		building_mouse_exited()

func snap():
	global_position = global_position.snapped(Vector2(size, size))

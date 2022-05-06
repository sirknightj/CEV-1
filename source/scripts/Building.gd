extends Node2D
class_name Building

const HOVER_MODULATE : Color = Color.white
const DRAGGING_MODULATE : Color = Color.white
const REGULAR_MODULATE : Color = Color.white

const DRAGGING_Z_INDEX : int = 10
const REGULAR_Z_INDEX : int = 1

const SPRITE_BASE_SIZE : int = 1

const _size : float = GameData.SQUARE_SIZE

"""
	Buildings keep track of all of their own state, including resources, whether
	or not they are active, their position, and their movement

	In order to facilitate dragging, dropping, and snapping to the grid, there
	are three objects for every building:
	- The "main" building: This is the object that the player can drag around
	  It interacts with the mouse to detect dragging and dropping, and works
	  with other objects to determine where it is safe to be placed.
	- The "shadow" building: This is the slightly transparent copy of the
	  building that the player sees when they are dragging the building around.
	  It represents what the building looks like snapped to the grid and is the
	  source of truth for where the building will be dropped when the player
	  releases it. It contains no logic of its own and is parented to the main
	  game tree (not the building object itself) in order to be independent from
	  the position and behavior of the main building.
	- The "ghost" building: This is an invisible copy of the building which
	  handles collision detection with other buildings. Its position is always
	  snapped to the grid, unlike the building's position which follows the
	  mouse when being dragged.

	All buildings are made up of GridSquare objects which are squares of the
	right size and shape to fit the grid. The GridSquare objects hold the actual
	collision detectors and render the actual textures for the building.
"""
var _shadow : Node2D
var _ghost : Node2D

enum MouseState {
	NONE,
	HOVER,
	DRAGGING,
	HOLDING
}

var _last_mouse_pos : Vector2
var _mouse_state : int = MouseState.NONE
var _mouse_enters : int = 0
var _overlapping_areas : int = 0
var square_scene = preload("res://scenes/GridSquare.tscn")

"""
	These are needed because of the following Godot bug:
	https://github.com/godotengine/godot/issues/43743

	The physics engine cannot keep up with fast movement from things like mouse
	input. In order to mitigate this instead of changing the true position of
	the building when the mouse moves, we change the "next" position variable
	which we eventually set the true position to on every physics step.
"""
var _global_pos_next : Vector2
var _global_rot_next : float

export(bool) var enabled = true
export(bool) var locked = false
export(Array) var shape
export(Dictionary) var building_effects
export(Dictionary) var building_cost
export(int) var building_id = -1
export(Color) var color
export(Texture) var texture

func init_shadow():
	remove_child(_shadow)
	get_parent().add_child(_shadow)

# Called when the node enters the scene tree for the first time.
func _ready():
	assert(shape != null)
	assert(building_effects != null)
	assert(building_cost != null)
	assert(color != null)
	assert(texture != null)

	if (building_id > 0 && building_id < GameData.BuildingType.size()):
		set_name("AUTOGEN_" + GameData.BuildingType.keys()[building_id])
	_last_mouse_pos = get_global_mouse_position()
	_global_pos_next = global_position
	_global_rot_next = 0
	_shadow = get_node("Shadow")
	_ghost = get_node("Ghost")
	call_deferred("init_shadow")

	var scale = Vector2(_size / SPRITE_BASE_SIZE, _size / SPRITE_BASE_SIZE)
	$Sprite.texture = texture
	$Sprite.scale = scale
	_shadow.get_node("Sprite").texture = texture
	_shadow.get_node("Sprite").scale = scale

	init_shape()
	add_to_group("buildings")

func init_shape():
	assert(shape.size() > 0)

	for x in range(shape.size()):
		for y in range(shape[x].size()):
			if (shape[x][y]):
				setup_main_square(create_grid_square(x, y, self))
				create_grid_square(x, y, _shadow).set_collision_box_size(_size)
				setup_ghost_square(create_grid_square(x, y, _ghost))

"""
	Create a grid square
	x : The x of the (x, y) representing the top-left corner of this building
	y : The y of the (x, y) representing the top-left corner of this building
	parent : The parent node to add the grid square to as a child
"""
func create_grid_square(x : int, y : int, parent : Node):
	var grid_square : GridSquare = square_scene.instance()
	parent.add_child(grid_square)
	grid_square.set_position(Vector2(y * _size + _size / 2, x * _size + _size / 2))
	return grid_square

"""
	Set up a grid square for the main object by connecting proper events
	grid_square : The grid square to set up
"""
func setup_main_square(grid_square : GridSquare):
	grid_square.connect("mouse_entered", self, "_on_MainSquare_mouse_entered")
	grid_square.connect("mouse_exited", self, "_on_MainSquare_mouse_exited")
	grid_square.collision_layer = 4
	grid_square.collision_mask = 4
	# Needs to be ever so slightly larger than the actual grid snap size so
	# that adjacent buildings can be detected
	grid_square.set_collision_box_size(_size + 1)
	return grid_square

"""
	Set up a grid square for the ghost object by connecting proper events
	grid_square : The grid square to set up
"""
func setup_ghost_square(grid_square : GridSquare):
	grid_square.connect("area_entered", self, "_on_GhostSquare_area_entered")
	grid_square.connect("area_exited", self, "_on_GhostSquare_area_exited")
	# Only collide with other ghost squares
	grid_square.collision_layer = 2
	grid_square.collision_mask = 2
	# Smaller than the regular collision box in order to detect collisions
	# properly, otherwise it is too sensitive to the edges of blocks
	#
	# Note that even if this was 1x1 it should be fine because collision is
	# checked using the entirety of the shadow. If the entire block does not
	# fit, it will not accept that position
	grid_square.set_collision_box_size(_size / 2)
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
	var relative = rotation_position - _global_pos_next
	var rotated = relative.rotated(rotation_angle)
	var diff = relative - rotated
	_global_rot_next += rotation_angle
	_global_pos_next += diff

"""
	Returns true if the Building is currently overlapping something, false
	otherwise
"""
func is_overlapping() -> bool:
	return _overlapping_areas != 0

func snapped(position) -> Vector2:
	return position.snapped(Vector2(_size, _size))

func get_effect(resource_type : int) -> float:
	assert(GameData.is_resource_type(resource_type))
	if (!enabled):
		return 0.0
	return building_effects[resource_type]

func get_adjacent_buildings() -> Array:
	var buildings : Dictionary = {}
	for grid_square in get_children():
		if (!(grid_square is GridSquare)):
			continue
		var adjacents : Array = grid_square.get_adjacent_buildings()
		for adjacent in adjacents:
			buildings[adjacent] = true
	return buildings.keys()

func _update_shadow():
	_shadow.global_position = snapped(_ghost.global_position)
	_shadow.rotation = rotation

func _update_ghost():
	_ghost.global_position = snapped(global_position)

func _process(_delta):
	if (locked):
		return

	if (_mouse_state == MouseState.HOVER):
		set_modulate(HOVER_MODULATE)
	elif (_mouse_state == MouseState.DRAGGING):
		set_modulate(DRAGGING_MODULATE)
		set_z_index(DRAGGING_Z_INDEX)
	else:
		set_modulate(REGULAR_MODULATE)
		set_z_index(REGULAR_Z_INDEX)

	if (_mouse_state == MouseState.DRAGGING):
		_shadow.visible = true
	else:
		_shadow.visible = false

func _physics_process(_delta):
	if (!is_overlapping()):
		_update_shadow()
	global_position = _global_pos_next
	rotation = _global_rot_next
	_update_ghost()

func _unhandled_input(event : InputEvent):
	if (locked):
		return

	if (event.is_action_pressed("building_grab")):
		if (_mouse_state == MouseState.HOVER):
			print("Grab ", get_name())
			print("Adjacents: ", get_adjacent_buildings())
			_last_mouse_pos = get_global_mouse_position()
			_mouse_state = MouseState.DRAGGING
		else:
			_mouse_state = MouseState.HOLDING

	if (event.is_action_released("building_grab")):
		if (_mouse_state == MouseState.DRAGGING):
			_mouse_state = MouseState.HOVER
			_global_pos_next = _shadow.global_position
			_global_rot_next = _shadow.rotation
		else:
			_mouse_state = MouseState.NONE

	if (event.is_action_pressed("building_rotate")
			&& _mouse_state == MouseState.DRAGGING):
		rotate_around(get_global_mouse_position(), PI/2)

	if (event is InputEventMouseMotion
			&& _mouse_state == MouseState.DRAGGING):
		_global_pos_next += (get_global_mouse_position() - _last_mouse_pos)
		_last_mouse_pos = get_global_mouse_position()

func _on_MainSquare_mouse_entered():
	_mouse_enters += 1
	if (_mouse_enters == 1):
		building_mouse_entered()

func _on_MainSquare_mouse_exited():
	_mouse_enters -= 1
	if (_mouse_enters == 0):
		building_mouse_exited()

func _on_GhostSquare_area_entered(area : Area2D):
	_overlapping_areas += 1

func _on_GhostSquare_area_exited(area : Area2D):
	_overlapping_areas -= 1

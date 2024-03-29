extends Node2D
class_name Building

signal building_changed(building)
signal building_grabbed(building)
signal building_released(building)
signal building_destroy(building)
signal building_hovered(building)
signal building_hovered_off(building)

const HOVER_MODULATE : Color = Color.white
const DRAGGING_MODULATE : Color = Color.white
var REGULAR_MODULATE : Color = Color.white.darkened(0.2)

const DRAGGING_Z_INDEX : int = 10
const REGULAR_Z_INDEX : int = 1

const SPRITE_BASE_SIZE : int = 9

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
var _main : Node2D
var _shadow : Node2D
var _ghost : Node2D

enum MouseState {
	# The building is free to be selected
	NONE,
	# The mouse is hovering over the building
	HOVER,
	# The building is being dragged by the mouse
	DRAGGING,
	# The building is being selected along with multiple other buildings
	MULTISELECT,
	MULTISELECTHOVER,
	MULTISELECTDRAGGING
}

var _main_flipped : bool = false
var _ghost_flipped : bool = false
var _shadow_flipped : bool = false

var _last_mouse_pos : Vector2
var _mouse_state : int = MouseState.NONE
var _mouse_enters : int = 0
var _overlapping_areas : int = 0
var square_scene = preload("res://scenes/GridSquare.tscn")
var trash_icon = preload("res://assets/images/trash.png")
var refund_icon = preload("res://assets/images/refund.png")

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
var _emit_release_on_next_physics : bool = false
var _main_flipped_next : bool = false
var _ghost_flipped_next : bool = false
var _shadow_flipped_next : bool = false
var building_pos : Vector2

var _original_pos : Vector2
var _original_rot : float
var _original_flipped : bool

export(bool) var enabled = false
export(bool) var locked = false
export(bool) var purchased = false
export(bool) var saleable = true
export(Array) var shape
export(Dictionary) var building_effects
export(Dictionary) var building_cost
export(int) var building_id = -1
export(Color) var color
export(Texture) var texture

var purchase_turn = 0

var building_effect_upgrades : Dictionary = {}

func deserialize(data):
	name = data.name
	building_id = int(data.id)
	purchased = data.purchased
	enabled = data.enabled
	locked = data.locked
	force_set(GameStats.grid.grid_to_global(Vector2(data.current_pos.x, data.current_pos.y)), data.rotation, data.flipped)
	emit_signal("building_released", self)

func serialize():
	var moving = GameStats.grid.global_to_grid(_main.global_position)
	var original = GameStats.grid.global_to_grid(_original_pos)
	var pos = GameStats.grid.global_to_grid(_shadow.global_position)
	var serialized_upgrades = []
	for upgrade in building_effect_upgrades.keys():
		serialized_upgrades.append(upgrade.serialize())
	return {
		"name": name,
		"id": building_id,
		"current_pos": {
			"x": pos.x,
			"y": pos.y
		},
		"moving_pos": {
			"x": moving.x,
			"y": moving.y
		},
		"original_pos": {
			"x": original.x,
			"y": original.y
		},
		"rotation": _shadow.rotation,
		"moving_rotation": _main.rotation,
		"original_rotation": _original_rot,
		"flipped": _shadow_flipped,
		"moving_flipped": _main_flipped,
		"original_flipped": _original_flipped,
		"upgrades": serialized_upgrades,
		"purchased": purchased,
		"enabled": enabled,
		"locked": locked
	}

func log_building_action(action, metadata = null):
	var data = {
		"group0": GameStats.logger.get_group(0),
		"group1": GameStats.logger.get_group(1),
		"building": serialize()
	}
	if metadata != null:
		data.action_data = metadata
	GameStats.logger.log_level_action(action, data)

func _setup_sprite(sprite : Sprite, flipped : bool):
	var scale = Vector2(_size / SPRITE_BASE_SIZE, _size / SPRITE_BASE_SIZE)
	sprite.texture = texture
	sprite.scale = scale
	sprite.flip_h = flipped

# Called when the node enters the scene tree for the first time.
func _ready():
	assert(shape != null)
	assert(building_effects != null)
	assert(building_cost != null)
	assert(color != null)
	assert(texture != null)
	assert(building_id != -1)
	
	if building_id == GameData.BuildingType.END1:
		saleable = false

	_main = get_node("Main")
	if (building_id > 0 && building_id < GameData.BuildingType.size()):
		set_name("AUTOGEN_" + GameData.BuildingType.keys()[building_id])
	_last_mouse_pos = get_global_mouse_position()
	_global_pos_next = _main.global_position
	_global_rot_next = 0
	_shadow = get_node("Shadow")
	_ghost = get_node("Ghost")
	reset_graphics()
	set_state(MouseState.NONE)
	set_physics_process(false)

	add_to_group("buildings")

func clear(node : Node2D):
	for child in node.get_children():
		if child is GridSquare:
			child.free()

func reset_graphics():
	_mouse_enters = 0
	building_mouse_exited()
	_setup_sprite(_main.get_node("Sprite"), _main_flipped)
	_setup_sprite(_shadow.get_node("Sprite"), _shadow_flipped)
	clear(_main)
	clear(_ghost)
	clear(_shadow)
	init_shape()

func setup_main(x : int, y : int):
	setup_main_square(create_grid_square(x, y, _main))

func setup_shadow(x : int, y : int):
	setup_shadow_square(create_grid_square(x, y, _shadow))

func setup_ghost(x : int, y : int):
	setup_ghost_square(create_grid_square(x, y, _ghost))

func init_shape():
	assert(shape.size() > 0)

	for x in range(shape.size()):
		for y in range(shape[x].size()):
			if shape[x][y]:
				if _main_flipped:
					setup_main(x, shape[x].size() - y - 1)
				else:
					setup_main(x, y)
				if _ghost_flipped:
					setup_ghost(x, shape[x].size() - y - 1)
				else:
					setup_ghost(x, y)
				if _shadow_flipped:
					setup_shadow(x, shape[x].size() - y - 1)
				else:
					setup_shadow(x, y)

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
	grid_square.set_collision_box_size(_size)
	return grid_square

func setup_shadow_square(grid_square : GridSquare):
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
	if ((_mouse_state == MouseState.NONE and GameStats.current_selected_building == null)
			or _mouse_state == MouseState.MULTISELECT):
		GameStats.current_hovered_building = self
		if _mouse_state == MouseState.MULTISELECT:
			set_state(MouseState.MULTISELECTHOVER)
		else:
			set_state(MouseState.HOVER)
			emit_signal("building_hovered", self)
		if locked:
			Input.set_default_cursor_shape(Input.CURSOR_FORBIDDEN)
		else:
			Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)

func building_mouse_exited():
	if _mouse_state == MouseState.HOVER or _mouse_state == MouseState.MULTISELECTHOVER:
		if _mouse_state == MouseState.MULTISELECTHOVER:
			set_state(MouseState.MULTISELECT)
		else:
			set_state(MouseState.NONE)
			emit_signal("building_hovered_off", self)
		if GameStats.current_hovered_building == self:
			Input.set_default_cursor_shape(Input.CURSOR_ARROW)
			GameStats.current_hovered_building = null

func set_next_pos(pos : Vector2):
	_global_pos_next = pos
	_main.global_position = pos
	_ghost.global_position = pos
	_shadow.global_position = pos

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

func add_building_effect_upgrade(upgrade : BuildingEffectUpgrade):
	building_effect_upgrades[upgrade] = true
	emit_signal("building_changed", self)

func has_building_effect_upgrade(upgrade : BuildingEffectUpgrade):
	return building_effect_upgrades.has(upgrade)

func remove_building_effect_upgrade(upgrade : BuildingEffectUpgrade):
	if building_effect_upgrades.has(upgrade):
		building_effect_upgrades.erase(upgrade)
		emit_signal("building_changed", self)

func get_base_effect(resource_type : int) -> float:
	assert(GameData.is_resource_type(resource_type))
	if not enabled:
		return 0.0
	return building_effects[resource_type]

func get_effect(resource_type : int) -> float:
	var effect = get_base_effect(resource_type)
	for upgrade in building_effect_upgrades.keys():
		effect = upgrade.stack_effect(self, resource_type, effect)
	return effect

func get_adjacent_buildings() -> Array:
	var buildings : Dictionary = {}
	for grid_square in _shadow.get_children():
		if not (grid_square is GridSquare):
			continue
		var adjacents : Array = grid_square.get_adjacent_buildings()
		for adjacent in adjacents:
			buildings[adjacent] = true
	return buildings.keys()

"""
	Buy the Building with our stored cost if needed (the building has not been
	purchased yet) and possible (there are enough resources to buy it).
	Returns true iff purchase successful (and not previously purchased)
"""
func purchase_building() -> bool:
	if purchased or not GameStats.resources.try_consume(building_cost):
		return false
	purchased = true
	purchase_turn = GameStats.turn
	# Automatically enable on purchase
	enabled = true
	emit_signal("building_hovered", self)
	log_building_action(Logger.Actions.BuildingPlaced)
	return true

func check_trash():
	if is_in_trash_area():
		if has_moved() or purchased:
			if purchased and (not saleable or not GameStats.selling_enabled):
				if not GameStats.selling_enabled:
					var text = "Selling is currently disabled."
					var tt = get_node("../../MainGameScene/UpperLayer/TutorialText")
					if tt.text != text:
						tt.text = text
						get_node("/root/MainGameScene/AudioAlert").play()
				Input.set_default_cursor_shape(Input.CURSOR_FORBIDDEN)
			elif refundable():
				if GameStats.show_sell_yes_refund_message and purchased:
					var to_show = ""
					if true: # TODO: possible upgrade for refunds?
						to_show = "Since this building was built on this turn, you'll receive a full refund!"
					else:
						to_show = "Demolishing a building will give you a full refund!"
					if get_node("../../MainGameScene/UpperLayer/TutorialText").text != to_show:
						get_node("../../MainGameScene/UpperLayer/TutorialText").text = to_show
						get_node("/root/MainGameScene/AudioAlert").play()
						GameStats.show_sell_yes_refund_message -= 1
				if purchased:
					Input.set_custom_mouse_cursor(refund_icon)
				elif has_moved():
					Input.set_custom_mouse_cursor(trash_icon)
				else:
					Input.set_custom_mouse_cursor(null)
			else:
				Input.set_custom_mouse_cursor(trash_icon)
		_shadow.visible = false
	else:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		Input.set_custom_mouse_cursor(null)
		if has_moved():
			_shadow.visible = true

func _update_shadow():
	_shadow_flipped_next = _ghost_flipped
	_shadow.global_position = snapped(_ghost.global_position)
	_shadow.rotation = _ghost.rotation
	if (_mouse_state == MouseState.DRAGGING or _mouse_state == MouseState.MULTISELECTDRAGGING):
		_shadow.visible = true
	else:
		_shadow.visible = false

func _update_ghost() -> void:
	_ghost.global_position = snapped(_main.global_position)
	_ghost.rotation = _main.rotation

func _is_in_grid_range() -> bool:
	for child in _ghost.get_children():
		var _position : Vector2 = child.global_position / _size
		var edge = GameStats.grid_size / 2 + 0.1
		if _position.x < -edge or _position.x > edge + 1 or _position.y < -edge or _position.y > edge + 1:
			return false
	return true

func set_locked(is_locked: bool) -> void:
	locked = is_locked
	set_state(_mouse_state)
	if material:
		material.set_shader_param('saturation', 0 if locked else 1)

func set_state(state):
	_mouse_state = state
	if locked:
		return

	if (_mouse_state == MouseState.HOVER
			or _mouse_state == MouseState.MULTISELECT
			or _mouse_state == MouseState.MULTISELECTHOVER):
		set_modulate(HOVER_MODULATE)
	elif (_mouse_state == MouseState.DRAGGING
			or _mouse_state == MouseState.MULTISELECTDRAGGING):
		set_modulate(DRAGGING_MODULATE)
		set_z_index(DRAGGING_Z_INDEX)
	else:
		set_modulate(REGULAR_MODULATE)
		set_z_index(REGULAR_Z_INDEX)

func _update_main():
	_main.global_position = _global_pos_next
	_main.rotation = _global_rot_next

func _physics_process(_delta):
	if _mouse_state == MouseState.DRAGGING and not is_overlapping() and _is_in_grid_range():
		_update_shadow()
	_update_main()
	_update_ghost()
	if _emit_release_on_next_physics:
		_emit_release_on_next_physics = false
		set_physics_process(false)
		emit_signal("building_released", self)
		if _mouse_enters > 0:
			building_mouse_entered()
	if (_main_flipped_next != _main_flipped
			or _shadow_flipped_next != _shadow_flipped
			or _ghost_flipped_next != _ghost_flipped):
		_main_flipped = _main_flipped_next
		_ghost_flipped = _ghost_flipped_next
		_shadow_flipped = _shadow_flipped_next
		reset_graphics()

func has_moved():
	return _shadow.global_position != _original_pos or _shadow.rotation != _original_rot or _shadow_flipped != _original_flipped

func set_building_flip(flipped : bool):
	_main_flipped_next = flipped
	_ghost_flipped_next = flipped

func force_set(pos : Vector2, rot : float, flip : bool):
	_original_pos = pos
	_original_rot = rot
	_global_pos_next = pos
	_global_rot_next = rot
	_main.global_position = pos
	_main.rotation = rot
	_ghost.global_position = pos
	_ghost.rotation = rot
	_shadow.global_position = pos
	_shadow.rotation = rot
	_shadow_flipped_next = flip
	_ghost_flipped_next = flip
	_main_flipped_next = flip
	_shadow_flipped = flip
	_ghost_flipped = flip
	_main_flipped = flip
	reset_graphics()

func refund():
	if not purchased:
		return
	for resource in building_cost.keys():
		if building_cost[resource] > 0:
			GameStats.resources.give(resource, building_cost[resource])
	
	if not GameStats.restrictions.empty():
		if GameStats.restrictions.has(building_id):
			GameStats.restrictions[building_id] += 1
		else:
			GameStats.restrictions[building_id] = 1

func refundable():
	if false: # TODO: possible upgrade to make refunds always happen?
		return true
	else:
		return not purchased or GameStats.turn == purchase_turn

func destroy():
	if _mouse_state == MouseState.DRAGGING:
		emit_signal("building_released", self)
	remove_from_group("buildings")
	log_building_action(Logger.Actions.BuildingDeleted, {
		"refunded": refundable()
	})
	GameStats.current_selected_building = null
	Input.set_custom_mouse_cursor(null)
	set_state(MouseState.NONE)
	queue_free()
	if refundable():
		refund()
	emit_signal("building_destroy", self)
	emit_signal("building_hovered_off", self)

func _on_building_place():
	var old_purchased = purchased
	if _mouse_state == MouseState.DRAGGING:
		if is_in_trash_area():
			if not purchased or GameStats.selling_enabled:
				if not saleable and purchased:
					get_node("../../MainGameScene/UpperLayer/TutorialText").text = "This building cannot be sold."
					get_node("/root/MainGameScene/AudioAlert").play()
				else:
					if purchased and GameStats.show_sell_no_refund_message and not refundable():
						GameStats.show_sell_no_refund_message = 0
						Input.set_custom_mouse_cursor(null)
						GameStats.dialog_box.prompt("Are you sure you want to remove this building? You cannot receive a refund for its material cost since it was built in a previous month.", "Demolish", "Cancel")
						var delete = yield(GameStats.dialog_box, "answer")
						if delete:
							destroy()
							return
					else:
						destroy()
						return
			else:
				#get_node("../../MainGameScene/UpperLayer/TutorialText").text = "Selling is currently disabled."
				#get_node("/root/MainGameScene/AudioAlert").play()
				Input.set_custom_mouse_cursor(null)
		else:
			check_trash()
		if has_moved():
			purchase_building()
		elif not purchased:
			destroy()
			return
	var old = _mouse_state
	if purchased:
		if _mouse_state == MouseState.DRAGGING:
			set_state(MouseState.HOVER)
		else:
			set_state(MouseState.NONE)
		_global_pos_next = _shadow.global_position
		_global_rot_next = _shadow.rotation
		_main_flipped_next = _shadow_flipped
		_ghost_flipped_next = _main_flipped_next
		_shadow_flipped_next = _shadow_flipped
		emit_signal("building_changed", self)
	else:
		set_state(MouseState.NONE)
		force_set(_original_pos, _original_rot, _original_flipped)
	var was_purchased = purchased and not old_purchased
	var param = "progress_rainbow" if was_purchased else "progress_highlight"
	var time = 1.8 if was_purchased else 0.5
	$Tween.interpolate_property(get_material(), "shader_param/" + param, 0, 1, time, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	$Tween.start()
	if GameStats.current_hovered_building == self:
		play(get_node("/root/MainGameScene/AudioPop"))
	_on_building_release()

func possible_enter():
	if _mouse_enters > 0:
		building_mouse_entered()

func force_update():
	_last_mouse_pos = get_global_mouse_position()

func is_in_trash_area():
	return get_global_mouse_position().x > GameStats.grid.get_pos_edge() * 1.1

func multiselect_on():
	set_state(MouseState.MULTISELECT)
	if _mouse_enters > 0:
		building_mouse_entered()

func multiselect_off():
	set_state(MouseState.NONE)

func _on_building_release():
	if not is_instance_valid(self):
		return
	if GameStats.current_selected_building == self:
		GameStats.current_selected_building = null
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	_emit_release_on_next_physics = true
	if (_mouse_enters == 0):
		building_mouse_exited()
	log_building_action(Logger.Actions.BuildingReleased)

func play(audio : AudioStreamPlayer):
	audio.stop()
	audio.play()

func _on_building_grab():
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	_last_mouse_pos = get_global_mouse_position()
	_original_pos = _main.global_position
	_original_rot = _main.rotation
	set_physics_process(true)
	log_building_action(Logger.Actions.BuildingGrabbed)
	if _mouse_state != MouseState.MULTISELECTDRAGGING and GameStats.current_selected_building != null:
		set_state(MouseState.NONE)
		return
	if _mouse_state == MouseState.DRAGGING:
		GameStats.current_selected_building = self
	var audio = "AudioPop" if purchased else "AudioPickup"
	play(get_node("/root/MainGameScene/" + audio))
	emit_signal("building_grabbed", self)

func _on_building_rotate():
	rotate_around(get_global_mouse_position(), PI/2)
	log_building_action(Logger.Actions.BuildingRotated)

func _on_building_flip():
	log_building_action(Logger.Actions.BuildingFlipped)
	set_building_flip(!_main_flipped)

func _on_building_drag():
	if _mouse_state == MouseState.DRAGGING:
		check_trash()
	_global_pos_next += (get_global_mouse_position() - _last_mouse_pos)
	_last_mouse_pos = get_global_mouse_position()
	_update_main()

func _unhandled_input(event : InputEvent):
	if locked:
		return
	if not is_instance_valid(self):
		return

	var any_dragging = _mouse_state == MouseState.DRAGGING or _mouse_state == MouseState.MULTISELECTDRAGGING

	if event.is_action_pressed("building_grab") and _mouse_state == MouseState.HOVER:
		set_state(MouseState.DRAGGING)
		_on_building_grab()
	elif (event.is_action_pressed("building_grab")
			and ((_mouse_state == MouseState.MULTISELECT
				or _mouse_state == MouseState.MULTISELECTHOVER))
				and GameStats.current_hovered_building != null):
		set_state(MouseState.MULTISELECTDRAGGING)
		_on_building_grab()
	elif event.is_action_released("building_grab") and any_dragging:
		_on_building_place()
		if event.device == -1: # touch
			building_mouse_exited()
	elif event.is_action_pressed("building_rotate") and any_dragging:
		_on_building_rotate()
	elif (event.is_action_pressed("building_flip")
			and (_mouse_state == MouseState.DRAGGING
				or _mouse_state == MouseState.MULTISELECTDRAGGING and GameStats.multiselect_drag == MultiSelector.DragMode.Drag)):
		_on_building_flip()
	elif (event is InputEventMouseMotion
			and event.relative != Vector2(0.0, 0.0)
			and any_dragging):
		_on_building_drag()

func _on_MainSquare_mouse_entered():
	_mouse_enters += 1
	if (_mouse_enters == 1):
		call_deferred("building_mouse_entered")

func _on_MainSquare_mouse_exited():
	_mouse_enters -= 1
	if (_mouse_enters == 0):
		call_deferred("building_mouse_exited")

func _on_GhostSquare_area_entered(area : Area2D):
	_overlapping_areas += 1

func _on_GhostSquare_area_exited(area : Area2D):
	_overlapping_areas -= 1

func is_symmetrical():
	for x in range(shape.size()):
		for y in range(shape[x].size() / 2):
			if shape[x][y] != shape[x][shape[x].size() - y - 1]:
				return false
	return true

func _get_resource_color_as_hex(resource_type: int) -> String:
	assert(GameData.is_resource_type(resource_type))
	var color = GameData.COLORS[resource_type]
	return "#%02X%02X%02X" % [color.r8, color.g8, color.b8]

class FirstAbsSorter:
	static func sort_descending(a, b):
		a = a[0]
		b = b[0]
		if (a < 0) != (b < 0):
			return a > b
		return abs(a) > abs(b)

"""
	Returns a production list in return[0] and a consumption list in return[1]
"""
func get_production_consumption_as_bbcode() -> Array:
	var production_texts: Array = []
	var consumption_texts: Array = []

	for resource_type in GameData.ResourceType.values():
		if not GameStats.shown_resources.has(resource_type):
			continue

		var e = get_effect(resource_type)

		if e == 0:
			continue

		if resource_type == GameData.ResourceType.PEOPLE:
			var people = GameStats.resources.get_reserve(GameData.ResourceType.PEOPLE)
			e = floor(people + e) - floor(people)

		var key = GameData.RESOURCE_TYPE_TO_STRING[resource_type]

		var text = "[color=" + GameData.get_resource_color_as_hex(resource_type) + "]"
		if e >= 0:
			text += "+%s %s" % [str(abs(e)), key]
		else:
			text += "-%s %s" % [str(-e), key]
		text += "[/color]\n"
		if e < 0:
			consumption_texts.append([e, text])
		else:
			production_texts.append([e, text])
	
	production_texts.sort_custom(FirstAbsSorter, "sort_descending")
	consumption_texts.sort_custom(FirstAbsSorter, "sort_descending")

	var production = ""
	for t in production_texts:
		production += t[1]
	var consumption = ""
	for t in consumption_texts:
		consumption += t[1]

	return [production.strip_edges(), consumption.strip_edges()]

func get_effects_as_bbcode() -> String:
	var texts: Array = []

	for resource_type in building_effects:
		if not GameStats.shown_resources.has(resource_type):
			continue
		var e = building_effects[resource_type]
		for upgrade in building_effect_upgrades.keys():
			e = upgrade.stack_effect(self, resource_type, e)
		
		if e == 0:
			continue

		var key = GameData.ResourceType.keys()[resource_type].capitalize()
		if key == "Electricity":
			key = "Energy"
		
		var text = "[color=" + GameData.get_resource_color_as_hex(resource_type) + "]"
		if e > 0:
			text += "+%s %s" % [str(e), key]
		else:
			text += "-%s %s" % [str(-e), key]
		text += "[/color]\n"
		texts.append([e, text])

	texts.sort_custom(FirstAbsSorter, "sort_descending")
	var res: String = ""
	for t in texts:
		res += t[1]
	return res.strip_edges()

func get_costs_as_bbcode() -> String:
	var texts: Array = []

	for resource_type in building_cost:
		if not GameStats.shown_resources.has(resource_type):
			continue
		var e = building_cost[resource_type]
		if e == 0:
			continue

		var key = GameData.ResourceType.keys()[resource_type].capitalize()
		if key == "Electricity":
			key = "Energy"

		var text = "[color=%s]%s %s[/color]\n" % [GameData.get_resource_color_as_hex(resource_type), str(e), key]
		texts.append([e, text])
	texts.sort_custom(FirstAbsSorter, "sort_descending")
	var res: String = ""
	for t in texts:
		res += t[1]
	return res.strip_edges() if res else "[color=#666]None[/color]"

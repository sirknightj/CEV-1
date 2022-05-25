extends Node2D
class_name MultiSelector

var active : bool = false
var dragging : bool = false
var selected : Dictionary = {}
var start_pos : Vector2

enum DragMode {
	None,
	Drag
	DragRotateOnly
}

onready var rect = $ColorRect
onready var area = $Area2D
onready var collider = $Area2D/CollisionShape2D

func _ready():
	start_pos = get_global_mouse_position()
	area.connect("area_entered", self, "_on_area_entered")
	area.connect("area_exited", self, "_on_area_exited")
	set_physics_process(false)

func update_rect(end_pos):
	var top_left : Vector2
	var bottom_right : Vector2
	if end_pos.x > start_pos.x and end_pos.y > start_pos.y:
		top_left = start_pos
		bottom_right = end_pos
	elif end_pos.x > start_pos.x and end_pos.y < start_pos.y:
		top_left = Vector2(start_pos.x, end_pos.y)
		bottom_right = Vector2(end_pos.x, start_pos.y)
	elif end_pos.x < start_pos.x and end_pos.y < start_pos.y:
		top_left = end_pos
		bottom_right = start_pos
	else:
		top_left = Vector2(end_pos.x, start_pos.y)
		bottom_right = Vector2(start_pos.x, end_pos.y)
	var size = bottom_right - top_left
	rect.rect_size = size
	collider.shape.extents = size / 2
	global_position = top_left
	area.global_position = Vector2(top_left + size / 2)

func _on_area_entered(area : Area2D):
	if not active:
		return
	var building = area.get_parent().get_parent()
	if building.locked:
		return
	if not selected.has(building):
		building.call_deferred("multiselect_on")
		selected[building] = 0
	selected[building] += 1

func _on_area_exited(area : Area2D):
	if not active:
		return
	var building = area.get_parent().get_parent()
	if not selected.has(building):
		return
	selected[building] -= 1
	if selected[building] == 0:
		building.call_deferred("multiselect_off")
		selected.erase(building)

func deselect():
	for building in selected.keys():
		building.call_deferred("multiselect_off")
	selected = {}

func _physics_process(_delta):
	if not dragging:
		return
	for building in selected.keys():
		if building.is_overlapping() or not building._is_in_grid_range():
			return
	for building in selected.keys():
		building._update_shadow()

func _unhandled_input(event):
	var mouse_pos = get_global_mouse_position()
	var x : float
	var y : float
	if mouse_pos.x > 0:
		x = min(mouse_pos.x, GameStats.grid.get_pos_edge())
	else:
		x = max(mouse_pos.x, GameStats.grid.get_neg_edge())
	if mouse_pos.y > 0:
		y = min(mouse_pos.y, GameStats.grid.get_pos_edge())
	else:
		y = max(mouse_pos.y, GameStats.grid.get_neg_edge())
	var pos = Vector2(x, y)

	if (event.is_action_pressed("building_grab")
			and GameStats.grid.is_within_grid(mouse_pos)
			and GameStats.current_hovered_building == null
			and not active):
		GameStats.current_selected_building = self
		active = true
		start_pos = pos
		update_rect(pos)
		show()
	elif (event.is_action_pressed("building_grab")
			and GameStats.current_selected_building == self):
		if GameStats.current_hovered_building == null:
			active = false
			GameStats.current_selected_building = null
			deselect()
		else:
			dragging = true
			if selected.size() == 1 and not selected.keys()[0].is_symmetrical():
				GameStats.multiselect_drag = DragMode.Drag
			else:
				GameStats.multiselect_drag = DragMode.DragRotateOnly
			set_physics_process(true)
	elif event.is_action_released("building_grab"):
		if active:
			active = false
			if selected.empty():
				GameStats.current_selected_building = null
				GameStats.current_hovered_building = null
			hide()
		elif dragging:
			set_physics_process(false)
			dragging = false
			GameStats.multiselect_drag = DragMode.None
			selected = {}
			GameStats.current_selected_building = null
			GameStats.current_hovered_building = null
	elif active and event is InputEventMouseMotion:
		update_rect(pos)

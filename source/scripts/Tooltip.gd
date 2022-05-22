extends Node2D

func _ready():
	global_position = get_global_mouse_position()

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		global_position = get_global_mouse_position()

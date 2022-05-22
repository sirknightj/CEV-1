extends Node2D
class_name Tooltip

onready var _screen_size = get_viewport().get_visible_rect().size

func _ready():
	global_position = get_global_mouse_position()

func _input(event):
	if event is InputEventMouseMotion:
		var pos = get_global_mouse_position()
		if pos.y + get_height() > _screen_size.y:
			global_position = pos - Vector2(0.0, get_height())
		else:
			global_position = pos

func get_height() -> float:
	return 0.0

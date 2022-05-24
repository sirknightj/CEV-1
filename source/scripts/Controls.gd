extends Tooltip

var controls_texture = preload("res://assets/images/building-controls.png")
var controls_rotateonly_texture = preload("res://assets/images/building-controls-rotateonly.png")

var _height = 60.0

func set_rotateonly(rotateonly : bool):
	if rotateonly:
		$Sprite.texture = controls_rotateonly_texture
		_height = 35.0
	else:
		$Sprite.texture = controls_texture
		_height = 60.0

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		var building = GameStats.current_selected_building
		if GameStats.multiselect_drag != MultiSelector.DragMode.None:
			set_rotateonly(GameStats.multiselect_drag == MultiSelector.DragMode.DragRotateOnly)
			show()
		elif building != null and building is Building:
			if (building.is_in_trash_area()
					and (building.purchased or building.has_moved())):
				hide()
			else:
				set_rotateonly(building.is_symmetrical())
				show()
		elif building == null:
			hide()
	._unhandled_input(event)

func get_height():
	return _height

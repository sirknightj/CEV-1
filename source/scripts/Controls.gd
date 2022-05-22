extends Tooltip

var controls_texture = preload("res://assets/images/building-controls.png")
var controls_rotateonly_texture = preload("res://assets/images/building-controls-rotateonly.png")

var _height = 60.0

func _ready():
	add_to_group("preparable")

func prepare():
	GameStats.game.connect("building_grabbed", self, "_on_Game_building_grabbed")
	GameStats.game.connect("building_released", self, "_on_Game_building_released")

func _on_Game_building_grabbed(_building):
	if _building.is_symmetrical():
		$Sprite.texture = controls_rotateonly_texture
		_height = 35.0
	else:
		$Sprite.texture = controls_texture
		_height = 60.0
	show()

func _on_Game_building_released(_building):
	hide()

func _input(event):
	if event is InputEventMouseMotion:
		if Input.get_current_cursor_shape() == Input.CURSOR_CAN_DROP:
			hide()
		elif GameStats.current_selected_building != null:
			show()
	._input(event)

func get_height():
	return _height

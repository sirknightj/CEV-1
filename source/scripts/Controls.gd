extends Node2D

var controls_texture = preload("res://assets/images/building-controls.png")
var controls_rotateonly_texture = preload("res://assets/images/building-controls-rotateonly.png")

func _ready():
	add_to_group("preparable")

func prepare():
	GameStats.game.connect("building_grabbed", self, "_on_Game_building_grabbed")
	GameStats.game.connect("building_released", self, "_on_Game_building_released")

func _on_Game_building_grabbed(_building):
	if GameStats.turn <= 2:
		$Tooltip/Sprite.texture = controls_rotateonly_texture
	else:
		$Tooltip/Sprite.texture = controls_texture
	show()

func _on_Game_building_released(_building):
	hide()

extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

onready var Building = preload("res://Building.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	var building = Building.instance()
	$Grid.add_child(building)
	building.position = Vector2(1000, 500)
	print('Got here!')


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

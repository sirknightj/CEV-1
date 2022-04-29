extends Building
class_name Farm

# Called when the node enters the scene tree for the first time.
func _ready():
	matrix = [true,  true,  true,  true,  false, false, false, false, false, false,
			  true,  true,  true,  false, false, false, false, false, false, false,
			  false, false, false, false, false, false, false, false, false, false]
	init_shape()

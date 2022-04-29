extends Node2D
class_name Building

# A generic building. All buildings will extend this.
# TODO: Restructure the code to make this load from the csv file?

# TODO: Add the building properties
var electricity_cost = 5
var water_effects = 69

# A 2D vector representing the position of this building
var position : Vector2 = Vector2.ZERO

# A 1D boolean array representing a 10x3 grid of the tiles this
# building takes up. true = occupied
# Initially empty. Buildings will override this
var matrix = []

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Hides/unhides the blocks that make up this building
func init_shape():
	var index : int = 0
	for child in get_children():
		child.visible = matrix[index]
		index += 1


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

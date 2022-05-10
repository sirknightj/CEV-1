extends Area2D
class_name GridSquare

const SPRITE_BASE_SIZE = 9

var shape : RectangleShape2D
var is_ghost_square : bool = false

func _ready():
	var owner = create_shape_owner(self)
	shape = RectangleShape2D.new()
	shape_owner_add_shape(owner, shape)

func set_collision_box_size(size : float):
	shape.extents = Vector2(size / 2, size / 2)

func get_adjacent_buildings():
	var buildings : Dictionary = {}
	for area in get_overlapping_areas():
		var parent = area.get_parent().get_parent()
		if (parent != get_parent().get_parent()
				&& (is_equal_approx(area.global_position.x, global_position.x)
					|| is_equal_approx(area.global_position.y, global_position.y))):
			buildings[parent] = true
	return buildings.keys()

func set_color(color : Color):
	set_modulate(color)

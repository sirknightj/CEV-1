extends Area2D
class_name GridSquare

var sprite : Sprite
var shape : RectangleShape2D
var is_ghost_square : bool = false

func _ready():
	var owner = create_shape_owner(self)
	shape = RectangleShape2D.new()
	shape_owner_add_shape(owner, shape)
	sprite = get_node("Sprite")

func set_collision_box_size(size : float):
	shape.extents = Vector2(size / 2, size / 2)

func set_sprite_size(size : float):
	sprite.scale = Vector2(size / 64, size / 64)

func get_adjacent_buildings():
	var buildings : Dictionary = {}
	for area in get_overlapping_areas():
		var parent = area.get_parent()
		if (parent != get_parent()
				&& (is_equal_approx(area.global_position.x, global_position.x)
					|| is_equal_approx(area.global_position.y, global_position.y))):
			buildings[area.get_parent()] = true
	return buildings.keys()

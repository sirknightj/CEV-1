extends Area2D
class_name GridSquare

var collision_box : CollisionShape2D
var sprite : Sprite
var is_shadow_square : bool = false

func _ready():
	collision_box = CollisionShape2D.new()
	add_child(collision_box)
	collision_box.shape = RectangleShape2D.new()
	sprite = get_node("Sprite")

func set_collision_box_size(size : float):
	collision_box.shape.extents = Vector2(size / 2, size / 2)

func set_sprite_size(size : float):
	sprite.scale = Vector2(size / 64, size / 64)

extends Polygon2D

signal hover_on
signal hover_off
signal click

# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"

var item_name: String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass


func _on_BorderRect_mouse_entered() -> void:
	emit_signal("hover_on", item_name)


func _on_BorderRect_mouse_exited() -> void:
	emit_signal("hover_off", item_name)


func _on_BorderRect_gui_input(event: InputEvent) -> void:
	var is_left_click = event is InputEventMouseButton and event.button_index == 1 and not event.pressed
	if not is_left_click:
		return
	emit_signal("click", item_name)

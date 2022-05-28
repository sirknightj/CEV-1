extends Polygon2D

signal hover_on
signal hover_off
signal click

# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"

var item_name: int
var always_animate: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func set_always_animate(val: bool) -> void:
	always_animate = val
	print("[%s] Setting is_rainbow to %s" % [item_name, val])
	$GradientRect.get_material().set_shader_param("is_rainbow", val)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass

func set_gradient_animation(show: bool) -> void:
	if always_animate or show:
		$Tween.interpolate_property($GradientRect.get_material(), "shader_param/progress", 0, 1, 2.1, Tween.TRANS_LINEAR, Tween.EASE_OUT)
		$Tween.start()
		$GradientRect.show()
	else:
		$Tween.stop_all()
		$GradientRect.hide()

func _on_BorderRect_mouse_entered() -> void:
	emit_signal("hover_on", item_name)

func _on_BorderRect_mouse_exited() -> void:
	emit_signal("hover_off", item_name)

func _on_BorderRect_gui_input(event: InputEvent) -> void:
	var is_left_click = event is InputEventMouseButton and event.button_index == 1 and not event.pressed
	if not is_left_click:
		return
	emit_signal("click", item_name)

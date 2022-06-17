extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _on_Continue_gui_input(event):
	if (event is InputEventMouseButton && event.pressed && event.button_index == BUTTON_LEFT):
		# TODO: Log?
		self.hide()
		show_original_button()

func _on_NewGame_gui_input(event):
	if (event is InputEventMouseButton && event.pressed && event.button_index == BUTTON_LEFT):
		# TODO: Log?
		GameStats.dialog_box.prompt("Are you sure you want to start a new game? All current progress will be lost.", "Restart", "Cancel")
		var newGame = yield(GameStats.dialog_box, "answer")
		if newGame:
			GameStats.reset_game(true)
			self.hide()


func _on_SettingsButton_pressed() -> void:
	# TODO - Log this
	.hide()
	show_original_button()

func show_original_button() -> void:
	get_parent().get_parent().get_node("SettingsButton").show()

func _unhandled_input(event : InputEvent):
	if event.is_action_pressed("ui_cancel") and is_visible_in_tree():
		get_tree().set_input_as_handled()
		.hide()
		show_original_button()

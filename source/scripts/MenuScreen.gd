extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _on_Continue_gui_input(event):
	if (event is InputEventMouseButton && event.pressed && event.button_index == BUTTON_LEFT):
		# TODO: Log?
		self.hide()

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

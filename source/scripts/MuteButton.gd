extends Button

func _ready():
	update()

func get_master():
	return AudioServer.get_bus_index("Master")

func update():
	if AudioServer.is_bus_mute(get_master()):
		icon = preload("res://assets/images/mute.png")
	else:
		icon = preload("res://assets/images/unmute.png")

func _on_MuteButton_pressed():
	var new_is_muted = not AudioServer.is_bus_mute(get_master())
	AudioServer.set_bus_mute(get_master(), new_is_muted)
	GameStats.logger.log_level_action(Logger.Actions.AudioMuted if new_is_muted else Logger.Actions.AudioUnmuted)
	update()

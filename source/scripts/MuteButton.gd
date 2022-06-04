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
	AudioServer.set_bus_mute(get_master(), not AudioServer.is_bus_mute(get_master()))
	update()

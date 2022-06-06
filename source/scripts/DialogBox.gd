extends Control
class_name DialogBox

signal answer

func _ready():
	GameStats.dialog_box = self

func prompt(text : String, okText : String, cancelText : String):
	$Panel/MarginContainer/RichTextLabel.text = text
	$Panel/MarginContainer/OkButton/Label.text = okText
	$Panel/MarginContainer/CancelButton/Label.text = cancelText
	show()

func answer(yes : bool):
	emit_signal("answer", yes)
	hide()

func isClick(event : InputEvent):
	return event is InputEventMouseButton && event.pressed && event.button_index == BUTTON_LEFT

func _on_CancelButton_Label_gui_input(event):
	if isClick(event):
		answer(false)

func _on_OkButton_Label_gui_input(event):
	if isClick(event):
		answer(true)

func _unhandled_input(event : InputEvent):
	if event.is_action_pressed("ui_cancel") and is_visible_in_tree():
		get_tree().set_input_as_handled()
		answer(false)

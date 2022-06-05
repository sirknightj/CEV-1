extends PanelContainer

onready var label = $MarginContainer/Label
onready var timer = $Timer
onready var tween = $Tween

const WAIT_BEFORE_SAVED_SECONDS = 1
const WAIT_BEFORE_FADE_SECONDS = 2
const FADE_TWEEN_SECONDS = 2

var current = 1

func begin():
	tween.stop(self)
	timer.stop()
	set_modulate(Color(1, 1, 1, 1))
	label.text = "Autosaving..."
	show()

func wait(seconds):
	timer.set_wait_time(seconds)
	timer.set_one_shot(true)
	timer.start()

func complete():
	current += 1
	var mine = current
	wait(WAIT_BEFORE_SAVED_SECONDS)
	yield(timer, "timeout")
	if mine != current:
		return
	label.text = "Saved."
	wait(WAIT_BEFORE_FADE_SECONDS)
	yield(timer, "timeout")
	if mine != current:
		return
	tween.interpolate_property(self, "modulate",
			Color(1, 1, 1, 1), Color(1, 1, 1, 0), FADE_TWEEN_SECONDS, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()

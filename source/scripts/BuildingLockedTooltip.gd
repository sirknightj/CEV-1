extends Tooltip

onready var control : Control = $Control
onready var panel : PanelContainer = $Control/Panel
onready var label : RichTextLabel = $Control/Panel/Label

var active_building = null

func _ready():
	add_to_group("preparable")

func _on_building_active(building):
	if not building.locked or building.purchased:
		return
	active_building = building
	show_building(building)
	show()

func _on_building_inactive(building):
	if building != active_building:
		return
	hide()

func prepare():
	GameStats.game.connect("building_hovered", self, "_on_building_active")
	GameStats.game.connect("building_hovered_off", self, "_on_building_inactive")

func show_building(building : Building):
	var missing_text : PoolStringArray = PoolStringArray()
	var missing_resources = GameStats.game.sidebar.resources_needed(building.building_id)
	for resource_id in missing_resources:
		missing_text.append("[color=" + GameData.get_resource_color_as_hex(resource_id) + "]" + str(missing_resources[resource_id]) 
							+ " " + GameData.RESOURCE_TYPE_TO_STRING[resource_id] + "[/color]")

	var output_text : String
	if missing_text.empty() or not GameStats.restrictions.empty() or GameStats.turn < 6 or (GameStats.win_status and building.building_id == GameData.BuildingType.END1) or (not GameStats.win_status and not GameStats.is_playing):
		output_text = "Currently\nunavailable"
	else:
		output_text = "Missing:\n\n" + missing_text.join("\n")

	label.bbcode_text = output_text

func get_height() -> float:
	return panel.rect_size.y + control.margin_top

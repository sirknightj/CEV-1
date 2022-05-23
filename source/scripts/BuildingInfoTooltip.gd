extends Tooltip

onready var control : Control = $Control
onready var panel : PanelContainer = control.get_node("Panel")
onready var building_name : RichTextLabel = panel.get_node("VBoxContainer/Name")
onready var production : RichTextLabel = panel.get_node("VBoxContainer/HBoxContainer/Production")
onready var consumption : RichTextLabel = panel.get_node("VBoxContainer/HBoxContainer/Consumption")
onready var upgrades : RichTextLabel = panel.get_node("VBoxContainer/Upgrades")

var active_building = null

func _ready():
	add_to_group("preparable")

func _on_building_changed(building):
	if building != active_building:
		return
	show_building(building)

func _on_building_active(building):
	if not building.purchased:
		return
	active_building = building
	show_building(building)
	show()

func _on_building_inactive(building):
	if building != active_building:
		return
	hide()

func _people():
	return GameStats.resources.get_reserve(GameData.ResourceType.PEOPLE)

func prepare():
	GameStats.game.connect("building_hovered", self, "_on_building_active")
	GameStats.game.connect("building_released", self, "_on_building_active")
	GameStats.game.connect("building_hovered_off", self, "_on_building_inactive")
	GameStats.game.connect("building_grabbed", self, "_on_building_inactive")
	GameStats.game.connect("building_changed", self, "_on_building_changed")

func show_building(building : Building):
	building_name.text = GameStats.buildings_dict[building.building_id].name
	var res = building.get_production_consumption_as_bbcode()
	production.bbcode_text = res[0]
	consumption.bbcode_text = res[1]
	var building_upgrades = building.building_effect_upgrades
	var upgrade_names = []
	for upgrade in building_upgrades:
		upgrade_names.append(upgrade.upgrade_name)
	var has_upgrades = len(building_upgrades) > 0
	if has_upgrades:
		upgrades.text = "Active upgrades: %s" % [GameData.natural_join(upgrade_names)]
		upgrades.show()
	else:
		upgrades.hide()

func get_height() -> float:
	return panel.rect_size.y + control.margin_top

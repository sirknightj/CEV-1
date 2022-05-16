extends Node2D
class_name Game

signal next_turn
signal building_added

# The sidebar object
var sidebar : Control
# The graph object
var graph : Control

onready var building_scene = preload("res://scenes/Building.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	GameStats.game = self
	GameStats.logger.start_new_session(123)
	sidebar = get_node("UILayer/Sidebar")
	graph = get_node("UILayer/Sidebar/Graph")
	for building in get_tree().get_nodes_in_group("buildings"):
		_on_SceneTree_node_added(building)
	get_tree().connect("node_added", self, "_on_SceneTree_node_added")
	get_tree().connect("node_removed", self, "_on_SceneTree_node_removed")
	update_stats()
	show_correct_text()
	GameStats.resources.set_callback(funcref(self, "_on_Resources_changed"))

"""
	Update visualizations
"""
func update_stats():
	sidebar.update_displays()
	var all_resources = aggregate_resources()
	var shown_resources : Dictionary = {}
	for resource in $UILayer/Sidebar.show_resources:
		shown_resources[resource] = all_resources[resource]
	graph.update_graph(GameStats.resources, shown_resources)

"""
	Handles the logic for the next turn
"""
func on_next_turn():
	GameStats.logger.log_level_end({
		"resource_hovers": graph.hover_durations,
	})
	GameStats.resources.step()
	GameStats.turn += 1
	emit_signal("next_turn")
	GameStats.logger.log_level_start(GameStats.turn)
	show_correct_text()

var someone_died : bool = false

func show_correct_text():
	var turn = GameStats.turn
	var text = "" # bbcode
	if turn == 0:
		text = "Welcome to consciousness! You're an AI in charge of a Mars colony of " + str(GameStats.resources.get_reserve(GameData.ResourceType.PEOPLE)) + " colonists.\nClick the \"Next Month\" button to start."
		$UILayer/Sidebar.toggle_upgrades_button(false)
	elif turn == 1:
		text = "Each colonist drinks 1 unit of [color=%s]water[/color] every month.\nPlace down some [color=%s]Wells[/color] to ensure you don't run out of water and your humans stay alive!\nTip: use the \"R\" key to rotate the building." % [GameData.get_resource_color_as_hex(GameData.ResourceType.WATER), GameData.get_resource_color_as_hex(GameData.ResourceType.WATER)]
		$UILayer/Sidebar.toggle_next_month_button(false)
		GameStats.resources.give(GameData.ResourceType.METAL, 12)
		GameStats.restrictions = {GameData.BuildingType.WATER1: 2}
		GameStats.selling_enabled = true
	elif turn == 2:
		text = "Notice how another person has arrived to your colony.\nYou now need another [color=%s]Well[/color] to support your growing population." % GameData.get_resource_color_as_hex(GameData.ResourceType.WATER)
		$UILayer/Sidebar.toggle_next_month_button(false)
		GameStats.resources.give(GameData.ResourceType.METAL, 6)
		GameStats.restrictions = {GameData.BuildingType.WATER1: 1}
	elif turn == 3:
		text = "Feed the humans!\nIn addition to water, each colonist also consumes 2 units of [color=%s]food[/color] per month.\nTip: Use the \"T\" key to flip a building." % GameData.get_resource_color_as_hex(GameData.ResourceType.FOOD)
		$UILayer/Sidebar.toggle_next_month_button(false)
		GameStats.resources.give(GameData.ResourceType.METAL, 40)
		GameStats.restrictions = {GameData.BuildingType.FOOD1: 2}
	elif turn == 4:
		text = "Keep expanding your colony. And keep your people alive!"
	elif turn == 5:
		$UILayer/Sidebar.toggle_next_month_button(false)
		GameStats.resources.give(GameData.ResourceType.METAL, 26)
		GameStats.restrictions = {GameData.BuildingType.WATER1: 1, GameData.BuildingType.FOOD1: 1}
	elif turn == 6:
		text = "Humans consume 1 [color=%s]oxygen[/color] unit per month. Make sure you have enough or they'll suffocate!\nYour colony will also need [color=%s]metal[/color] to construct more buildings." % [GameData.get_resource_color_as_hex(GameData.ResourceType.OXYGEN), GameData.get_resource_color_as_hex(GameData.ResourceType.METAL)]
		$UILayer/Sidebar.toggle_next_month_button(false)
		GameStats.resources.give(GameData.ResourceType.METAL, 146)
		GameStats.restrictions = {GameData.BuildingType.WATER1: 1, GameData.BuildingType.METAL1: 1, GameData.BuildingType.OXY1: 1}
	elif turn == 7:
		text = "Tip: You can also move the buildings around!"
	elif turn == 8:
		text = "If " + str(GameStats.colonist_death_threshold) + " colonists die, you'll be shut down. Make sure that doesn't happen!"
	elif turn == 9:
		text = "Your mine needs [color=%s]energy[/color] to function.\nBuild some [color=%s]Solar Panel[/color]s." % [GameData.get_resource_color_as_hex(GameData.ResourceType.ELECTRICITY), GameData.get_resource_color_as_hex(GameData.ResourceType.ELECTRICITY)]
		$UILayer/Sidebar.toggle_next_month_button(false)
		GameStats.resources.give(GameData.ResourceType.METAL, 24)
		GameStats.restrictions = {GameData.BuildingType.ELEC1: 3}
	elif turn == 10:
		text = "Your city has generated enough [color=%s]science[/color] for an upgrade! Spend your science points to unlock new building types and expand your colony." % GameData.get_resource_color_as_hex(GameData.ResourceType.SCIENCE)
		$UILayer/Sidebar.toggle_next_month_button(false)
		$UILayer/Sidebar.toggle_upgrades_button(true)
	elif turn == 11:
		text = "You should aim to get a [color=%s]University[/color] down to speed up your research progress!" % GameData.get_resource_color_as_hex(GameData.ResourceType.SCIENCE)
	elif turn == 12:
		text = "Your goal is to place down the Cryonic Chamber while minimizing colonist deaths. Note that you receive a refund if you destroy a building on the same turn you build it!"
	else:
		if someone_died:
			# TODO: explain what they died from (food -> starvation, water -> dehydration, oxygen -> suffocation)
			text = "Oh no! Some colonists died due to lack of resources. Only " + str(GameStats.colonist_death_threshold - GameStats.dead) + " more colonist deaths will be tolerated before you get shut down!"
			someone_died = false
		else:
			text = ""
	$UILayer/TextBox.bbcode_text = text
	_on_Resources_changed()

"""
	Place the building at the grid square (_x, _y).
"""
func place_building(_x: int, _y: int) -> void:
	var key = GameStats.buildings_dict.keys()[randi() % (GameStats.buildings_dict.size() - 1) + 1]
	var building_stats = GameStats.buildings_dict[key]
	var building = building_scene.instance()
	building.shape = building_stats.shape
	building.building_effects = building_stats.effects
	building.building_cost = building_stats.cost
	building.building_id = key
	building.texture = GameData.BUILDING_TO_TEXTURE[key]
	add_child(building)
	building.set_next_pos(building.snapped(Vector2(_x, _y)))

func update_resources() -> void:
	var cb = GameStats.resources.get_callback()
	GameStats.resources.set_callback(null)

	GameStats.resources.reset_income_expense()
	for building in get_tree().get_nodes_in_group("buildings"):
		for resource in GameData.ResourceType.values():
			GameStats.resources.add_effect(resource, building.get_effect(resource))
	# Handle colonists dying
	var dead_colonists : int = 0
	# TODO: account for upgrades changing people's resource consumption
	for resource in GameData.PEOPLE_RESOURCE_CONSUMPTION:
		if GameStats.resources.get_reserve(resource) < 0:
			var colonists_unsupported : int = -floor(GameStats.resources.get_reserve(resource) / GameData.PEOPLE_RESOURCE_CONSUMPTION[resource])
			if dead_colonists < colonists_unsupported:
				dead_colonists = colonists_unsupported
	if dead_colonists:
		GameStats.resources.consume(GameData.ResourceType.PEOPLE, dead_colonists)
		GameStats.dead += dead_colonists
		for resource in GameData.PEOPLE_RESOURCE_CONSUMPTION:
			GameStats.resources.give(resource, GameData.PEOPLE_RESOURCE_CONSUMPTION[resource] * dead_colonists)
		someone_died = true
		print(str(dead_colonists) + " people died!")

	GameStats.resources.set_callback(cb)

func aggregate_resources() -> Dictionary:
	var dict : Dictionary = {}
	for building in get_tree().get_nodes_in_group("buildings"):
		for resource in GameData.ResourceType.values():
			if not dict.has(resource):
				dict[resource] = {}
			if not dict[resource].has(building.building_id):
				dict[resource][building.building_id] = 0
			dict[resource][building.building_id] += building.get_effect(resource)
	return dict

func _unhandled_input(event):
	if event.is_action_pressed("toggle_fullscreen"):
		OS.window_fullscreen = !OS.window_fullscreen

func _on_Resources_changed():
	update_resources()
	sidebar.update_displays()
	update_stats()
	sidebar.check_buttons()

func _on_Building_hover(building):
	graph.on_building_hover(building)

func _on_Building_hover_off(building):
	graph.on_building_hover_off(building)

func _on_SceneTree_node_removed(_node):
	if _node is Building:
		_on_Resources_changed()

func _on_SceneTree_node_added(_node):
	if (not _node.is_in_group("buildings")
			or _node.is_in_group("tracked")):
		return
	_node.add_to_group("tracked")
	_node.connect("building_changed", self, "_on_Resources_changed")
	_node.connect("building_hovered", self, "_on_Building_hover")
	_node.connect("building_hovered_off", self, "_on_Building_hover_off")
	emit_signal("building_added", _node)

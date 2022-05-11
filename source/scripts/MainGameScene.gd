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

func show_correct_text():
	var turn = GameStats.turn
	if turn == 0:
		$UILayer/TextBox.text = "Welcome! You're in charge of a Mars colony of 50 colonists.\nClick the \"Next Month\" button to start."
		$UILayer/Sidebar.toggle_upgrades_button(false)
	elif turn == 1:
		$UILayer/TextBox.text = "Each colonist consumes 1 water/month.\nPlace down some wells to ensure you don't run out of water!\nTip: use R to rotate the building."
		$UILayer/Sidebar.toggle_next_month_button(false)
		GameStats.resources.give(GameData.ResourceType.METAL, 12)
		GameStats.restrictions = {GameData.BuildingType.WATER1: 2}
	elif turn == 2:
		$UILayer/TextBox.text = "Notice how another person has arrived to your colony.\nYou now need another well to support your growing population."
		$UILayer/Sidebar.toggle_next_month_button(false)
		GameStats.resources.give(GameData.ResourceType.METAL, 6)
		GameStats.restrictions = {GameData.BuildingType.WATER1: 1}
	elif turn == 3:
		$UILayer/TextBox.text = "Each colonists also consumes 2 food/month.\nFEED THE HUMANS\nYou can also use T to flip the building!"
		$UILayer/Sidebar.toggle_next_month_button(false)
		GameStats.resources.give(GameData.ResourceType.METAL, 40)
		GameStats.restrictions = {GameData.BuildingType.FOOD1: 2}
	elif turn == 4:
		$UILayer/TextBox.text = "Keep expanding your colony! And keep your people alive!"
	elif turn == 5:
		$UILayer/Sidebar.toggle_next_month_button(false)
		GameStats.resources.give(GameData.ResourceType.METAL, 26)
		GameStats.restrictions = {GameData.BuildingType.WATER1: 1, GameData.BuildingType.FOOD1: 1}
	elif turn == 6:
		$UILayer/TextBox.text = "Humans consume 1 oxygen/mo.\nMake sure you have enough!\nYour colony will need metal to building more buildings."
		$UILayer/Sidebar.toggle_next_month_button(false)
		GameStats.resources.give(GameData.ResourceType.METAL, 146)
		GameStats.restrictions = {GameData.BuildingType.WATER1: 1, GameData.BuildingType.METAL1: 1, GameData.BuildingType.OXY1: 1}
	elif turn == 7:
		$UILayer/TextBox.text = "You can also move the buildings around!"
	elif turn == 9:
		$UILayer/TextBox.text = "Your mine needs energy to function.\nPlace down some solar panels."
		$UILayer/Sidebar.toggle_next_month_button(false)
		GameStats.resources.give(GameData.ResourceType.METAL, 24)
		GameStats.restrictions = {GameData.BuildingType.ELEC1: 3}
	elif turn == 10:
		$UILayer/TextBox.text = "Your city center has generated enough science for an upgrade! Spend your science points to unlock new building types and expand your colony!"
		$UILayer/Sidebar.toggle_upgrades_button(true)
	elif turn == 11:
		$UILayer/TextBox.text = "You should aim to get a University down to speed up your research progress!"
	elif turn == 12:
		$UILayer/TextBox.text = "Your goal is to place down the Cryonic Chamber while minimizing colonist deaths."
	else:
		$UILayer/TextBox.text = ""
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
			var colonists_unsupported : int = -ceil(GameStats.resources.get_reserve(resource) / GameData.PEOPLE_RESOURCE_CONSUMPTION[resource])
			if dead_colonists < colonists_unsupported:
				dead_colonists = colonists_unsupported
	if dead_colonists:
		GameStats.resources.consume(GameData.ResourceType.PEOPLE, dead_colonists)
		GameStats.dead += dead_colonists
		for resource in GameData.PEOPLE_RESOURCE_CONSUMPTION:
			GameStats.resources.give(resource, GameData.PEOPLE_RESOURCE_CONSUMPTION[resource] * dead_colonists)
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

func _on_Resources_changed():
	update_resources()
	sidebar.update_displays()
	update_stats()

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

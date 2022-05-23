extends Node2D
class_name Game

signal next_turn
signal building_added(building)
signal building_grabbed(building)
signal building_released(building)
signal building_hovered(building)
signal building_hovered_off(building)
signal building_changed(building)

# The sidebar object
var sidebar : Control
# The graph object
var graph : Control

onready var building_scene = preload("res://scenes/Building.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	GameStats.game = self
	GameStats.logger.start_new_session(124)
	sidebar = get_node("UILayer/Sidebar")
	graph = get_node("UILayer/Sidebar/Graph")
	for building in get_tree().get_nodes_in_group("buildings"):
		_on_SceneTree_node_added(building)
	get_tree().connect("node_added", self, "_on_SceneTree_node_added")
	get_tree().connect("node_removed", self, "_on_SceneTree_node_removed")
	GameStats.resources.set_callback(funcref(self, "update_all"))
	"""
		SAVED GAME DEBUGGING
		DISABLE IN PRODUCTION
	"""
	#if not GameStats.load_game():
	#	sidebar.start_game()
	"""
	"""
	sidebar.get_node("CanvasLayer/TechTree").add_nodes()
	get_tree().call_group("preparable", "prepare")
	update_stats()
	show_correct_text()
	sidebar.start_game()

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
		"game": GameStats.serialize()
	})
	GameStats.resources.step()
	GameStats.turn += 1
	emit_signal("next_turn")
	"""
		SAVED GAME DEBUGGING
		DISABLE IN PRODUCTION
	"""
	#GameStats.save_game()
	"""
	"""
	GameStats.logger.log_level_start(GameStats.turn)
	show_correct_text()
	if GameStats.turn == 6 or GameStats.turn == 9 or GameStats.turn == 11:
		$UILayer/Sidebar.scroll_down()

var num_died : int = 0
var death_reasons : Array = []

func show_correct_text():
	var turn = GameStats.turn
	var text = "" # bbcode
	if turn == 0:
		text = "Welcome to consciousness! You're an AI put in charge of a Mars colony of " + str(GameStats.resources.get_reserve(GameData.ResourceType.PEOPLE)) + ".\nYour objective: keep the humans alive. \nClick the \"Next Month\" button to start."
		$UILayer/Sidebar.toggle_upgrades_button(false)
	elif turn == 1:
		text = "Welcome to consciousness! You're an AI put in charge of a Mars colony of " + str(GameStats.resources.get_reserve(GameData.ResourceType.PEOPLE)) + ".\n"
		text += "Each colonist needs 1 unit of [color=%s]water[/color].\nPlace down a %s to generate some [color=%s]water[/color]!" % [GameData.get_resource_color_as_hex(GameData.ResourceType.WATER), GameStats.buildings_dict[GameData.BuildingType.WATER1].format_str(1), GameData.get_resource_color_as_hex(GameData.ResourceType.WATER)]
		$UILayer/Sidebar.toggle_next_month_button(false)
		GameStats.resources.give(GameData.ResourceType.METAL, 6)
		GameStats.restrictions = {GameData.BuildingType.WATER1: 1}
		GameStats.selling_enabled = true
	elif turn == 2:
		text = "More colonists have arrived!\nYou'll need another %s to support the growing population." % GameStats.buildings_dict[GameData.BuildingType.WATER1].format_str(1)
		# $UILayer/Sidebar.toggle_next_month_button(false)
		GameStats.resources.give(GameData.ResourceType.METAL, 6)
		# GameStats.restrictions = {GameData.BuildingType.WATER1: 1}
	elif turn == 3:
		text = "Feed the humans!\nIn addition to [color=%s]water[/color], each colonist also consumes 2 units of [color=%s]food[/color] per month.\n" % [GameData.get_resource_color_as_hex(GameData.ResourceType.WATER), GameData.get_resource_color_as_hex(GameData.ResourceType.FOOD)]
		$UILayer/Sidebar.toggle_next_month_button(false)
		GameStats.resources.give(GameData.ResourceType.METAL, 40)
		GameStats.restrictions = {GameData.BuildingType.FOOD1: 2}
	elif turn == 4:
		text = "Time passes..."
		GameStats.resources.give(GameData.ResourceType.METAL, 6)
	elif turn == 5:
		text = "Your colony continues to grow. Make sure that everyone has enough resources to survive!"
		# $UILayer/Sidebar.toggle_next_month_button(false)
		GameStats.resources.give(GameData.ResourceType.METAL, 26)
		# GameStats.restrictions = {GameData.BuildingType.WATER1: 1, GameData.BuildingType.FOOD1: 1}
	elif turn == 6:
		text = "Humans consume 1 [color=%s]oxygen[/color] unit per month. Make sure you have enough or they'll suffocate!\nYour colony will also need [color=%s]metal[/color] to construct more buildings." % [GameData.get_resource_color_as_hex(GameData.ResourceType.OXYGEN), GameData.get_resource_color_as_hex(GameData.ResourceType.METAL)]
		$UILayer/Sidebar.toggle_next_month_button(false)
		GameStats.resources.give(GameData.ResourceType.METAL, 146)
		GameStats.restrictions = {GameData.BuildingType.METAL1: 1, GameData.BuildingType.OXY1: 1}
		# GameStats.restrictions = {GameData.BuildingType.WATER1: 1, GameData.BuildingType.METAL1: 1, GameData.BuildingType.OXY1: 1}
	elif turn == 7:
		text = "Tip: You can also re-arrange any placed buildings for free."
	elif turn == 8:
		text = "If " + str(GameStats.colonist_death_threshold) + " colonists die, you'll be shut down. Make sure that doesn't happen!"
	elif turn == 9:
		text = "Some buildings need [color=%s]energy[/color] to function.\nBuild %s before you run out!" % [GameData.get_resource_color_as_hex(GameData.ResourceType.ELECTRICITY), GameStats.buildings_dict[GameData.BuildingType.ELEC1].format_str(2)]
		# $UILayer/Sidebar.toggle_next_month_button(false)
		GameStats.resources.give(GameData.ResourceType.METAL, 24)
		# GameStats.restrictions = {GameData.BuildingType.ELEC1: 3}
	elif turn == 10:
		text = "Your city has generated enough [color=%s]science[/color] for an upgrade! Spend [color=%s]science[/color] to unlock new buildings and increase building efficiency." % [GameData.get_resource_color_as_hex(GameData.ResourceType.SCIENCE), GameData.get_resource_color_as_hex(GameData.ResourceType.SCIENCE)]
		$UILayer/Sidebar.toggle_next_month_button(false)
		$UILayer/Sidebar.toggle_upgrades_button(true)
	elif turn == 11:
		text = "Building a %s will significantly speed up your research progress." % GameStats.buildings_dict[GameData.BuildingType.SCI1].format_str(1)
	elif turn == 12:
		text = "Your goal is to place down the [color=#FFFFFF]Cryonic Chamber[/color] while minimizing colonist deaths."
	elif turn == 13:
		if GameStats.show_sell_no_refund_message and GameStats.show_sell_yes_refund_message:
			# Basically, the player hasn't tried selling yet.
			text = "Tip: You can demolish a building by dragging it off the grid."
		else:
			text = ""
	else:
		if GameStats.just_won == 1:
			text = "A meteor crashes into the Cryonic Chamber and the colonists wake up from their slumber. You insist on building another one but the colonists refuse. They want their freedom."
		elif GameStats.just_won == 2:
			text = "Your objective function remains the same: keep the humans alive for as long as possible."
		else:
			text = ""
		if GameStats.just_won:
			GameStats.just_won += 1
	if num_died:
			var deaths_left = GameStats.colonist_death_threshold - GameStats.dead
			var plural_colonists = "colonist" if num_died == 1 else "colonists"
			plural_colonists = str(num_died) + " " + plural_colonists
			text += ("\nOh no! %s died from %s." % [plural_colonists, format_death_reasons_as_bbcode(death_reasons)])
			if deaths_left > 0:
				var plural_deaths = "death" if deaths_left == 1 else "deaths"
				text += (" " if text else "")
				text += "Only %s more %s will be tolerated before you get shut down!" % [deaths_left, plural_deaths]
			num_died = 0
			death_reasons = []
	$UpperLayer/TutorialText.bbcode_text = text.strip_edges()
	update_all()

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
	# death_reasons = []
	# TODO: account for upgrades changing people's resource consumption
	for resource in GameData.PEOPLE_RESOURCE_CONSUMPTION:
		if GameStats.resources.get_reserve(resource) < 0:
			var colonists_unsupported : int = -floor(GameStats.resources.get_reserve(resource) / GameData.PEOPLE_RESOURCE_CONSUMPTION[resource])
			if colonists_unsupported > 0:
				death_reasons.append(resource)
				if dead_colonists < colonists_unsupported:
					dead_colonists = colonists_unsupported
	if dead_colonists:
		GameStats.resources.consume(GameData.ResourceType.PEOPLE, dead_colonists)
		GameStats.dead += dead_colonists
		for resource in GameData.PEOPLE_RESOURCE_CONSUMPTION:
			GameStats.resources.give(resource, GameData.PEOPLE_RESOURCE_CONSUMPTION[resource] * dead_colonists)
		num_died = dead_colonists
		print(str(dead_colonists) + " people died!")

	GameStats.resources.set_callback(cb)

func format_death_reasons_as_bbcode(reasons: Array) -> String:
	var res = ""
	for resource_type in reasons:
		assert(GameData.is_resource_type(resource_type))
		var death = "lack of resources"
		if resource_type == GameData.ResourceType.FOOD:
			death = "starvation"
		elif resource_type == GameData.ResourceType.WATER:
			death = "dehydration"
		elif resource_type == GameData.ResourceType.OXYGEN:
			death = "suffocation"
		var color = GameData.get_resource_color_as_hex(resource_type)
		res += "[color=%s]%s[/color] and " % [color, death]
	res.erase(res.length() - 5, 5)
	return res

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

func update_all():
	update_resources()
	update_stats()
	sidebar.check_buttons()

func _on_Building_building_changed(building):
	update_all()
	emit_signal("building_changed", building)

func _on_Building_building_hovered(building):
	emit_signal("building_hovered", building)

func _on_Building_building_hovered_off(building):
	emit_signal("building_hovered_off", building)

func _on_Building_building_grabbed(building):
	emit_signal("building_grabbed", building)

func _on_Building_building_released(building):
	emit_signal("building_released", building)

func _on_SceneTree_node_removed(_node):
	if _node is Building:
		_on_Building_building_changed(_node)

func _on_Building_ready(building):
	building.add_to_group("tracked")
	building.connect("building_changed", self, "_on_Building_building_changed")
	building.connect("building_hovered", self, "_on_Building_building_hovered")
	building.connect("building_hovered_off", self, "_on_Building_building_hovered_off")
	building.connect("building_grabbed", self, "_on_Building_building_grabbed")
	building.connect("building_released", self, "_on_Building_building_released")
	emit_signal("building_added", building)

func _on_SceneTree_node_added(_node):
	if (_node.is_in_group("buildings")):
		if not _node.is_in_group("tracked"):
			_on_Building_ready(_node)
		return
	if _node is Building:
		_node.connect("ready", self, "_on_Building_ready", [_node])

func get_buildings():
	return get_tree().get_nodes_in_group("tracked")

extends Node2D
class_name Game

signal next_turn

# The sidebar object
var sidebar : Control
# The graph object
var graph : Control

onready var building_scene = preload("res://scenes/Building.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	sidebar = get_node("UILayer/Sidebar")
	graph = get_node("UILayer/Sidebar/Graph")
	get_tree().connect("node_added", self, "_on_SceneTree_node_added")
	update_stats()

"""
	Update visualizations
"""
func update_stats():
	sidebar.update_displays()
	graph.update_graph(GameStats.resources, aggregate_resources())

"""
	Handles the logic for the next turn
"""
func on_next_turn():
	update_resources()
	GameStats.resources.step()
	GameStats.turn += 1
	emit_signal("next_turn")
	update_stats()

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
	GameStats.resources.reset_income_expense()
	for building in get_tree().get_nodes_in_group("buildings"):
		for resource in GameData.ResourceType.values():
			GameStats.resources.add_effect(resource, building.get_effect(resource))
	# Handle colonists dying
	var dead_colonists : int = 0
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

func _on_Building_ready():
	update_resources()
	sidebar.update_displays()
	update_stats()

func _on_SceneTree_node_added(_node):
	if (!(_node is Building)):
		return
	_node.connect("ready", self, "_on_Building_ready")

extends Node2D
class_name Game

signal next_turn

class BuildingStats:
	var shape : Array
	var name : String
	var effects : Dictionary
	var cost : Dictionary

	func _init():
		effects = {}
		cost = {}

var resources : GameObjs.Resources

var _initial_reserves = {
	GameData.ResourceType.FOOD: 100.0,
	GameData.ResourceType.OXYGEN: 100.0,
	GameData.ResourceType.WATER: 55.0,
	GameData.ResourceType.METAL: 60.0,
	GameData.ResourceType.ELECTRICITY: 50.0,
	GameData.ResourceType.SCIENCE: 0.0,
	GameData.ResourceType.PEOPLE: 25.0
}

# The sidebar object
var sidebar : Control

onready var building_scene = preload("res://scenes/Building.tscn")
# File path of buildings.json
var buildings_json = "res://assets/data/buildings.json"
# building_id -> BuildingStats
var buildings_dict : Dictionary = {}

var turn : int = 0 # the current turn
var _turn_count_text # the text holder object that displays "Turn: 69"

func _init():
	load_buildings_json()

# Called when the node enters the scene tree for the first time.
func _ready():
	sidebar = get_node("Sidebar")
	resources = GameObjs.Resources.new()
	resources.set_reserves(_initial_reserves)
	get_tree().connect("node_added", self, "_on_SceneTree_node_added")

"""
	Reads the building data from assets/data/buildings.json and loads it into
	the buildings_dict, which maps building_name -> building
"""
func load_buildings_json() -> void:
	var file = File.new()
	assert(file.file_exists(buildings_json))
	file.open(buildings_json, File.READ)
	var data = parse_json(file.get_as_text())
	for building in data:
		assert(not building.name == null)
		var building_type : int = GameData.BuildingType[building.id.to_upper()]
		var stats = BuildingStats.new()
		stats.name = building.name
		stats.shape = building.shape
		for resource in GameData.ResourceType.keys():
			var resource_type = GameData.ResourceType[resource]
			if resource_type == GameData.ResourceType.PEOPLE:
				stats.effects[resource_type] = 0
				stats.cost[resource_type] = 0
				continue
			stats.cost[resource_type] = building[resource.to_lower() + "_cost"]
			stats.effects[resource_type] = building[resource.to_lower() + "_effect"]
		buildings_dict[building_type] = stats
	print("Loaded the buildings: " + str(buildings_dict.keys()))
	file.close()

"""
	Handles the logic for the next turn
"""
func on_next_turn():
	update_resources()
	resources.step()
	turn += 1
	emit_signal("next_turn")
	sidebar.update_displays()

"""
	Place the building at the grid square (_x, _y).
"""
func place_building(_x: int, _y: int) -> void:
	var key = buildings_dict.keys()[randi() % buildings_dict.size()]
	var building_stats = buildings_dict[key]
	var building = building_scene.instance()
	building.shape = building_stats.shape
	building.building_effects = building_stats.effects
	building.building_cost = building_stats.cost
	building.building_id = key
	add_child(building)
	building.set_position(building.snapped(Vector2(_x, _y)))

func update_resources() -> void:
	resources.reset_income_expense()
	for building in get_tree().get_nodes_in_group("buildings"):
		for resource in GameData.ResourceType.values():
			resources.add_effect(resource, building.get_effect(resource))

func aggregate_resources() -> Dictionary:
	var dict : Dictionary = {}
	for building in get_tree().get_nodes_in_group("buildings"):
		for resource in GameData.ResourceType.values():
			if not dict.has(resource):
				dict[resource] = {}
			dict[resource][building.building_id] = building.get_effect(resource)
	return dict

func _on_Building_ready():
	update_resources()
	sidebar.update_displays()

func _on_SceneTree_node_added(_node):
	if (!(_node is Building)):
		return
	_node.connect("ready", self, "_on_Building_ready")

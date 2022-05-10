extends Node
# This class holds all of the game data. This singleton object's namespace
# is globally registered, meaning you do not need to import it.
# You can call any method in this class by doing GameStats.method_name()
# And also access any variable in this class by doing GameStats.var_name

var resources : GameObjs.Resources
var upgrade_tree : GameObjs.UpgradeTree
var grid : Grid
var game : Game

var logger : Logger.Log

"""
	Each upgrade object defines its individual properties and mechanics

	This map loads the upgrades, assigns labels to them, and describes the
	_relationships_ between them
"""
var upgrades_data = {
	GameData.UpgradeType.UNLOCK_WATER1: {
		"scene": preload("res://scenes/upgrades/impl/UnlockWater1.tscn"),
		"position": Vector2(9.1, 2.1),
		"prereqs": [],
		"starting": true
	},
	GameData.UpgradeType.UNLOCK_WATER2: {
		"scene": preload("res://scenes/upgrades/impl/UnlockWater2.tscn"),
		"position": Vector2(7.7, 6.3),
		"prereqs": [GameData.UpgradeType.IMPROVE_FARM1],
		"starting": false
	},
	GameData.UpgradeType.UNLOCK_WATER3: {
		"scene": preload("res://scenes/upgrades/impl/UnlockWater3.tscn"),
		"position": Vector2(9.1, 6.3),
		"prereqs": [GameData.UpgradeType.IMPROVE_MINE1],
		"starting": false
	},
	GameData.UpgradeType.UNLOCK_FOOD1: {
		"scene": preload("res://scenes/upgrades/impl/UnlockFood1.tscn"),
		"position": Vector2(7.7, 3.5),
		"prereqs": [GameData.UpgradeType.UNLOCK_WATER1],
		"starting": true
	},
	GameData.UpgradeType.UNLOCK_FOOD2: {
		"scene": preload("res://scenes/upgrades/impl/UnlockFood2.tscn"),
		"position": Vector2(4.9, 6.3),
		"prereqs": [GameData.UpgradeType.ASTRO],
		"starting": false
	},
	GameData.UpgradeType.UNLOCK_FOOD3: {
		"scene": preload("res://scenes/upgrades/impl/UnlockFood3.tscn"),
		"position": Vector2(4.9, 7.7),
		"prereqs": [GameData.UpgradeType.UNLOCK_FOOD2],
		"starting": false
	},
	GameData.UpgradeType.UNLOCK_OXY1: {
		"scene": preload("res://scenes/upgrades/impl/UnlockOxy1.tscn"),
		"position": Vector2(2.1, 2.1),
		"prereqs": [GameData.UpgradeType.UNLOCK_ELEC1],
		"starting": true
	},
	GameData.UpgradeType.UNLOCK_OXY2: {
		"scene": preload("res://scenes/upgrades/impl/UnlockOxy2.tscn"),
		"position": Vector2(2.1, 3.5),
		"prereqs": [GameData.UpgradeType.UNLOCK_OXY1, GameData.UpgradeType.IMPROVE_ELEC1],
		"starting": false
	},
	GameData.UpgradeType.UNLOCK_OXY3: {
		"scene": preload("res://scenes/upgrades/impl/UnlockOxy3.tscn"),
		"position": Vector2(2.1, 4.9),
		"prereqs": [GameData.UpgradeType.UNLOCK_OXY2],
		"starting": false
	},
	GameData.UpgradeType.UNLOCK_ELEC1: {
		"scene": preload("res://scenes/upgrades/impl/UnlockElec1.tscn"),
		"position": Vector2(0.7, 0.7),
		"prereqs": [],
		"starting": true
	},
	GameData.UpgradeType.UNLOCK_ELEC2: {
		"scene": preload("res://scenes/upgrades/impl/UnlockElec2.tscn"),
		"position": Vector2(0.7, 3.5),
		"prereqs": [GameData.UpgradeType.IMPROVE_ELEC1],
		"starting": false
	},
	GameData.UpgradeType.UNLOCK_ELEC3: {
		"scene": preload("res://scenes/upgrades/impl/UnlockElec3.tscn"),
		"position": Vector2(0.7, 4.9),
		"prereqs": [GameData.UpgradeType.UNLOCK_ELEC2],
		"starting": false
	},
	GameData.UpgradeType.UNLOCK_SCI1: {
		"scene": preload("res://scenes/upgrades/impl/UnlockSci1.tscn"),
		"position": Vector2(4.9, 2.1),
		"prereqs": [],
		"starting": true
	},
	GameData.UpgradeType.UNLOCK_SCI2: {
		"scene": preload("res://scenes/upgrades/impl/UnlockSci2.tscn"),
		"position": Vector2(4.9, 3.5),
		"prereqs": [GameData.UpgradeType.UNLOCK_SCI1],
		"starting": false
	},
	GameData.UpgradeType.UNLOCK_METAL1: {
		"scene": preload("res://scenes/upgrades/impl/UnlockMetal1.tscn"),
		"position": Vector2(9.1, 3.5),
		"prereqs": [GameData.UpgradeType.UNLOCK_WATER1],
		"starting": true
	},
	GameData.UpgradeType.UNLOCK_END1: {
		"scene": preload("res://scenes/upgrades/impl/UnlockEnd1.tscn"),
		"position": Vector2(9.1, 9.1),
		"prereqs": [GameData.UpgradeType.IMPROVE_PEOPLE2, GameData.UpgradeType.UNLOCK_WATER3],
		"starting": false
	},
	GameData.UpgradeType.GRID_1: {
		"scene": preload("res://scenes/upgrades/impl/Grid1.tscn"),
		"position": Vector2(3.5, 3.5),
		"prereqs": [],
		"starting": true
	},
	GameData.UpgradeType.GRID_2: {
		"scene": preload("res://scenes/upgrades/impl/Grid2.tscn"),
		"position": Vector2(3.5, 4.9),
		"prereqs": [GameData.UpgradeType.GRID_1, GameData.UpgradeType.UNLOCK_OXY2],
		"starting": false
	},
	GameData.UpgradeType.GRID_3: {
		"scene": preload("res://scenes/upgrades/impl/Grid3.tscn"),
		"position": Vector2(3.5, 6.3),
		"prereqs": [GameData.UpgradeType.GRID_2, GameData.UpgradeType.ASTRO],
		"starting": false
	},
	GameData.UpgradeType.GRID_4: {
		"scene": preload("res://scenes/upgrades/impl/Grid4.tscn"),
		"position": Vector2(3.5, 7.7),
		"prereqs": [GameData.UpgradeType.GRID_3],
		"starting": false
	},
	GameData.UpgradeType.IMPROVE_MINE1: {
		"scene": preload("res://scenes/upgrades/impl/ImproveMine1.tscn"),
		"position": Vector2(9.1, 4.9),
		"prereqs": [GameData.UpgradeType.UNLOCK_METAL1],
		"starting": false
	},
	GameData.UpgradeType.IMPROVE_ELEC1: {
		"scene": preload("res://scenes/upgrades/impl/ImproveElec1.tscn"),
		"position": Vector2(0.7, 2.1),
		"prereqs": [GameData.UpgradeType.UNLOCK_ELEC1],
		"starting": false
	},
	GameData.UpgradeType.IMPROVE_FARM1: {
		"scene": preload("res://scenes/upgrades/impl/ImproveFarm1.tscn"),
		"position": Vector2(7.7, 4.9),
		"prereqs": [GameData.UpgradeType.UNLOCK_FOOD1],
		"starting": false
	},
	GameData.UpgradeType.IMPROVE_FARM2: {
		"scene": preload("res://scenes/upgrades/impl/ImproveFarm2.tscn"),
		"position": Vector2(6.3, 6.3),
		"prereqs": [GameData.UpgradeType.ASTRO],
		"starting": false
	},
	GameData.UpgradeType.ASTRO: {
		"scene": preload("res://scenes/upgrades/impl/Astro.tscn"),
		"position": Vector2(4.9, 4.9),
		"prereqs": [GameData.UpgradeType.UNLOCK_FOOD1, GameData.UpgradeType.UNLOCK_SCI2],
		"starting": false
	},
	GameData.UpgradeType.IMPROVE_PEOPLE1: {
		"scene": preload("res://scenes/upgrades/impl/ImprovePeople1.tscn"),
		"position": Vector2(6.3, 7.7),
		"prereqs": [GameData.UpgradeType.IMPROVE_FARM2],
		"starting": false
	},
	GameData.UpgradeType.IMPROVE_PEOPLE2: {
		"scene": preload("res://scenes/upgrades/impl/ImprovePeople2.tscn"),
		"position": Vector2(7.7, 7.7),
		"prereqs": [GameData.UpgradeType.IMPROVE_FARM2],
		"starting": false
	}
}

# Array of building IDs that are unlocked
var buildings_unlocked : Array = []
var buildings_owned : Dictionary = {}
var restrictions : Dictionary = {}

var grid_size : int # the number of squares the grid is at the moment

var turn : int # The current month
var dead : int # The number of dead colonists

"""var _initial_reserves = {
	GameData.ResourceType.FOOD: 100.0,
	GameData.ResourceType.OXYGEN: 100.0,
	GameData.ResourceType.WATER: 55.0,
	GameData.ResourceType.METAL: 60.0,
	GameData.ResourceType.ELECTRICITY: 50.0,
	GameData.ResourceType.SCIENCE: 0.0,
	GameData.ResourceType.PEOPLE: 25.0
}"""

var _initial_reserves = {
	GameData.ResourceType.FOOD: 550.0,
	GameData.ResourceType.OXYGEN: 950.0,
	GameData.ResourceType.WATER: 25.0,
	GameData.ResourceType.METAL: 0.0,
	GameData.ResourceType.ELECTRICITY: 80.0,
	GameData.ResourceType.SCIENCE: 0.0,
	GameData.ResourceType.PEOPLE: 20.0
}

var current_selected_building : Building = null

class BuildingStats:
	var shape : Array
	var name : String
	var effects : Dictionary
	var cost : Dictionary

	func _init():
		effects = {}
		cost = {}

# File path of buildings.json
var buildings_json = "res://assets/data/buildings.json"
# building_id -> BuildingStats
var buildings_dict : Dictionary = {}

func _init():
	logger = Logger.Log.new()
	upgrade_tree = GameObjs.UpgradeTree.new()
	load_buildings_json()

func _ready():
	grid_size = 15
	turn = 0
	dead = 0
	resources = GameObjs.Resources.new()
	resources.set_reserves(_initial_reserves)

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

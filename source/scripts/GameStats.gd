extends Node
# This class holds all of the game data. This singleton object's namespace
# is globally registered, meaning you do not need to import it.
# You can call any method in this class by doing GameStats.method_name()
# And also access any variable in this class by doing GameStats.var_name

var resources : GameObjs.Resources
var upgrade_tree : GameObjs.UpgradeTree
var grid : Grid
var game : Game

var is_playing : bool # true if the game is still being played, false if it has ended
var win_status : bool # true if the player won. false if they lost
var just_won : int # number of turns since winning
var selling_enabled : bool # true if selling is enabled. false if disabled
var colonist_death_threshold : int
var scroll_down_queued : bool # true if we should scroll down after clicking
									  # the "back" button in the upgrades menu

var show_sell_no_refund_message : int # greater than 0 if we should show this when the player sells
var show_sell_yes_refund_message : int # greater than 0 if we should show this when the player sells

var shown_resources : Array # The resources to show. Resources in this array are shown.

var logger : Logger.Log
var group : int

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
		"position": Vector2(9.1, 7.7),
		"prereqs": [GameData.UpgradeType.UNLOCK_METAL2],
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
	GameData.UpgradeType.UNLOCK_METAL2: {
		"scene": preload("res://scenes/upgrades/impl/UnlockMetal2.tscn"),
		"position": Vector2(9.1, 6.3),
		"prereqs": [GameData.UpgradeType.IMPROVE_MINE1],
		"starting": false
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
		"prereqs": [GameData.UpgradeType.GRID_1],
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

var _initial_reserves = {
	GameData.ResourceType.FOOD: 140.0,
	GameData.ResourceType.OXYGEN: 450.0,
	GameData.ResourceType.WATER: 25.0,
	GameData.ResourceType.METAL: 0.0,
	GameData.ResourceType.ELECTRICITY: 100.0,
	GameData.ResourceType.SCIENCE: 1.0,
	GameData.ResourceType.PEOPLE: 10.0
}

var current_selected_building = null
var current_hovered_building = null
var multiselect_drag : int = 0

class BuildingStats:
	var shape : Array
	var name : String
	var effects : Dictionary
	var cost : Dictionary

	func _init():
		effects = {}
		cost = {}
	
	func format_str(quantity: int) -> String:
		var main_resource = 0
		var main_resource_amount = 0
		for e in effects:
			if effects[e] > main_resource_amount:
				main_resource_amount = effects[e]
				main_resource = e
		var plural = "s" if quantity > 1 else ""
		return "[color=%s]%s%s[/color]" % [GameData.get_resource_color_as_hex(main_resource), name, plural]

# File path of buildings.json
var buildings_json = "res://assets/data/buildings.json"
# building_id -> BuildingStats
var buildings_dict : Dictionary = {}

onready var building_scene = preload("res://scenes/Building.tscn")

func _init():
	logger = Logger.Log.new()
	upgrade_tree = GameObjs.UpgradeTree.new()
	load_buildings_json()

func _ready():
	reset_game(false)

"""
	Resets the game to the original state.
	is_restart : true iff the game is restarting
"""
func reset_game(is_restart : bool):
	group = GameStats.logger.get_group()
	print("Group " + str(group))
	show_sell_no_refund_message = 2
	show_sell_yes_refund_message = 2
	is_playing = true
	grid_size = 15
	turn = 1
	dead = 0
	colonist_death_threshold = 100
	resources = GameObjs.Resources.new()
	resources.set_reserves(_initial_reserves)
	buildings_unlocked = []
	buildings_owned = {}
	restrictions = {}
	current_selected_building = null
	current_hovered_building = null
	multiselect_drag = false
	just_won = 0
	selling_enabled = false
	scroll_down_queued = false
	upgrade_tree = GameObjs.UpgradeTree.new()
	if is_restart:
		get_tree().reload_current_scene()

"""
	Show the win/lose screen
	is_win true if the player won
	false if the player lost
"""
func show_win_lose_screen(is_win : bool) -> void:
	is_playing = false
	GameStats.win_status = is_win
	game.sidebar.on_ending()
	logger.log_level_action(Logger.Actions.Win if is_win else Logger.Actions.Lose, {
		"game": GameStats.serialize()
	})

func serialize_buildings():
	var buildings = []
	for building in get_tree().get_nodes_in_group("buildings"):
		if building.purchased:
			buildings.append(building.serialize())
	return buildings

func deserialize_buildings(buildings):
	for data in buildings:
		var type = int(data.id)
		if type == GameData.BuildingType.CENTER:
			continue
		var building = building_scene.instance()
		var building_stats = buildings_dict[type]
		building.shape = building_stats.shape
		building.building_effects = building_stats.effects
		building.building_cost = building_stats.cost
		building.building_id = type
		building.texture = GameData.BUILDING_TO_TEXTURE[type]
		get_tree().current_scene.add_child(building)
		building.deserialize(data)
		game._on_SceneTree_node_added(building)

const SERIALIZATION_VERSION = 1
const SAVE_FILE = "res://savegame.save"

func save_game():
	var save_game = File.new()
	save_game.open(SAVE_FILE, File.WRITE)
	save_game.store_line(JSON.print(serialize()))
	save_game.close()

func load_game() -> bool:
	var save_game = File.new()
	if not save_game.file_exists(SAVE_FILE):
		print("Save file not found. Aborting load.")
		return false
	save_game.open(SAVE_FILE, File.READ)
	var res = JSON.parse(save_game.get_line())
	save_game.close()
	if res.error != OK:
		print("JSON parse error: " + res.error_string + ". Aborting load.")
		return false
	var data = res.result
	if data.serialization_version != SERIALIZATION_VERSION:
		print("Serialization version mismatch (file: " + str(data.serialization_version) + ", game: " + str(SERIALIZATION_VERSION) + "). Aborting load.")
		return false
	deserialize(data)
	return true

func serialize():
	return {
		"serialization_version": SERIALIZATION_VERSION,
		"turn": turn,
		"dead": dead,
		"colonist_death_threshold": colonist_death_threshold,
		"win_status": win_status,
		"is_playing": is_playing,
		"resources": resources.serialize(),
		"upgrades": upgrade_tree.serialize(),
		"buildings": serialize_buildings(),
		"grid_size": grid_size,
		"group": GameStats.logger.get_group()
	}

func deserialize(data):
	assert(data.serialization_version == SERIALIZATION_VERSION)
	colonist_death_threshold = data.colonist_death_threshold
	turn = data.turn
	dead = data.dead
	is_playing = data.is_playing
	resources.deserialize(data.resources)
	deserialize_buildings(data.buildings)
	upgrade_tree.deserialize(data.upgrades)
	if not is_playing:
		show_win_lose_screen(data.win_status)
	else:
		game.update_stats()
		game.sidebar.show_all()

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
	# ("Loaded the buildings: " + str(buildings_dict.keys()))
	file.close()

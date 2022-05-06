extends Node
# This class holds all of the game data. This singleton object's namespace
# is globally registered, meaning you do not need to import it.
# You can call any method in this class by doing GameStats.method_name()
# And also access any variable in this class by doing GameStats.var_name

var resources : GameObjs.Resources

var grid_size : int # the number of squares the grid is at the moment

var _initial_reserves = {
	GameData.ResourceType.FOOD: 100.0,
	GameData.ResourceType.OXYGEN: 100.0,
	GameData.ResourceType.WATER: 55.0,
	GameData.ResourceType.METAL: 60.0,
	GameData.ResourceType.ELECTRICITY: 50.0,
	GameData.ResourceType.SCIENCE: 0.0,
	GameData.ResourceType.PEOPLE: 25.0
}

# Called when the node enters the scene tree for the first time.
# Note that this is loaded before every other node, as it is global.
# Note: Since this is a singleton, this will only be called once.
func _ready():
	grid_size = 15
	resources = GameObjs.Resources.new()
	resources.set_reserves(_initial_reserves)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

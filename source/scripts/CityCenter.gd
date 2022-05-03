extends Building

var game : Game

func _ready():
	game = get_parent()

func _people():
	return game.resources.get_reserve(GameData.ResourceType.PEOPLE)

func get_effect(resource : int) -> float:
	if (resource != GameData.ResourceType.PEOPLE):
		var consumption_map = GameData.PEOPLE_RESOURCE_CONSUMPTION
		if (consumption_map.has(resource)):
			return -(consumption_map[resource] * floor(_people()))
		return 0.0
	var turn = game.turn
	var turn_progression = GameData.TURN_PROGRESSION
	var factor = turn_progression[0]
	for turn_start in turn_progression.keys():
		if turn_start > turn:
			break
		factor = turn_progression[turn_start]

	return _people() * factor

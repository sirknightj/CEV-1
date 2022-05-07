extends Building

var game : Game

func center():
	var middle = -1.5 * GameData.SQUARE_SIZE
	.set_next_pos(.snapped(Vector2(middle, middle)))

func _ready():
	game = get_parent()
	center()

func _people():
	return GameStats.resources.get_reserve(GameData.ResourceType.PEOPLE)

func get_effect(resource : int) -> float:
	if (resource != GameData.ResourceType.PEOPLE):
		var consumption_map = GameData.PEOPLE_RESOURCE_CONSUMPTION
		if (consumption_map.has(resource)):
			return -(consumption_map[resource] * floor(_people()))
		return 0.0
	var turn = GameStats.turn
	var turn_progression = GameData.TURN_PROGRESSION
	var factor = turn_progression[0]
	for turn_start in turn_progression.keys():
		if turn_start > turn:
			break
		factor = turn_progression[turn_start]

	return _people() * factor

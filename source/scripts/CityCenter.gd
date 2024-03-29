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

func get_base_effect(resource : int) -> float:
	if (resource == GameData.ResourceType.SCIENCE):
		return 1.0
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
	
	# To prevent cheesing
	if turn > 15 and GameStats.resources.get_reserve(GameData.ResourceType.PEOPLE) < 50:
		factor += (50 - _people()) / 100 * 2
	
	if GameStats.win_status:
		if turn % 10 == 0:
			factor += 0.07
		else:
			factor += 0.03
		if turn % 100 == 69:
			factor += 0.069
	
	return _people() * factor

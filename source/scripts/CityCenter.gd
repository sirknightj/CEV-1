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
	
	if GameStats.logger.get_group(0):
		if peopleOnTurn.has(turn):
			return peopleOnTurn[turn]

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

var peopleOnTurn : Dictionary = {"1":5,"2":1.05,"3":1.1235,"4":10.3041,"5":6.8694,"6":2.74776,"7":2.967581,"8":3.204987,"9":3.461386,"10":7.009307,"11":1.612141,"12":1.660505,"13":1.71032,"14":1.76163,"15":0.604826,"16":0.610874,"17":0.616983,"18":0.623153,"21":0.680176,"22":0.686978,"23":0.693847,"24":0.700786,"25":0.707794,"26":0.714872,"27":0.72202,"28":0.729241,"29":0.736533,"30":8.92678,"31":1.249749,"32":1.268495,"33":1.287523,"34":1.306836,"35":8.400775,"36":2.42075,"37":2.481269,"38":2.5433,"39":2.606883,"40":2.672055,"41":2.738856,"42":2.807328,"43":2.877511,"44":2.949449,"45":1.511592,"46":1.530487,"47":1.549618,"48":1.568989,"49":1.588601,"50":12.867668,"51":1.415443,"52":1.429598,"53":1.443894,"54":1.458333,"55":1.472916,"56":1.487645,"57":1.502522,"58":1.517547,"59":1.532722,"60":0.92883,"61":0.934403,"62":0.940009,"63":0.945649,"64":0.951323,"65":0.957031,"66":1.44416,"67":1.457157,"68":1.470272,"69":26.373408,"70":1.529658,"71":1.541895,"72":1.55423,"73":1.566664,"74":1.579197,"75":1.338133,"76":1.347132,"77":1.356191,"78":1.365312,"79":1.374493,"80":1.383737,"81":1.393042,"82":1.402411,"83":1.411842,"84":1.421336,"85":1.430895,"86":1.440518,"87":1.450205,"88":1.459958,"89":1.469776,"90":1.47966,"91":1.489611,"92":1.499629,"93":1.509714,"94":1.519866,"95":1.530088,"96":1.540377}

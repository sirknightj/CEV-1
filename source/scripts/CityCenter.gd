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
	
	if GameStats.group == 1:
		if peopleOnTurn.has(turn + 1):
			return peopleOnTurn[turn + 1] - _people()

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

var peopleOnTurn : Dictionary = {"2":15,"3":16.05,"4":17.1735,"5":27.4776,"6":34.347,"7":37.09476,"8":40.062341,"9":43.267328,"10":46.728714,"11":53.738021,"12":55.350162,"13":57.010667,"14":58.720987,"15":60.482617,"16":61.087443,"17":61.698317,"18":62.3153,"19":62.938453,"20":63.567838,"21":68.017587,"22":68.697762,"23":69.38474,"24":70.078587,"25":70.779373,"26":71.487167,"27":72.202039,"28":72.924059,"29":73.6533,"30":74.389833,"31":83.316613,"32":84.566362,"33":85.834857,"34":87.12238,"35":88.429216,"36":96.829991,"37":99.250741,"38":101.73201,"39":104.27531,"40":106.882193,"41":109.554247,"42":112.293104,"43":115.100431,"44":117.977942,"45":120.92739,"46":122.438983,"47":123.96947,"48":125.519089,"49":127.088077,"50":128.676678,"51":141.544346,"52":142.959789,"53":144.389387,"54":145.833281,"55":147.291614,"56":148.76453,"57":150.252175,"58":151.754697,"59":153.272244,"60":154.804967,"61":155.733796,"62":156.668199,"63":157.608208,"64":158.553858,"65":159.505181,"66":160.462212,"67":161.906372,"68":163.363529,"69":164.833801,"70":191.207209,"71":192.736867,"72":194.278762,"73":195.832992,"74":197.399656,"75":198.978853,"76":200.316986,"77":201.664117,"78":203.020309,"79":204.38562,"80":205.760113,"81":207.14385,"82":208.536893,"83":209.939303,"84":211.351145,"85":212.772481,"86":214.203376,"87":215.643894,"88":217.094099,"89":218.554057,"90":220.023833,"91":221.503493,"92":222.993104}

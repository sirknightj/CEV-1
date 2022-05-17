extends Object
class_name GameData

"""
	The type of building represented
"""
enum BuildingType {
	CENTER,
	ELEC1,
	ELEC2,
	ELEC3,
	END1,
	FOOD1,
	FOOD2,
	FOOD3,
	METAL1,
	METAL2,
	OXY1,
	OXY2,
	OXY3,
	SCI1,
	SCI2,
	WATER1,
	WATER2,
	WATER3
}

"""
	The type of resource represented
"""
enum ResourceType {
	FOOD,
	WATER,
	OXYGEN,
	ELECTRICITY,
	METAL,
	SCIENCE,
	PEOPLE
}

"""
	The upgrade type (ID)
"""
enum UpgradeType {
	UNLOCK_SCI1
	UNLOCK_SCI2
	UNLOCK_WATER1
	UNLOCK_WATER2
	UNLOCK_WATER3
	UNLOCK_FOOD1
	UNLOCK_FOOD2
	UNLOCK_FOOD3
	UNLOCK_OXY1
	UNLOCK_OXY2
	UNLOCK_OXY3
	UNLOCK_METAL1
	UNLOCK_METAL2
	UNLOCK_ELEC1
	UNLOCK_ELEC2
	UNLOCK_ELEC3
	UNLOCK_END1
	GRID_1
	GRID_2
	GRID_3
	GRID_4
	IMPROVE_FARM1
	IMPROVE_MINE1
	ASTRO
	IMPROVE_FARM2
	IMPROVE_PEOPLE1
	IMPROVE_PEOPLE2
	IMPROVE_ELEC1
}

"""
	A map of buildings to their texture file
"""
const BUILDING_TO_TEXTURE : Dictionary = {
	BuildingType.CENTER: preload("res://assets/images/center.png"),
	BuildingType.ELEC1: preload("res://assets/images/elec1.png"),
	BuildingType.ELEC2: preload("res://assets/images/elec2.png"),
	BuildingType.ELEC3: preload("res://assets/images/elec3.png"),
	BuildingType.END1: preload("res://assets/images/end1.png"),
	BuildingType.FOOD1: preload("res://assets/images/food1.png"),
	BuildingType.FOOD2: preload("res://assets/images/food2.png"),
	BuildingType.FOOD3: preload("res://assets/images/food3.png"),
	BuildingType.METAL1: preload("res://assets/images/metal1.png"),
	BuildingType.METAL2: preload("res://assets/images/metal2.png"),
	BuildingType.OXY1: preload("res://assets/images/oxy1.png"),
	BuildingType.OXY2: preload("res://assets/images/oxy2.png"),
	BuildingType.OXY3: preload("res://assets/images/oxy3.png"),
	BuildingType.SCI1: preload("res://assets/images/sci1.png"),
	BuildingType.SCI2: preload("res://assets/images/sci2.png"),
	BuildingType.WATER1: preload("res://assets/images/water1.png"),
	BuildingType.WATER2: preload("res://assets/images/water2.png"),
	BuildingType.WATER3: preload("res://assets/images/water3.png")
}

"""
	The size of each square on the grid
"""
const SQUARE_SIZE : float = 32.0

"""
	A map of turns to the people growth factor
	The growth factor for a given turn is TURN_PROGRESSION[i] where i is the max
	i represented in the map such that i <= turn
"""
const TURN_PROGRESSION : Dictionary = {
	0: 0,
	1: 0.05,
	2: 0.08,
	4: 0.25,
	5: 0.08,
	8: 0.08,
	10: 0.15,
	11: 0.03,
	15: 0.01,
	20: 0.07,
	21: 0.01,
	35: 0.095,
	36: 0.025,
	45: 0.0125,
	50: 0.10,
	51: 0.01,
	60: 0.006,
	66: 0.009,
	69: 0.16,
	70: 0.008,
	75: 0.006725
}

"""
	A map representing how much of each resource one person consumes
	Omitted resources are equivalent to 0.0
"""
const PEOPLE_RESOURCE_CONSUMPTION : Dictionary = {
	ResourceType.FOOD: 2.0,
	ResourceType.WATER: 1.0,
	ResourceType.OXYGEN: 1.0
}

static func is_resource_type(type : int) -> bool:
	return type in ResourceType.values()

static func is_building_type(type : int) -> bool:
	return type in BuildingType.values()

static func is_upgrade_type(type : int) -> bool:
	return type in UpgradeType.values()

static func fix_types(va) -> Dictionary:
	var iter = range(len(va)) if typeof(va) == TYPE_ARRAY else va.keys()
	var fixed = {}
	for str_type in iter:
		var type = int(str_type)
		fixed[type] = va[str_type]
	return fixed

"""
	Colors
"""
const COLORS : Dictionary = {
	ResourceType.WATER: Color("#0070c0"),
	ResourceType.FOOD: Color("#00b050"),
	ResourceType.OXYGEN: Color("#ff3300"),
	ResourceType.ELECTRICITY: Color("#ffcc00"),
	ResourceType.METAL: Color("#ff9933"),
	ResourceType.SCIENCE: Color("#cc66ff"),
	ResourceType.PEOPLE: Color("#bdd7ee"),
}

static func get_resource_color_as_hex(resource_type: int) -> String:
	assert(is_resource_type(resource_type))
	var color = COLORS[resource_type]
	return "#%02X%02X%02X" % [color.r8, color.g8, color.b8]

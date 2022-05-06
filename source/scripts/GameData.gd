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
	10: 0.15,
	11: 0.03,
	15: 0.01,
	20: 0.07,
	21: 0.01,
	35: 0.095,
	36: 0.025
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

static func GET_SQUARE_SIZE() -> float:
	return 32.0



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

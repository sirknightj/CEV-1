extends Object
class_name GameObjs

class GameResource:
	# Amount of resource currently in reserves
	var reserves : float = 0
	# Amount of resource generated per turn
	var income : float = 0
	# Amount of resource used per turn
	var expense : float = 0

	func step_n(n : int):
		reserves += (income - expense) * n

class Resources:
	var resources : Dictionary = {}

	func _init_resources():
		for type in GameData.ResourceType.values():
			resources[type] = GameResource.new()

	func _init():
		_init_resources()

	func reset_income_expense():
		for resource in resources.values():
			resource.income = 0
			resource.expense = 0

	func set_reserve(type : int, amount_in_reserve : float):
		assert(GameData.is_resource_type(type))
		resources[type].reserves = amount_in_reserve

	func add_effect(type : int, effect : float):
		if (effect < 0):
			add_expense(type, -effect)
		else:
			add_income(type, effect)

	func add_income(type : int, income : float):
		assert(GameData.is_resource_type(type))
		resources[type].income += income

	func add_expense(type : int, expense : float):
		assert(GameData.is_resource_type(type))
		resources[type].expense += expense

	func set_reserves(reserves : Dictionary):
		for type in reserves:
			assert(GameData.is_resource_type(type))
			resources[type].reserves = reserves[type]
	
	func give(type : int, amount : float):
		assert(amount > 0 and GameData.is_resource_type(type))
		resources[type].reserves += amount
	
	func consume(type : int, amount : float):
		assert(amount > 0 and GameData.is_resource_type(type))
		resources[type].reserves -= amount

	# Consumes the given GameData.ResourceType -> float dictionary if there are
	# enough resources in reserves. Returns true if there are and we have
	# consumed the appropriate resources, returns false if there are not enough
	# so we do not consume any resources
	func try_consume(consume_resources : Dictionary) -> bool:
		if not enough_resources(consume_resources):
			return false
		for type in consume_resources.keys():
			resources[type].reserves -= consume_resources[type]
		return true
	
	func enough_resources(res : Dictionary) -> bool:
		for type in res.keys():
			assert(GameData.is_resource_type(type))
			if resources[type].reserves < res[type]:
				return false
		return true

	func get_reserve(type : int) -> float:
		assert(GameData.is_resource_type(type))
		return resources[type].reserves

	func get_income(type : int) -> float:
		assert(GameData.is_resource_type(type))
		return resources[type].income

	func get_expense(type : int) -> float:
		assert(GameData.is_resource_type(type))
		return resources[type].expense

	func get_net(type : int) -> float:
		assert(GameData.is_resource_type(type))
		return get_income(type) - get_expense(type)

		# Alias for step_n(1)
	func step() -> void:
		step_n(1)
	
	"""
		Return a string representation of this for debugging purposes
	"""
	func to_string() -> String:
		var ret_val : String = ""
		for resource_type in GameData.ResourceType.values():
			ret_val += str(GameData.ResourceType.keys()[resource_type].capitalize()) + ": "
			ret_val += str(get_reserve(resource_type)) + " (+" + str(get_income(resource_type)) + ", -" + str(get_expense(resource_type)) + ")\n"
		return ret_val.strip_edges()

	"""
		Increment and decrement reserves based on current income/expense for
		each reserve
		n : The number of times to update the reserves
	"""
	func step_n(n : int):
		for resource in resources.values():
			resource.step_n(n)

class UpgradeTree:
	var _tree_json = "res://assets/data/tree.json"
	var tree_dict : Dictionary = {} # upgrade name -> upgrade data
	
	func _init() -> void:
		load_tree_json()
		recalculate_available()
	
	# Loads upgrades configuration file
	func load_tree_json() -> void:
		var file = File.new()
		assert(file.file_exists(_tree_json))
		file.open(_tree_json, File.READ)
		var data = parse_json(file.get_as_text())
		for upgrade in data:
			tree_dict[upgrade.name] = Upgrade.new(upgrade, self)
		print("Loaded the upgrades: " + str(tree_dict.keys()))
		file.close()
	
	func recalculate_available() -> void:
		for v in tree_dict.values():
			v.recalculate_available()

class Upgrade:
	var name: String
	var prereqs: Array
	var type: String
	var description: String
	var effects: String
	var unlocks: String
	var science_cost: int
	var unlocked: bool
	var available: bool
	var enabled: bool
	var node: Node
	var links: Array
	var pos: Vector2
	var tree: UpgradeTree
	
	func _init(data, parent_tree) -> void:
		name = data.name
		prereqs = data.prereqs if data.prereqs else []
		type = data.type
		description = data.description
		effects = data.effects
		unlocks = data.unlocks
		science_cost = -data.science_cost
		node = null
		unlocked = data.starting
		available = false # correctly set by recalculate_available later
		enabled = data.starting
		tree = parent_tree
		
		var minX = 0.7
		var maxX = 9.1
		var minY = 0.7
		var maxY = 9.1
		
		var minScreenX = 100
		var maxScreenX = 800
		var minScreenY = 100
		var maxScreenY = 720 - 90
		
		var x = (data.x-minX) / (maxX-minX) * (maxScreenX-minScreenX) + minScreenX
		var y = (data.y-minY) / (maxY-minY) * (maxScreenY-minScreenY) + minScreenY
		pos = Vector2(x, y)
	
	func unlock() -> void:
		assert(not unlocked and available)
		unlocked = true
		enabled = true
		tree.recalculate_available()
	
	func recalculate_available() -> void:
		if available:
			return
		for p in prereqs:
			if not tree.tree_dict.get(p).unlocked:
				return
		available = true
	
	func get_all_pre_links() -> Array:
		var res = links.duplicate()
		for p in prereqs:
			res += tree.tree_dict.get(p).get_all_pre_links()
		return res

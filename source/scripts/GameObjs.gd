extends Object
class_name GameObjs

signal resources_changed

class GameResource:
	# Amount of resource currently in reserves
	var reserves : float = 0
	# Amount of resource generated per turn
	var income : float = 0
	# Amount of resource used per turn
	var expense : float = 0

	func step_n(n : int):
		reserves += (income - expense) * n

	func serialize():
		return {
			"reserves": reserves,
			"income": income,
			"expense": expense
		}

	func deserialize(data):
		reserves = data.reserves
		income = data.income
		expense = data.expense

class Resources:
	var resources : Dictionary = {}
	var callback : FuncRef
	var resources_generated : Dictionary = {}  # only for final stats purposes
	var resources_used : Dictionary = {}  # only for final stats purposes

	func _init_resources():
		for type in GameData.ResourceType.values():
			resources[type] = GameResource.new()
			resources_generated[type] = 0
			resources_used[type] = 0

	func _init():
		_init_resources()

	func set_callback(cb : FuncRef):
		callback = cb

	func get_callback():
		return callback

	func on_update():
		if callback != null:
			callback.call_func()

	func reset_income_expense():
		for resource in resources.values():
			resource.income = 0
			resource.expense = 0

	func set_reserve(type : int, amount_in_reserve : float):
		assert(GameData.is_resource_type(type))
		resources[type].reserves = amount_in_reserve
		on_update()

	func add_effect(type : int, effect : float):
		if (effect < 0):
			add_expense(type, -effect)
		else:
			add_income(type, effect)

	func add_income(type : int, income : float):
		assert(GameData.is_resource_type(type))
		resources[type].income += income
		on_update()

	func add_expense(type : int, expense : float):
		assert(GameData.is_resource_type(type))
		resources[type].expense += expense
		on_update()

	func set_reserves(reserves : Dictionary):
		for type in reserves:
			assert(GameData.is_resource_type(type))
			resources[type].reserves = reserves[type]
		on_update()

	func give(type : int, amount : float):
		assert(amount > 0 and GameData.is_resource_type(type))
		resources[type].reserves += amount
		resources_generated[type] += amount
		on_update()

	func consume(type : int, amount : float):
		assert(amount > 0 and GameData.is_resource_type(type))
		resources[type].reserves -= amount
		resources_used[type] += amount
		on_update()

	# Consumes the given GameData.ResourceType -> float dictionary if there are
	# enough resources in reserves. Returns true if there are and we have
	# consumed the appropriate resources, returns false if there are not enough
	# so we do not consume any resources
	func try_consume(consume_resources : Dictionary) -> bool:
		if not enough_resources(consume_resources):
			return false
		for type in consume_resources.keys():
			resources[type].reserves -= consume_resources[type]
			resources_used[type] += consume_resources[type]
		on_update()
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
		on_update()

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
		for type in resources:
			var resource = resources[type]
			resource.step_n(n)
			resources_generated[type] += resource.income
			resources_used[type] += resource.expense

	func serialize():
		var serialized_resources : Dictionary = {}
		for type in resources:
			serialized_resources[type] = resources[type].serialize()
		return {
			"resources": serialized_resources,
			"resources_generated": resources_generated,
			"resources_used": resources_used
		}

	func fix_types(dict):
		var fixed = {}
		for str_type in dict:
			var type = int(str_type)
			assert(GameData.is_resource_type(type))
			fixed[type] = dict[str_type]
		return fixed

	func deserialize(data):
		resources_generated = fix_types(data.resources_generated)
		resources_used = fix_types(data.resources_used)
		var load_resources = fix_types(data.resources)
		for type in load_resources:
			var resource = GameResource.new()
			resource.deserialize(load_resources[type])
			self.resources[type] = resource
		on_update()

class UpgradeTree:
	var tree_dict : Dictionary = {} # upgrade ID -> upgrade data
	var num_initial_unlocked : int = 0

	# Loads upgrades to the given node
	func load_upgrade_tree(parent : Node) -> void:
		for id in GameStats.upgrades_data.keys():
			var upgrade = GameStats.upgrades_data[id]
			var instance : Upgrade = upgrade.scene.instance()
			instance.id = id
			parent.add_child(instance)
			tree_dict[id] = UpgradeTreeNode.new({
				"id": id,
				"name": instance.upgrade_name,
				"prereqs": upgrade.prereqs,
				"description": instance.description,
				"effects": instance.effects,
				"cost": instance.cost,
				"starting": upgrade.starting,
				"x": upgrade.position.x,
				"y": upgrade.position.y,
				"instance": instance
			}, self)
			if upgrade.starting:
				num_initial_unlocked += 1
		recalculate_available()

	func recalculate_available() -> void:
		for v in tree_dict.values():
			v.recalculate_available()

	func get_num_bought() -> int:
		var num_unlocked = 0
		for v in tree_dict.values():
			if v.unlocked:
				num_unlocked += 1
		return num_unlocked - num_initial_unlocked

	func serialize():
		var upgrades = {}
		for type in tree_dict:
			upgrades[type] = tree_dict[type].serialize()
		return upgrades

	func deserialize(upgrades):
		for str_type in upgrades:
			var type = int(str_type)
			tree_dict[type].deserialize(upgrades[str_type])
		recalculate_available()

class UpgradeTreeNode:
	var id: int
	var name: String
	var prereqs: Array
	var description: String
	var effects: String
	var cost: Dictionary
	var unlocked: bool
	var available: bool
	var enabled: bool
	var node: Node
	var links: Array
	var pos: Vector2
	var tree: UpgradeTree
	var instance: Upgrade

	func _init(data, parent_tree) -> void:
		id = data.id
		name = data.name
		prereqs = data.prereqs if data.prereqs else []
		description = data.description
		effects = data.effects
		cost = data.cost
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

		instance = data.instance
		if data.starting:
			instance.purchased = true

	func can_afford() -> bool:
		return GameStats.resources.enough_resources(cost)

	func unlock() -> void:
		assert(not unlocked and available)
		unlocked = true
		enabled = true
		instance.purchase()
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

	func serialize():
		return {
			"unlocked": unlocked
		}

	func deserialize(data):
		if data.unlocked:
			unlocked = true
			enabled = true
			instance.purchased = true
			instance.apply()

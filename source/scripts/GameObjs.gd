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

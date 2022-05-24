extends Upgrade
class_name BuildingEffectUpgrade

export(Dictionary) var multipliers

var multi_stack = {}

func get_num_stacks(building):
	return multi_stack[building] if multi_stack.has(building) else 1

func stack_effect(building, resource_type : int, current_effect : float):
	assert(GameData.is_resource_type(resource_type))
	if multipliers.has(resource_type):
		var stacks = get_num_stacks(building)
		return current_effect + current_effect * (multipliers[resource_type] - 1) * stacks
	else:
		return current_effect

func get_name_for(building) -> String:
	var stacks = get_num_stacks(building)
	var n = .get_name_for(building)
	if stacks > 1:
		return "%s (x%d)" % [n, stacks]
	else:
		return n

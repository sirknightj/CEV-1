extends Upgrade
class_name BuildingEffectUpgrade

export(Dictionary) var multipliers

func stack_effect(_building, resource_type : int, current_effect : float):
	assert(GameData.is_resource_type(resource_type))
	if multipliers.has(resource_type):
		return current_effect * multipliers[resource_type]
	else:
		return current_effect

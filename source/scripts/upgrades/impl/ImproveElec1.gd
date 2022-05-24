extends AdjacencyUpgrade

var _stacks = {}

func apply_to(buildings : Array):
	for building in buildings:
		if (building.building_id == GameData.BuildingType.ELEC1
				or building.building_id == GameData.BuildingType.ELEC2
				or building.building_id == GameData.BuildingType.ELEC3):
			var found = false
			self.multi_stack[building] = 0
			for adjacent in building.get_adjacent_buildings():
				if (adjacent.building_id == GameData.BuildingType.ELEC1
						or adjacent.building_id == GameData.BuildingType.ELEC2
						or adjacent.building_id == GameData.BuildingType.ELEC3):
					found = true
					self.multi_stack[building] += 1
			if not found:
				building.remove_building_effect_upgrade(self)
			else:
				building.add_building_effect_upgrade(self)

extends AdjacencyUpgrade

func apply_to(buildings : Array):
	for building in buildings:
		if building.building_id == GameData.BuildingType.ELEC1:
			print("Doing building ", building.name)
			var found = false
			for adjacent in building.get_adjacent_buildings():
				print("Adjacent building: ", GameData.BuildingType.keys()[adjacent.building_id])
				if adjacent.building_id == GameData.BuildingType.ELEC1:
					found = true
					building.add_building_effect_upgrade(self)
					break
			if not found:
				building.remove_building_effect_upgrade(self)

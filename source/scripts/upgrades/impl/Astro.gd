extends AdjacencyUpgrade

func apply_to(buildings : Array):
	for building in buildings:
		if (building.building_id == GameData.BuildingType.FOOD1
				or building.building_id == GameData.BuildingType.FOOD2
				or building.building_id == GameData.BuildingType.FOOD3):
			var found = false
			for adjacent in building.get_adjacent_buildings():
				if (adjacent.building_id == GameData.BuildingType.SCI1
						or adjacent.building_id == GameData.BuildingType.SCI2):
					found = true
					building.add_building_effect_upgrade(self)
					break
			if not found:
				building.remove_building_effect_upgrade(self)

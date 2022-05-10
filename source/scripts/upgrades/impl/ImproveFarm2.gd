extends AdjacencyUpgrade

func apply_to(buildings : Array):
	for building in buildings:
		if ((building.building_id == GameData.BuildingType.FOOD1
				or building.building_id == GameData.BuildingType.FOOD2
				or building.building_id == GameData.BuildingType.FOOD3)
				and not building.has_building_effect_upgrade(self)):
			building.add_building_effect_upgrade(self)

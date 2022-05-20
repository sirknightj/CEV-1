extends BuildingEffectUpgrade
class_name AdjacencyUpgrade

func apply_to(buildings : Array):
	for building in buildings:
		if not building.has_building_effect_upgrade(self):
			building.apply_building_effect_upgrade(self)

func _on_Game_building_released(building : Building, old_adjacents : Array):
	building.disconnect("building_released", self, "_on_Game_building_released")
	var adjacents = building.get_adjacent_buildings()
	adjacents.append_array(old_adjacents)
	adjacents.append(building)
	apply_to(adjacents)

func _on_Game_building_grabbed(building: Building):
	building.connect("building_released", self, "_on_Game_building_released", [building.get_adjacent_buildings()])

func _on_Game_building_added(building : Building):
	if building._mouse_state == building.MouseState.DRAGGING:
		_on_Game_building_grabbed(building)
	building.connect("building_grabbed", self, "_on_Game_building_grabbed")
	var adjacents = building.get_adjacent_buildings()
	adjacents.append(building)
	apply_to(adjacents)

func apply():
	var buildings = GameStats.game.get_buildings()
	for building in buildings:
		_on_Game_building_added(building)
	GameStats.game.connect("building_added", self, "_on_Game_building_added")
	apply_to(buildings)

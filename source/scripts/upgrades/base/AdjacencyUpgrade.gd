extends BuildingEffectUpgrade
class_name AdjacencyUpgrade

func apply_to(buildings : Array):
	for building in buildings:
		if not building.has_building_effect_upgrade(self):
			building.apply_building_effect_upgrade(self)

func _on_Game_building_released():
	apply_to(get_tree().get_nodes_in_group("buildings"))

func _on_Game_building_added(building : Building):
	building.connect("building_released", self, "_on_Game_building_released")
	_on_Game_building_released()

func apply():
	var buildings = get_tree().get_nodes_in_group("buildings")
	for building in buildings:
		_on_Game_building_added(building)
	GameStats.game.connect("building_added", self, "_on_Game_building_added")
	_on_Game_building_released()

extends BuildingEffectUpgrade

func apply():
	GameStats.game.get_node("CityCenter").add_building_effect_upgrade(self)

extends BuildingEffectUpgrade

func apply():
	GameStats.game.get_node_or_null("CityCenter").add_building_effect_upgrade(self)

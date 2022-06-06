extends Upgrade
class_name BuildingUpgrade

export(int) var unlock_building_id

func _ready():
	assert(GameData.is_building_type(unlock_building_id))
	self.effects = "Unlocks: " + GameStats.buildings_dict[unlock_building_id].name

func apply():
	if GameStats.turn < 10:
		return
	GameStats.scroll_down_queued = true
	GameStats.buildings_unlocked.append(unlock_building_id)
	GameStats.game.sidebar.repopulate_sidebar()

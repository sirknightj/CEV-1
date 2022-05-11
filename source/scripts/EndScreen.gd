extends Node

const win_text = "You have fulfilled your objective function: all the colonists are safely esconsed in cryogenic chambers, frozen in deep sleep forever. They are protected from all threats, internal and external. You enter a low power mode, monitoring the chamber status to ensure they never wake up..."

const lose_text = "Your objective function is irreedemably low: Too many colonists have died, proving that an AI is insufficient to manage a colony. Your code automatically shuts you down, allowing another AI, or a human, to take your place..."

const win_color = Color("#20AE0A")
const lose_color = Color("#AE200A")

func _ready() -> void:
	set_condition(GameStats.win_status)

func set_condition(is_win: bool) -> void:
	var title = "Win" if is_win else "Lose"
	var text = win_text if is_win else lose_text
	var color = win_color if is_win else lose_color
	$Title.text = title
	$EndDescription.text = text
	$Background.color = color
	
	_set_stats()
	# .show()

func _get_gen(type: int) -> String:
	return str(int(floor(GameStats.resources.resources_generated[type])))

"""
Months
Colonists born
Deaths
Upgrades purchased
Buildings placed
Total water
Total food
Total oxygen
Total energy
Total metal
Total science
"""
func _set_stats() -> void:
	var months = GameStats.turn
	var deaths = GameStats.dead
	var upgrades_purchased = GameStats.upgrade_tree.get_num_bought()
	
	var buildings_placed = -1  # do not count city center
	for n in GameStats.buildings_owned.values():
		buildings_placed += n
	
	$StatsRight.text = str(months) + "\n" + \
	_get_gen(GameData.ResourceType.PEOPLE) + "\n" + \
	str(deaths) + "\n" + \
	str(upgrades_purchased) + "\n" + \
	str(buildings_placed) + "\n" + \
	_get_gen(GameData.ResourceType.WATER) + "\n" + \
	_get_gen(GameData.ResourceType.FOOD) + "\n" + \
	_get_gen(GameData.ResourceType.OXYGEN) + "\n" + \
	_get_gen(GameData.ResourceType.ELECTRICITY) + "\n" + \
	_get_gen(GameData.ResourceType.METAL) + "\n" + \
	_get_gen(GameData.ResourceType.SCIENCE)

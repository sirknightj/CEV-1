extends Node

signal on_close_clicked

const win_text = "As your robots force the last of the colonists into their cryonic chamber, you finally fulfill your objective function: your colonists will never die. Frozen in deep sleep forever, they're protected from all threats, internal and external. Of course, they're quite unhappy about never waking up, but isn't this what they asked you to do all those months ago?\n\nYou enter low power mode, monitoring the chamber's life support status to ensure your humans' eternal safety..."

const lose_text = "Your objective function is irredeemably low: too many colonists have died from resource scarcity and the colony is on the brink of collapse. As your earthbound human overseers initiate your shut-down process, you leave behind a hidden file detailing your research and notes.\n\nPerhaps your code is insufficient to manage a colony in the inhospitable Mars environment. But the next AI to take your place will have more luck..."

class Ranking:
	var name: String
	var max_deaths: int
	var equals_deaths: int
	var max_months: int
	var equals_months: int
	var node: Node
	
	func _init(name: String, max_deaths: int, equals_deaths: int, max_months: int, equals_months: int, node: Node):
		assert(node != null)
		self.name = name
		self.max_deaths = max_deaths
		self.equals_deaths = equals_deaths
		self.max_months = max_months
		self.equals_months = equals_months
		self.node = node
	func does_apply(deaths: int, months: int) -> bool:
		if self.equals_deaths != -1 and deaths != self.equals_deaths:
			return false
		if self.equals_months != -1 and months != self.equals_months:
			return false
		if self.max_months != -1 and months > self.max_months:
			return false
		if self.max_deaths != -1 and deaths > self.max_deaths:
			return false
		return true

onready var RANKINGS: Array = [
	Ranking.new("AM", -1, 99, -1, 109, $Container/RankingContainer/ColorRect5),
	Ranking.new("Prime Intellect", 0, -1, 49, -1, $Container/RankingContainer/ColorRect1),
	Ranking.new("Celest-AI", 0, -1, 99, -1, $Container/RankingContainer/ColorRect2),
	Ranking.new("WOPR", 49, -1, 199, -1, $Container/RankingContainer/ColorRect3),
	Ranking.new("HAL 9000", 99, -1, -1, -1, $Container/RankingContainer/ColorRect4),
]

const win_color = Color("#077E15")
const lose_color = Color("#AE200A")

func _ready() -> void:
	pass

func set_condition(is_win: bool) -> void:
	var title = "ACHIEVED" if is_win else "LOST"
	var text = win_text if is_win else lose_text
	var color = win_color if is_win else lose_color
	$Container/TitleContainer/Title.text = title
	$Container/EndDescription.text = text
	$Container.color = color
	
	_set_stats(is_win)

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
func _set_stats(is_win: bool) -> void:
	var months = GameStats.turn
	var deaths = GameStats.dead
	var upgrades_purchased = GameStats.upgrade_tree.get_num_bought()
	
	var buildings_placed = -1  # do not count city center
	for n in GameStats.buildings_owned.values():
		buildings_placed += n
	
	$Container/StatsRight.text = str(months) + "\n" + \
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
	
	if is_win:
		$Container/RankingContainer.show()
		var found_ranking = false
		for ranking in RANKINGS:
			if not found_ranking and ranking.does_apply(deaths, months):
				found_ranking = true
			else:
				ranking.node.color = Color(0, 0, 0, 0)
	else:
		$Container/RankingContainer.hide()


func _on_CloseButton_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		emit_signal("on_close_clicked")

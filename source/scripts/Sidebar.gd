extends Control
class_name SidebarX

onready var grid : Node2D = $"../../Grid"

var game : Game # The node representing the game
var Turn_Count_Text # The node holding the turn count text

var show_resources : Dictionary = {}
var ignore_next_month : bool = false # default = clickable
var ignore_upgrades_button = true # default = unclickable

onready var building_scene = preload("res://scenes/Building.tscn")
onready var row_scene = preload("res://scenes/BuildingRow.tscn")
onready var win_lose_scene = preload("res://scenes/EndScreen.tscn")

func _setup_control_element(control : Control):
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE

# Called when the node enters the scene tree for the first time.
func _ready():
	game = get_parent().get_parent()
	Turn_Count_Text = get_node("TurnCount")
	update_turn_display()

	# TODO: tutorial progression
	for resource in GameData.ResourceType.values():
		show_resources[resource] = false
	
	populate_sidebar_correctly()
	

func repopulate_sidebar():
	populate_sidebar_correctly()

func populate_sidebar_correctly() -> void:
	if not has_enough_electricity():
		toggle_next_month_button(false)
		get_parent().get_parent().get_node("UILayer/TextBox").text = "You don't have enough energy to keep your buildings running! You'll need to sell some buildings or generate more electricity!"
	elif GameStats.turn >= 12:
		toggle_next_month_button(true)
	
	if GameStats.colonist_death_threshold <= GameStats.dead:
		show_win_lose_screen(false)
	
	var turn = GameStats.turn
	if turn <= 2:
		GameStats.buildings_unlocked.append(GameData.BuildingType.WATER1)
		show_resources([GameData.ResourceType.WATER])
	elif turn <= 5:
		GameStats.buildings_unlocked.append(GameData.BuildingType.FOOD1)
		populate_sidebar_with_buildings([GameData.BuildingType.WATER1, GameData.BuildingType.FOOD1])
		show_resources([GameData.ResourceType.WATER, GameData.ResourceType.FOOD])
	elif turn <= 8:
		GameStats.buildings_unlocked.append_array([GameData.BuildingType.OXY1, GameData.BuildingType.METAL1])
		show_resources([GameData.ResourceType.WATER, GameData.ResourceType.FOOD, GameData.ResourceType.OXYGEN, GameData.ResourceType.METAL])
	elif turn <= 9:
		GameStats.buildings_unlocked.append(GameData.BuildingType.ELEC1)
		show_resources([GameData.ResourceType.WATER, GameData.ResourceType.FOOD, GameData.ResourceType.OXYGEN, GameData.ResourceType.METAL, GameData.ResourceType.ELECTRICITY])
	elif turn <= 10:
		GameStats.buildings_unlocked.append(GameData.BuildingType.SCI1)
		show_resources([GameData.ResourceType.WATER, GameData.ResourceType.FOOD, GameData.ResourceType.OXYGEN, GameData.ResourceType.METAL, GameData.ResourceType.ELECTRICITY, GameData.ResourceType.SCIENCE])
	populate_sidebar_with_buildings(GameStats.buildings_unlocked)

func show_resources(resources : Array) -> void:
	for resource in GameData.ResourceType.values():
		toggle(resource, resources.has(resource))

func toggle(resource : int, hide : bool) -> void:
	# Graph handles food, water, oxygen, metal, and energy
	if $Graph.RESOURCE_TYPE_TO_STRING.has(resource):
		var node = get_node("Graph/HBoxContainer/" + $Graph.RESOURCE_TYPE_TO_STRING[resource])
		node.visible = hide
	elif resource == GameData.ResourceType.SCIENCE:
		$Graph/Label.visible = hide
		$Graph/ScienceStore.visible = hide
		$Graph/ScienceDiff.visible = hide
	# ignore people

func populate_sidebar_with_buildings(_buildings : Array) -> void:
	var buildings : Dictionary = {}
	for building in _buildings:
		assert(GameData.BuildingType.values().has(building))
		buildings[building] = GameStats.buildings_dict[building]
	populate_sidebar(buildings)

func populate_sidebar(buildings : Dictionary) -> void:
	for child in $ScrollContainer/BuildingEntries.get_children():
		$ScrollContainer/BuildingEntries.remove_child(child)
	
	var scroll_offset = $ScrollContainer.get_v_scrollbar().value
	for building in buildings:
		var building_stats = GameStats.buildings_dict[building]
		
		if building_stats.name == "City center":
			continue
		
		var entry : Node = row_scene.instance()
		entry.get_node("BuildingName").text = GameStats.buildings_dict[building].name
		
		# TODO: sort costs decreasing
		var cost_text : String = ""
		for stat in building_stats.cost:
			if building_stats.cost[stat] > 0:
				cost_text += str(building_stats.cost[stat]) + " " + GameData.ResourceType.keys()[stat].capitalize() + "\n"
		entry.get_node("Cost").text = cost_text.strip_edges()
		
		# TODO: sort effects by abs(value) decreasing
		var effects_text : String = ""
		for stat in building_stats.effects:
			var e = building_stats.effects[stat]
			var key = GameData.ResourceType.keys()[stat].capitalize()
			if key == "Electricity":
				key = "Energy"
			if e > 0:
				effects_text += "+" + str(e) + " " + key + "\n"
			elif e < 0:
				effects_text += "-" + str(-e) + " " + key + "\n"
		entry.get_node("Effects").text = effects_text.strip_edges()
		
		# building icon
		var _building = building_scene.instance()
		_building.shape = building_stats.shape
		_building.building_effects = building_stats.effects
		_building.building_cost = building_stats.cost
		_building.building_id = building
		_building.texture = GameData.BUILDING_TO_TEXTURE[building]
		_building.set_locked(not available(building) or not GameStats.resources.enough_resources(building_stats.cost))
		entry.add_child(_building)
		
		# vertically center building with row
		var building_pos = Vector2(1035, $ScrollContainer.rect_position.y - scroll_offset)
		building_pos.y += entry.rect_min_size.y / 2 - _building.shape.size() * GameData.SQUARE_SIZE / 2
		
		$ScrollContainer/BuildingEntries.add_child(entry)
		_building.set_physics_process(false)
		_building.force_set(building_pos, 0.0, false)
		_building.connect("building_grabbed", self, "_on_Building_building_grabbed", [_building])
		_building.connect("building_destroy", self, "repopulate_sidebar")

func available(building) -> bool:
	return GameStats.restrictions.empty() or GameStats.restrictions.has(building)

func _on_Building_building_grabbed(building : Building):
	building.connect("building_released", self, "_on_Building_building_released", [building, building._main.global_position, building.get_parent()])
	var diff = get_global_mouse_position() - building._main.global_position
	building.get_parent().remove_child(building)
	get_tree().current_scene.add_child(building)
	building.force_update()
	var mouse = get_tree().current_scene.get_global_mouse_position()
	building.force_set(mouse - diff, 0.0, false)
	building.set_physics_process(true)

func _on_Building_building_released(building : Building, original_pos : Vector2, building_row : Node):
	building.disconnect("building_released", self, "_on_Building_building_released")
	if building.purchased:
		building.disconnect("building_grabbed", self, "_on_Building_building_grabbed")
		if GameStats.buildings_owned.has(building.building_id):
			GameStats.buildings_owned[building.building_id] += 1
		else:
			GameStats.buildings_owned[building.building_id] = 1
		placed_building(building.building_id)
		if building.building_id == GameData.BuildingType.END1:
			show_win_lose_screen(true)
	else:
		building.destroy()
	repopulate_sidebar()

"""
	Updates the text displaying the turn count
"""
func update_turn_display() -> void:
	Turn_Count_Text.text = "Month " + str(GameStats.turn)

"""
	Updates the text displaying the resource counts
"""
func update_displays() -> void:
	pass

"""
	Called when the NextMonth button is clicked
"""
func _on_Next_Month_gui_input(event):
	if (event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT):
		GameStats.logger.log_level_action(Logger.Actions.NextMonthClicked)
		# TODO(vishal)
		# print("People that will die next turn: " + str(how_many_people_will_die_next_turn()))
		if ignore_next_month:
			if GameStats.restrictions.keys().size() > 0:
				var required_placements = "Please place down "
				for building in GameStats.restrictions.keys():
					required_placements += (str(GameStats.restrictions[building]) + " more " + pluralize(GameStats.restrictions[building], GameStats.buildings_dict[building].name) + ", ") # TODO: get the actual building name instead of printing out the building id
				required_placements.erase(required_placements.length() - 2, 2)
				get_parent().get_parent().get_node("UILayer/TextBox").text = required_placements + "."
			elif GameStats.turn == 10:
				get_parent().get_parent().get_node("UILayer/TextBox").text = "Please check out the Upgrades menu!"
		else:
			game.on_next_turn()
			$Graph.reset_for_next_turn()
			update_turn_display()
			populate_sidebar_correctly()

"""
	Called when the Undo button is clicked
"""
func _on_Undo_gui_input(event):
	if (event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT):
		print("Undo was clicked!")
		GameStats.logger.log_level_action(Logger.Actions.UndoClicked)

"""
	Called when the Upgrades button is clicked
"""
func _on_Upgrades_gui_input(event):
	if (event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT):
		GameStats.logger.log_level_action(Logger.Actions.UpgradeMenuClicked)
		if GameStats.turn == 10:
			toggle_next_month_button(true)
		if not ignore_upgrades_button:
			$CanvasLayer/TechTree.show()

"""
	Tells the restrictions that the player has placed a building
"""
func placed_building(building : int):
	if GameStats.restrictions.has(building) and GameStats.restrictions[building] > 1:
		GameStats.restrictions[building] -= 1
	elif GameStats.restrictions.has(building) and GameStats.restrictions[building] == 1:
		GameStats.restrictions.erase(building)
	
	if GameStats.restrictions.keys().size() == 0 and GameStats.turn != 10:
		toggle_next_month_button(true)

func pluralize(quantity : int, word : String) -> String:
	if quantity == 1:
		return word
	else:
		return word + "s"

"""
	Returns how many people will die next turn
	0 if no one will die next turn
"""
func how_many_people_will_die_next_turn() -> int:
	var dead_colonists : int = 0
	for resource in GameData.PEOPLE_RESOURCE_CONSUMPTION:
		var resources_have : float = GameStats.resources.get_reserve(resource) + GameStats.resources.get_income(resource) - GameStats.resources.get_expense(resource)
		if 0 > resources_have:
			dead_colonists = max(dead_colonists, ceil(-resources_have / GameData.PEOPLE_RESOURCE_CONSUMPTION[resource]))
	return dead_colonists

"""
	Returns how much electricity you'll overdraw next turn
	0 if your electricity reserves are fine
"""
func how_much_electricity_over() -> int:
	var electricity_over : int = GameStats.resources.get_reserve(GameData.ResourceType.ELECTRICITY) + GameStats.resources.get_income(GameData.ResourceType.ELECTRICITY) - GameStats.resources.get_expense(GameData.ResourceType.ELECTRICITY)
	print(electricity_over)
	if electricity_over < 0:
		return -electricity_over
	else:
		return 0

"""
	Returns true if we have enough electricity for next turn
	false otherwise
"""
func has_enough_electricity() -> bool:
	return how_much_electricity_over() == 0

"""
	Returns a dictionary Resource -> # Needed to purchase a given building.
	Empty dictionary if player has enough resources
	_building : building id
"""
func resources_needed(_building) -> Dictionary:
	assert(GameStats.buildings_dict.has(_building))
	var needed : Dictionary = {}
	for resource in GameStats.buildings_dict[_building].cost:
		var amount_needed : float = GameStats.buildings_dict[_building].cost[resource]
		var have : float = GameStats.resources.get_reserve(resource)
		if amount_needed > have:
			needed[resource] = abs(amount_needed - have)
	return needed

"""
	Lets the "next month" button be clicked
	_clickable: true if the button is allowed to be clicked, false otherwise
"""
func toggle_next_month_button(_clickable : bool) -> void:
	ignore_next_month = not _clickable
	if _clickable:
		$NextMonth/Label.set("custom_colors/font_color", Color("#FFFFFF"))
	else:
		$NextMonth/Label.set("custom_colors/font_color", Color("#808080"))

"""
	Lets the "upgrades" button be clicked
	_clickable: true if the button is allowed to be clicked, false otherwise
"""
func toggle_upgrades_button(_clickable) -> void:
	ignore_upgrades_button = not _clickable
	if _clickable:
		$Upgrades.show()
	else:
		$Upgrades.hide()

"""
	Show the win/lose screen
	is_win true if the player won
	false if the player lost
"""
func show_win_lose_screen(is_win : bool) -> void:
	GameStats.win_status = is_win
	get_tree().change_scene("res://scenes/EndScreen.tscn")

const SCROLL_SPEED = 12
func _unhandled_input(event : InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_WHEEL_DOWN:
			$ScrollContainer.scroll_vertical += SCROLL_SPEED
		elif event.button_index == BUTTON_WHEEL_UP:
			$ScrollContainer.scroll_vertical -= SCROLL_SPEED

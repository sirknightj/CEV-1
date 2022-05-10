extends Control
class_name SidebarX

onready var grid : Node2D = $"../../Grid"

var game : Game # The node representing the game
var Turn_Count_Text # The node holding the turn count text

var show_resources : Dictionary = {}
var ignore_next_month : bool = false # default = clickable
var ignore_upgrades_button = true # default = unclickable

onready var building_scene = preload("res://scenes/Building.tscn")

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
	var turn = GameStats.turn
	if turn <= 2:
		populate_sidebar_with_buildings([GameData.BuildingType.WATER1])
		show_resources([GameData.ResourceType.WATER])
	elif turn <= 5:
		populate_sidebar_with_buildings([GameData.BuildingType.WATER1, GameData.BuildingType.FOOD1])
		show_resources([GameData.ResourceType.WATER, GameData.ResourceType.FOOD])
	elif turn <= 8:
		populate_sidebar_with_buildings([GameData.BuildingType.WATER1, GameData.BuildingType.FOOD1, GameData.BuildingType.OXY1, GameData.BuildingType.METAL1])
		show_resources([GameData.ResourceType.WATER, GameData.ResourceType.FOOD, GameData.ResourceType.OXYGEN, GameData.ResourceType.METAL])
	elif turn <= 14:
		populate_sidebar_with_buildings([GameData.BuildingType.WATER1, GameData.BuildingType.FOOD1, GameData.BuildingType.OXY1, GameData.BuildingType.METAL1, GameData.BuildingType.ELEC1])
		show_resources([GameData.ResourceType.WATER, GameData.ResourceType.FOOD, GameData.ResourceType.OXYGEN, GameData.ResourceType.METAL, GameData.ResourceType.ELECTRICITY, GameData.ResourceType.SCIENCE])
	else:
		populate_sidebar_with_buildings([GameData.BuildingType.WATER1, GameData.BuildingType.FOOD1, GameData.BuildingType.OXY1, GameData.BuildingType.METAL1, GameData.BuildingType.ELEC1, GameData.BuildingType.SCI1])
		show_resources([GameData.ResourceType.WATER, GameData.ResourceType.FOOD, GameData.ResourceType.OXYGEN, GameData.ResourceType.METAL, GameData.ResourceType.ELECTRICITY, GameData.ResourceType.SCIENCE])

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
		
		if building_stats.name != 'City center':
			var entry : HBoxContainer = HBoxContainer.new()
			_setup_control_element(entry)
			var building_name_label : Label = Label.new()
			building_name_label.text = GameStats.buildings_dict[building].name
			entry.add_child(building_name_label)
			
			var spacing1 : MarginContainer = MarginContainer.new()
			_setup_control_element(spacing1)
			spacing1.add_constant_override("margin_right", 20)
			entry.add_child(spacing1)
			spacing1.add_constant_override("margin_top", building_stats.shape.size() * GameData.SQUARE_SIZE)
			
			var building_cost_label : Label = Label.new()
			_setup_control_element(building_cost_label)
			var cost_text : String = "Cost:\n"
			for stat in building_stats.cost:
				if (building_stats.cost[stat] > 0):
					cost_text += str(building_stats.cost[stat]) + " " + GameData.ResourceType.keys()[stat].capitalize() + "\n"
			building_cost_label.text = cost_text.strip_edges()
			entry.add_child(building_cost_label)
			
			var spacing2 : MarginContainer = MarginContainer.new()
			_setup_control_element(spacing2)
			spacing2.add_constant_override("margin_right", 20)
			entry.add_child(spacing2)
			
			var building_effects_label : Label = Label.new()
			_setup_control_element(building_effects_label)
			var effects_text : String = "Effects:\n"
			for stat in building_stats.effects:
				if (building_stats.effects[stat] > 0):
					effects_text += "+" + str(building_stats.effects[stat]) + " " + GameData.ResourceType.keys()[stat].capitalize() + "/mo\n"
				elif (building_stats.effects[stat] < 0):
					effects_text += "-" + str(-building_stats.effects[stat]) + " " + GameData.ResourceType.keys()[stat].capitalize() + "/mo\n"
			building_effects_label.text = effects_text.strip_edges()
			entry.add_child(building_effects_label)
			
			# Attempting to put a building inside of the HBox
			var _building = building_scene.instance()
			_building.shape = building_stats.shape
			_building.building_effects = building_stats.effects
			_building.building_cost = building_stats.cost
			_building.building_id = building
			_building.texture = GameData.BUILDING_TO_TEXTURE[building]
			_building.locked = not available(building) or not GameStats.resources.enough_resources(building_stats.cost)
			print(GameStats.buildings_dict[building].name + ", locked=" + str(_building.locked) + ", available=" + str(available(building)) + ", enough=" + str(GameStats.resources.enough_resources(building_stats.cost)))
			entry.add_child(_building)
			
			$ScrollContainer/BuildingEntries.add_child(entry)
			_building.set_physics_process(false)
			_building.force_set(Vector2(1050, 375 - scroll_offset), 0.0)
			_building.connect("building_grabbed", self, "_on_Building_building_grabbed", [_building])
	
	var extra_spacing : HBoxContainer = HBoxContainer.new()
	var spacer : MarginContainer = MarginContainer.new()
	_setup_control_element(spacer)
	_setup_control_element(extra_spacing)
	spacer.add_constant_override("margin_top", GameData.SQUARE_SIZE)
	extra_spacing.add_child(spacer)
	$ScrollContainer/BuildingEntries.add_child(extra_spacing)

func available(building) -> bool:
	if GameStats.restrictions.has(building):
		return true
	elif GameStats.restrictions.keys().size() == 0:
		return true
	else:
		return false

func _on_Building_building_grabbed(building : Building):
	building.connect("building_released", self, "_on_Building_building_released", [building, building._main.global_position, building.get_parent()])
	var diff = get_global_mouse_position() - building._main.global_position
	building.get_parent().remove_child(building)
	get_tree().current_scene.add_child(building)
	building.force_update()
	var mouse = get_tree().current_scene.get_global_mouse_position()
	building.force_set(mouse - diff, 0.0)
	building.set_physics_process(true)

func _on_Building_building_released(building : Building, original_pos : Vector2, hbox : HBoxContainer):
	building.disconnect("building_released", self, "_on_Building_building_released")
	if building.purchased:
		building.disconnect("building_grabbed", self, "_on_Building_building_grabbed")
		if GameStats.buildings_owned.has(building.building_id):
			GameStats.buildings_owned[building.building_id] += 1
		else:
			GameStats.buildings_owned[building.building_id] = 1
		placed_building(building.building_id)
		repopulate_sidebar()
	else:
		building.set_physics_process(false)
		building.get_parent().remove_child(building)
		hbox.add_child(building)
		building.force_set(original_pos, 0.0)

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
		if ignore_next_month:
			if GameStats.restrictions.keys().size() > 0:
				var required_placements = "Please place down "
				for building in GameStats.restrictions.keys():
					required_placements += (str(GameStats.restrictions[building]) + " more " + pluralize(GameStats.restrictions[building], GameStats.buildings_dict[building].name) + ", ") # TODO: get the actual building name instead of printing out the building id
				required_placements.erase(required_placements.length() - 2, 2)
				get_parent().get_parent().get_node("UILayer/TextBox").text = required_placements + "."
		else:
			game.on_next_turn()
			update_turn_display()
			# game.place_building(350, 50)
			#if GameStats.turn % 5 == 0:
			#	grid.set_grid_size(GameStats.grid_size + 6)
			populate_sidebar_correctly()

"""
	Called when the Undo button is clicked
"""
func _on_Undo_gui_input(event):
	if (event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT):
		print("Undo was clicked!")
		GameStats.logger.log_action_with_no_level(Logger.Actions.UndoClicked)

"""
	Called when the Upgrades button is clicked
"""
func _on_Upgrades_gui_input(event):
	if (event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT):
		GameStats.logger.log_action_with_no_level(Logger.Actions.UpgradeMenuClicked)
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
	
	if GameStats.restrictions.keys().size() == 0:
		toggle_next_month_button(true)

func pluralize(quantity : int, word : String) -> String:
	if quantity == 1:
		return word
	else:
		return word + "s"
		
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
		$Upgrades/Label.set("custom_colors/font_color", Color("#FFFFFF"))
	else:
		$Upgrades/Label.set("custom_colors/font_color", Color("#808080"))
		

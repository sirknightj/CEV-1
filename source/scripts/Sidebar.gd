extends Control
class_name SidebarX

onready var grid : Node2D = $"../../Grid"

var game : Game # The node representing the game
var Turn_Count_Text # The node holding the turn count text

var show_resources : Dictionary = {}

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
		show_resources[resource] = true
	
	for building in GameStats.buildings_dict:
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
			entry.add_child(_building)
			
			$ScrollContainer/BuildingEntries.add_child(entry)
			_building.set_physics_process(false)
			_building.force_set(Vector2(1050, 360), 0.0)
			_building.connect("building_grabbed", self, "_on_Building_building_grabbed", [_building])

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
	if (event is InputEventMouseButton && event.pressed && event.button_index == BUTTON_LEFT):
		game.on_next_turn()
		update_turn_display()
		game.place_building(350, 50)
		if GameStats.turn % 5 == 0:
			grid.set_grid_size(GameStats.grid_size + 6)

"""
	Called when the Undo button is clicked
"""
func _on_Undo_gui_input(event):
	if (event is InputEventMouseButton && event.pressed && event.button_index == BUTTON_LEFT):
		print("Undo was clicked!")
		GameStats.logger.log_action_with_no_level(Logger.Actions.UndoClicked)

"""
	Called when the Upgrades button is clicked
"""
func _on_Upgrades_gui_input(event):
	if (event is InputEventMouseButton && event.pressed && event.button_index == BUTTON_LEFT):
		GameStats.logger.log_action_with_no_level(Logger.Actions.UpgradeMenuClicked)
		get_tree().change_scene("res://scenes/TechTreeScene.tscn")

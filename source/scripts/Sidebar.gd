extends Control
class_name SidebarX

onready var grid : Node2D = $"../../Grid"

var game : Game # The node representing the game
var Turn_Count_Text # The node holding the turn count text

var show_resources : Dictionary = {}

onready var building_scene = preload("res://scenes/Building.tscn")

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
			var building_name_label : Label = Label.new()
			building_name_label.text = GameStats.buildings_dict[building].name
			entry.add_child(building_name_label)
			
			# Attempting to put a building inside of the HBox
			var _building = building_scene.instance()
			_building.shape = building_stats.shape
			_building.building_effects = building_stats.effects
			_building.building_cost = building_stats.cost
			_building.building_id = building
			_building.texture = GameData.BUILDING_TO_TEXTURE[building]
			entry.add_child(_building)

			var building_cost_label : Label = Label.new()
			var cost_text : String = "TODO: Cost"
			entry.add_child(building_cost_label)
			
			$ScrollContainer/BuildingEntries.add_child(entry)
			#_building.set_next_pos(_building.snapped(Vector2(0, 50)))
			_building.connect("building_grabbed", self, "_on_Building_building_grabbed", [_building])
			_building.connect("building_released", self, "_on_Building_building_released", [_building])
			break

func _on_Building_building_grabbed(building : Building):
	building.get_parent().remove_child(building)
	get_tree().current_scene.add_child(building)
	building.force_update()

func _on_Building_building_released(building : Building):
	if not building.purchased:
		building.get_parent().remove_child(building)
		self.add_child(building)

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

"""
	Called when the Upgrades button is clicked
"""
func _on_Upgrades_gui_input(event):
	if (event is InputEventMouseButton && event.pressed && event.button_index == BUTTON_LEFT):
		get_tree().change_scene("res://scenes/TechTreeScene.tscn")

extends Control
class_name SidebarX

onready var grid : Node2D = $"../../Grid"

var game : Game # The node representing the game
var Turn_Count_Text # The node holding the turn count text

var show_resources : Dictionary = {}
var ignore_next_month : bool # default = clickable
var ignore_upgrades_button : bool  # default = unclickable

onready var building_scene = preload("res://scenes/Building.tscn")
onready var row_scene = preload("res://scenes/BuildingRow.tscn")

var ending_shown_on_this_turn: bool  # set to true after ending shown for the first time so it isn't shown again

func _setup_control_element(control : Control):
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE

# Called when the node enters the scene tree for the first time.
func _ready():
	ignore_next_month = false
	ignore_upgrades_button = true
	ending_shown_on_this_turn = false
	game = get_parent().get_parent()
	Turn_Count_Text = get_node("TurnCount")
	$NextMonth/Label.text = "Next Month"

func start_game():
	for resource in GameData.ResourceType.values():
		show_resources[resource] = false

	populate_sidebar_correctly()
	update_turn_display()

func show_all():
	GameStats.shown_resources = GameData.ResourceType.values()
	show_resources()
	toggle_next_month_button(true)
	$NextMonth.show()
	toggle_upgrades_button(true)
	GameStats.restrictions.clear()
	GameStats.selling_enabled = true
	GameStats.buildings_unlocked.append_array([GameData.BuildingType.WATER1, GameData.BuildingType.FOOD1, GameData.BuildingType.OXY1, GameData.BuildingType.METAL1, GameData.BuildingType.ELEC1, GameData.BuildingType.SCI1])
	populate_sidebar_correctly()
	update_turn_display()

func cheat():
	var cheat_alot = true
	GameStats.turn = max(GameStats.turn, 20)
	GameStats.buildings_unlocked = GameData.BuildingType.values()
	if cheat_alot:
		GameStats.resources.set_reserves({
			GameData.ResourceType.FOOD: 5000.0,
			GameData.ResourceType.OXYGEN: 5000.0,
			GameData.ResourceType.WATER: 5000.0,
			GameData.ResourceType.METAL: 5000.0,
			GameData.ResourceType.ELECTRICITY: 5000.0,
			GameData.ResourceType.SCIENCE: 5000.0,
			GameData.ResourceType.PEOPLE: 1.0
		})
	else:
		GameStats.resources.set_reserves({
			GameData.ResourceType.FOOD: 100,
			GameData.ResourceType.OXYGEN: 700,
			GameData.ResourceType.WATER: 100,
			GameData.ResourceType.METAL: 550,
			GameData.ResourceType.ELECTRICITY: 100,
			GameData.ResourceType.SCIENCE: 5000.0,
			GameData.ResourceType.PEOPLE: 1.0
		})
	GameStats.game.on_next_turn()
	show_all()
	GameStats.game.on_next_turn()

func check_buttons() -> void:
	var current = get_parent().get_parent().get_node("UpperLayer/TutorialText").bbcode_text.strip_edges()
	var not_enough_energy_message : String = "You don't have enough [color=%s]energy[/color] to keep your buildings running! You'll need to sell some buildings or generate more [color=%s]energy[/color]!" % [GameData.get_resource_color_as_hex(GameData.ResourceType.ELECTRICITY), GameData.get_resource_color_as_hex(GameData.ResourceType.ELECTRICITY)]
	var not_enough_metal_message : String = "You don't have enough [color=%s]metal[/color] to keep your buildings running! You'll need to sell some buildings or generate more [color=%s]metal[/color]!" % [GameData.get_resource_color_as_hex(GameData.ResourceType.METAL), GameData.get_resource_color_as_hex(GameData.ResourceType.METAL)]
	var ppl = GameStats.resources.get_reserve(GameData.ResourceType.PEOPLE)
	if not has_enough_electricity() and GameStats.turn >= 12 and not ppl < 1:
		if not current.ends_with(not_enough_energy_message):
			current += "\n" + not_enough_energy_message
		toggle_next_month_button(false)
	elif not has_enough_metal() and GameStats.turn >= 12 and not current.ends_with("more metal!") and not ppl < 1:
		current = current.strip_edges().trim_suffix(not_enough_energy_message).strip_edges()
		if not current.ends_with(not_enough_metal_message):
			current += "\n" + not_enough_metal_message
		toggle_next_month_button(false)
	elif GameStats.turn >= 12:
		current = current.strip_edges().trim_suffix(not_enough_energy_message).strip_edges()
		current = current.strip_edges().trim_suffix(not_enough_metal_message).strip_edges()
		toggle_next_month_button(true)
	if current:
		get_parent().get_parent().get_node("UpperLayer/TutorialText").bbcode_text = current.strip_edges()

func repopulate_sidebar():
	populate_sidebar_correctly()

func populate_sidebar_correctly() -> void:
	check_buttons()
	var ppl = GameStats.resources.get_reserve(GameData.ResourceType.PEOPLE)
	if GameStats.colonist_death_threshold <= GameStats.dead or ppl < 1:
		if ending_shown_on_this_turn:
			return
		if ppl < 1:
			GameStats.resources.set_reserve(GameData.ResourceType.PEOPLE, 0)
		if GameStats.resources.get_reserve(GameData.ResourceType.FOOD) < 0:
			GameStats.resources.set_reserve(GameData.ResourceType.FOOD, 0)
		if GameStats.resources.get_reserve(GameData.ResourceType.OXYGEN) < 0:
			GameStats.resources.set_reserve(GameData.ResourceType.OXYGEN, 0)
		if GameStats.resources.get_reserve(GameData.ResourceType.WATER) < 0:
			GameStats.resources.set_reserve(GameData.ResourceType.WATER, 0)
		GameStats.show_win_lose_screen(false)
		GameStats.game.update_all()
		
		$NextMonth/Label.text = "Restart"
		toggle_next_month_button(true)
		
		# Lock all the buildings
		for _building in GameStats.game.get_buildings():
			if _building.purchased:
				_building.locked = true
	
	var turn = GameStats.turn
	if turn <= 2:
		GameStats.buildings_unlocked.append(GameData.BuildingType.WATER1)
		GameStats.shown_resources = [GameData.ResourceType.WATER]
		show_resources()
	elif turn <= 5:
		GameStats.buildings_unlocked.append(GameData.BuildingType.FOOD1)
		populate_sidebar_with_buildings([GameData.BuildingType.WATER1, GameData.BuildingType.FOOD1])
		GameStats.shown_resources = [GameData.ResourceType.WATER, GameData.ResourceType.FOOD]
		show_resources()
	elif turn <= 8:
		GameStats.buildings_unlocked.append_array([GameData.BuildingType.OXY1, GameData.BuildingType.METAL1])
		GameStats.shown_resources = [GameData.ResourceType.WATER, GameData.ResourceType.FOOD, GameData.ResourceType.OXYGEN, GameData.ResourceType.METAL]
		show_resources()
	elif turn <= 9:
		GameStats.buildings_unlocked.append(GameData.BuildingType.ELEC1)
		GameStats.shown_resources = [GameData.ResourceType.WATER, GameData.ResourceType.FOOD, GameData.ResourceType.OXYGEN, GameData.ResourceType.METAL, GameData.ResourceType.ELECTRICITY]
		show_resources()
	elif turn <= 10:
		GameStats.buildings_unlocked.append(GameData.BuildingType.SCI1)
		GameStats.shown_resources = [GameData.ResourceType.WATER, GameData.ResourceType.FOOD, GameData.ResourceType.OXYGEN, GameData.ResourceType.METAL, GameData.ResourceType.ELECTRICITY, GameData.ResourceType.SCIENCE]
		show_resources()
	populate_sidebar_with_buildings(GameStats.buildings_unlocked)

func show_resources() -> void:
	for resource in GameData.ResourceType.values():
		toggle_visibility(resource, GameStats.shown_resources.has(resource))

func toggle_visibility(resource : int, hide : bool) -> void:
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
	var entry_container = $ScrollContainer/BuildingEntries
	
	# Remove any entries that are not in buildings
	for child in entry_container.get_children():
		if not child.get_meta("building_id") in buildings.keys():
			entry_container.remove_child(child)
	
	var scroll_offset = $ScrollContainer.get_v_scrollbar().value
	for building in buildings:
		var building_stats = GameStats.buildings_dict[building]

		if building_stats.name == "City center":
			continue

		var entry_name = "BuildingRow" + str(building)
		var entry
		if not entry_container.has_node(entry_name): # not in entry list
			entry = row_scene.instance()
			entry.set_name(entry_name)
			entry.set_meta("building_name", building_stats.name)
			entry.set_meta("building_id", building)
			entry_container.add_child(entry)
		else:
			entry = entry_container.get_node(entry_name)

		entry.get_node("BuildingName").text = GameStats.buildings_dict[building].name

		# building icon
		var building_exists = entry.get_child_count() >= 4
		var _building = entry.get_children().back() if building_exists else building_scene.instance()
		if not building_exists:
			# made a new node
			_building.shape = building_stats.shape
			_building.building_effects = building_stats.effects
			_building.building_cost = building_stats.cost
			_building.building_id = building
			_building.texture = GameData.BUILDING_TO_TEXTURE[building]

		# vertically center building with row
		var building_pos = Vector2(1035, $ScrollContainer.rect_position.y - scroll_offset)
		building_pos.y += entry.rect_position.y + entry.rect_min_size.y / 2 - _building.shape.size() * GameData.SQUARE_SIZE / 2
		_building.building_pos = building_pos
		_building.set_locked(not available(building) or not GameStats.resources.enough_resources(building_stats.cost))
		if not building_exists:
			entry.add_child(_building)
			_building.set_physics_process(false)
			_building.force_set(building_pos, 0.0, false)
			_building.connect("building_grabbed", self, "_on_Building_building_grabbed")
			_building.connect("building_destroy", self, "_on_Building_building_destroy")

		# set cost and effect texts
		var cost_text = _building.get_costs_as_bbcode()
		var effects_text = _building.get_effects_as_bbcode()
		entry.get_node("CostContainer/Text").bbcode_text = cost_text
		entry.get_node("EffectsContainer/Text").bbcode_text = effects_text

"""
	Returns true if the building is available
	false if not
"""
func available(building) -> bool:
	if GameData.BuildingType.END1 == building and GameStats.buildings_owned.has(building) and GameStats.buildings_owned[building] == 1:
		return false
	return (GameStats.restrictions.empty() or GameStats.restrictions.has(building)) and not (not GameStats.win_status and not GameStats.is_playing)

func _on_Building_building_destroy(_building):
	repopulate_sidebar()

func _on_Building_building_grabbed(building : Building):
	building.connect("building_released", self, "_on_Building_building_released")
	var diff = get_global_mouse_position() - building._main.global_position
	building.get_parent().remove_child(building)
	get_tree().current_scene.add_child(building)
	building.force_update()
	var mouse = get_tree().current_scene.get_global_mouse_position()
	building.force_set(mouse - diff, 0.0, false)
	building.set_physics_process(true)

func _on_Building_building_released(building : Building):
	building.disconnect("building_released", self, "_on_Building_building_released")
	if building.purchased:
		building.disconnect("building_grabbed", self, "_on_Building_building_grabbed")
		if GameStats.buildings_owned.has(building.building_id):
			GameStats.buildings_owned[building.building_id] += 1
		else:
			GameStats.buildings_owned[building.building_id] = 1
		placed_building(building.building_id)
		if building.building_id == GameData.BuildingType.END1:
			$NextMonth/Label.text = "Freeplay"
			GameStats.show_win_lose_screen(true)
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
		ending_shown_on_this_turn = false
		GameStats.logger.log_level_action(Logger.Actions.NextMonthClicked)
		
		if $NextMonth/Label.text == "Restart":
			GameStats.logger.log_level_action(Logger.Actions.RestartClicked)
			GameStats.reset_game(true)
			return
		
		if $NextMonth/Label.text == "Freeplay":
			$NextMonth/Label.text = "Next Month"
		
		# print("People that will die next turn: " + str(how_many_people_will_die_next_turn()))
		if ignore_next_month:
			if GameStats.restrictions.keys().size() > 0:
				var required_placements = "Please build "
				var num_restrictions = GameStats.restrictions.keys().size()
				var i = num_restrictions
				for building in GameStats.restrictions.keys():
					i -= 1
					if i == 0 and num_restrictions > 1:
						if num_restrictions == 2:
							required_placements.erase(required_placements.length() - 2, 2)
							required_placements += " "
						required_placements += "and "
					var quantity = GameStats.restrictions[building]
					if quantity == 1:
						required_placements += "a "
					else:
						required_placements += str(quantity) + " more "
					required_placements += GameStats.buildings_dict[building].format_str(quantity) + ", "
				required_placements.erase(required_placements.length() - 2, 2)
				get_parent().get_parent().get_node("UpperLayer/TutorialText").bbcode_text = required_placements + "."
			elif GameStats.turn == 10:
				get_parent().get_parent().get_node("UpperLayer/TutorialText").bbcode_text = "Please check out the [color=%s]Upgrades[/color] menu!" % GameData.get_resource_color_as_hex(GameData.ResourceType.SCIENCE)
		else:
			game.on_next_turn()
			$Graph.reset_for_next_turn()
			update_turn_display()
			populate_sidebar_correctly()

"""
	Called when the Stats button is clicked
"""
func _on_Stats_gui_input(event):
	if (event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT):
		print("Stats was clicked!")
		GameStats.logger.log_level_action(Logger.Actions.StatsClicked)

"""
	Called when the Upgrades button is clicked
"""
func _on_Upgrades_gui_input(event):
	if (event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT):
		GameStats.logger.log_level_action(Logger.Actions.UpgradeMenuClicked)
		if GameStats.turn == 10:
			get_parent().get_parent().get_node("UpperLayer/TutorialText").bbcode_text = get_parent().get_parent().get_node("UpperLayer/TutorialText").bbcode_text.trim_prefix("Your city has generated enough [color=%s]science[/color] for an upgrade! Spend [color=%s]science[/color] to unlock new buildings and increase building efficiency." % [GameData.get_resource_color_as_hex(GameData.ResourceType.SCIENCE), GameData.get_resource_color_as_hex(GameData.ResourceType.SCIENCE)]).strip_edges()
			toggle_next_month_button(true)
		if not ignore_upgrades_button:
			$Upgrades/AnimationPlayer.stop()
			$Upgrades/AnimationPlayer.seek(0, true)
			$CanvasLayer/TechTree.show()

func scroll_down():
	var tween : Tween = get_node("Tween")
	var current : float = $ScrollContainer.get_v_scrollbar().value
	var target : float = $ScrollContainer.get_v_scrollbar().max_value
	if not tween.is_active() and current != target:
		var duration : float = 1.0
		tween.interpolate_property($ScrollContainer.get_v_scrollbar(), "value",
									current, target, 1.5, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
		tween.start()


func on_ending() -> void:
	if ending_shown_on_this_turn:
		return
	GameStats.game.update_all()
	ending_shown_on_this_turn = true
	GameStats.just_won = 1
	$CanvasLayer/EndScreen.set_condition(GameStats.win_status)
	$CanvasLayer/EndScreen.show()

	$CanvasLayer/EndScreen.connect("on_close_clicked", self, "on_endingscreen_close")

func on_endingscreen_close() -> void:
	GameStats.game.update_all()
	get_parent().get_parent().get_node("UpperLayer/TutorialText").bbcode_text = ""
	$CanvasLayer/EndScreen.hide()

"""
	Tells the restrictions that the player has placed a building
"""
func placed_building(building : int):
	# print("placed_building was called")
	if GameStats.restrictions.has(building) and GameStats.restrictions[building] > 1:
		GameStats.restrictions[building] -= 1
	elif GameStats.restrictions.has(building) and GameStats.restrictions[building] == 1:
		GameStats.restrictions.erase(building)
	
	if GameStats.restrictions.keys().size() == 0 and GameStats.turn != 10:
		toggle_next_month_button(true)
	
	if GameStats.turn == 1:
		get_parent().get_parent().get_node("UpperLayer/TutorialText").bbcode_text = "Great work! Advance to the next month."
		$NextMonth.show()
	check_buttons()

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
	Returns true if we have enough metal for the next turn
	false if we'll go negative
"""
func has_enough_metal() -> bool:
	var metal_over : float = GameStats.resources.get_reserve(GameData.ResourceType.METAL) + GameStats.resources.get_income(GameData.ResourceType.METAL) - GameStats.resources.get_expense(GameData.ResourceType.METAL)
	return metal_over >= 0

"""
	Returns how much electricity you'll overdraw next turn
	0 if your electricity reserves are fine
"""
func how_much_electricity_over() -> float:
	var electricity_over : float = GameStats.resources.get_reserve(GameData.ResourceType.ELECTRICITY) + GameStats.resources.get_income(GameData.ResourceType.ELECTRICITY) - GameStats.resources.get_expense(GameData.ResourceType.ELECTRICITY)
	# print(electricity_over)
	if electricity_over < 0:
		return -electricity_over
	else:
		return 0.0

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
		$NextMonth.color = Color("#5421d1")
		$NextMonth/Label.set("custom_colors/font_color", Color("#FFFFFF"))
	else:
		$NextMonth.color = Color("#404040")
		$NextMonth/Label.set("custom_colors/font_color", Color("#AAAAAA"))

"""
	Lets the "upgrades" button be clicked
	_clickable: true if the button is allowed to be clicked, false otherwise
"""
func toggle_upgrades_button(_clickable) -> void:
	ignore_upgrades_button = not _clickable
	if _clickable:
		$Upgrades.show()
		
		$Upgrades/AnimationPlayer.play("Shake")
	else:
		$Upgrades.hide()

const SCROLL_SPEED = 13
func _unhandled_input(event : InputEvent):
	# if GameStats.turn < 20:
	#	cheat()
	if event.is_action_pressed("debug"):
		cheat()
	elif event is InputEventMouseButton:
		if event.button_index == BUTTON_WHEEL_DOWN:
			$ScrollContainer.scroll_vertical += SCROLL_SPEED
		elif event.button_index == BUTTON_WHEEL_UP:
			$ScrollContainer.scroll_vertical -= SCROLL_SPEED

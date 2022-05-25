extends Control

const RESOURCE_TYPE_TO_STRING: Dictionary = {
	GameData.ResourceType.WATER: "Water",
	GameData.ResourceType.FOOD: "Food",
	GameData.ResourceType.OXYGEN: "Oxygen",
	GameData.ResourceType.ELECTRICITY: "Energy",
	GameData.ResourceType.METAL: "Metal",
}

var last_turn_animated = -1
var resources_saved_hash: int = -1

const ANIMATION_SPEED = 2

var resource_dict : Dictionary
var resources_saved: GameObjs.Resources

var tooltip_control : Control

var hover_durations : Dictionary = {}  # resource_type -> int (how long the bar was hovered over this turn)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for type in RESOURCE_TYPE_TO_STRING.keys():
		_set_color(type)

	reset_for_next_turn()

func reset_for_next_turn() -> void:
	for type in RESOURCE_TYPE_TO_STRING.keys():
		hover_durations[type] = 0
	if tooltip_control:
		tooltip_control.hide()

func _set_color(type: int) -> void:
	assert(GameData.is_resource_type(type))
	var node_name = RESOURCE_TYPE_TO_STRING.get(type)
	var color = GameData.COLORS.get(type)
	var node = get_node("HBoxContainer/" + node_name)
	node.set_color_and_name(color, node_name)
	
	node.get_node("BackgroundHoverBar").connect("mouse_entered", self, "_on_hover_on", [type])
	node.get_node("BackgroundHoverBar").connect("mouse_exited", self, "_on_hover_off", [type])

class BuildingEffectsSorter:
	static func sort_descending(a, b):
		return a[0] > b[0]

"""
	Sets the hover tooltips
"""
func _on_hover_on(type: int) -> void:
	assert(GameData.is_resource_type(type))

	if not resource_dict:
		return
	
	tooltip_control = get_parent().get_parent().get_parent().get_node("UpperLayer/GraphTooltip")
	
	if not tooltip_control:
		return
	
	hover_durations[type] -= OS.get_ticks_msec()
	var node_name = RESOURCE_TYPE_TO_STRING.get(type)
	
	var production_texts = []
	var consumption_texts = []
	
	var total_production = 0
	var total_consumption = 0
	
	# sort by absolute value decreasing
	for building in resource_dict[type]:
		var val = resource_dict[type][building]
		if building == GameData.BuildingType.CENTER:
			building = "Colonists"
		else:
			building = GameStats.buildings_dict[building].name
		if val > 0:
			total_production += val
			production_texts.append([val, "\n" + building + ": " + str(val)])
		elif val < 0:
			val *= -1
			total_consumption += val
			consumption_texts.append([val, "\n" + building + ": " + str(val)])
	
	var production_text = "Production: " + str(total_production)
	production_texts.sort_custom(BuildingEffectsSorter, "sort_descending")
	for t in production_texts:
		production_text += t[1]

	var consumption_text = "Consumption: " + str(total_consumption)
	consumption_texts.sort_custom(BuildingEffectsSorter, "sort_descending")
	for t in consumption_texts:
		consumption_text += t[1]
	
	var reserve_text = "Reserve: %s\n\n%s per month" % [resources_saved.get_reserve(type), _to_str(total_production - total_consumption, true)]
	
	tooltip_control.get_node("RectLeft/Text").text = production_text + "\n\n" + consumption_text
	tooltip_control.get_node("RectRight/Text").text = reserve_text
	tooltip_control.show()
	
	tooltip_control.get_node("RectLeft").rect_size.y = tooltip_control.get_node("RectLeft/Text").rect_size.y + 20
	tooltip_control.get_node("RectLeft").rect_size.x = tooltip_control.get_node("RectLeft/Text").rect_size.x + 20
	tooltip_control.get_node("RectRight").rect_size.y = tooltip_control.get_node("RectRight/Text").rect_size.y + 20
	tooltip_control.get_node("RectRight").rect_size.x = tooltip_control.get_node("RectRight/Text").rect_size.x + 20
	
	var graph_container = get_node("HBoxContainer")
	var graph_bar = graph_container.get_node(node_name)
	var graph_bar_bar = graph_bar.get_node("Line2D")
	tooltip_control.get_node("RectRight").rect_position.x = graph_container.rect_position.x + graph_bar.rect_position.x + graph_bar_bar.position.x + graph_bar_bar.width / 2
	
	tooltip_control.get_node("RectLeft").rect_position.x = graph_container.rect_position.x + graph_bar.rect_position.x - tooltip_control.get_node("RectLeft").rect_size.x + graph_bar_bar.position.x - graph_bar_bar.width / 2

func _on_hover_off(type: int) -> void:
	assert(GameData.is_resource_type(type))
	hover_durations[type] += OS.get_ticks_msec()
	if tooltip_control:
		tooltip_control.hide()

func _to_str(number: float, include_plus: bool, people : float = 0.0) -> String:
	var prefix = "+" if number >= 0 and include_plus else ""
	if not people:
		return prefix + str(floor(number))
	else:
		return prefix + str(max(floor(people + number) - floor(people), 0))

func _animate_store_Science(val: float) -> void:
	$ScienceStore.text = _to_str(val, false)
func _animate_diff_Science(val: float) -> void:
	$ScienceDiff.text = _to_str(val, true) + " / mo"
func _animate_store_Colonists(val: float) -> void:
	$ColonistsStore.text = _to_str(val, false)

func are_resources_same(resources: GameObjs.Resources) -> bool:
	if resources and resources_saved:
		return resources.hash() == resources_saved_hash
	return false

func update_graph(turn: int, resources: GameObjs.Resources, new_resource_dict : Dictionary) -> void:
	var is_next_turn_update = (turn != last_turn_animated)
	last_turn_animated = turn

	resource_dict = new_resource_dict
	if are_resources_same(resources) and not is_next_turn_update:
		# no need to animate anything
		return
	resources_saved = resources
	resources_saved_hash = resources.hash()
	
	print("update_graph with next_turn=", is_next_turn_update)

	for type in RESOURCE_TYPE_TO_STRING.keys():
		var node_name = RESOURCE_TYPE_TO_STRING.get(type)
		var graph_bar = get_node("HBoxContainer/" + node_name)
		
		# set text
		var production = resources.get_income(type)
		var consumption = resources.get_expense(type)
		var reserve = resources.get_reserve(type)

		graph_bar.update_bar(is_next_turn_update, production, consumption, reserve)
	
	var tween = $Tween
	# set science and people labels
	var initial_science_store = $ScienceStore.text.to_float()
	tween.interpolate_method(self, "_animate_store_Science", initial_science_store, resources.get_reserve(GameData.ResourceType.SCIENCE), ANIMATION_SPEED / 2, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	
	var initial_science_diff = $ScienceDiff.text.trim_suffix(" / mo").to_float()
	tween.interpolate_method(self, "_animate_diff_Science", initial_science_diff, resources.get_income(GameData.ResourceType.SCIENCE), ANIMATION_SPEED / 2, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	
	var initial_colonists_store = $ColonistsStore.text.to_float()
	tween.interpolate_method(self, "_animate_store_Colonists", initial_colonists_store, resources.get_reserve(GameData.ResourceType.PEOPLE), ANIMATION_SPEED / 2, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	
	$ColonistsDiff.text = _to_str(resources.get_income(GameData.ResourceType.PEOPLE), true, resources.get_reserve(GameData.ResourceType.PEOPLE)) + " / mo"
	$ColonistsDead.text = _to_str(GameStats.dead, false) + " dead"
	
	tween.start()


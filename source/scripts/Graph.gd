extends Control

const MAX_BAR_HEIGHT = 210

const RESOURCE_TYPE_TO_STRING: Dictionary = {
	GameData.ResourceType.WATER: "Water",
	GameData.ResourceType.FOOD: "Food",
	GameData.ResourceType.OXYGEN: "Oxygen",
	GameData.ResourceType.ELECTRICITY: "Energy",
	GameData.ResourceType.METAL: "Metal",
}

const ANIMATION_SPEED = 0.5

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
	node.get_node("Bar").color = color
	node.get_node("ResourceName").text = node_name
	node.get_node("ResourceName").add_color_override("font_color", color)
	
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
		print("No tooltip control")
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
	var graph_bar_bar = graph_bar.get_node("Bar")
	tooltip_control.get_node("RectRight").rect_position.x = graph_container.rect_position.x + graph_bar.rect_position.x + graph_bar_bar.rect_position.x + graph_bar_bar.rect_size.x
	tooltip_control.get_node("RectRight").rect_position.y = graph_bar.rect_position.y
	
	tooltip_control.get_node("RectLeft").rect_position.x = graph_container.rect_position.x + graph_bar.rect_position.x + graph_bar_bar.rect_position.x - tooltip_control.get_node("RectLeft").rect_size.x
	tooltip_control.get_node("RectLeft").rect_position.y = graph_bar.rect_position.y

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

func _animate_store(name: String, val: float) -> void:
	get_node("HBoxContainer/" + name + "/TextReserve").text = _to_str(val, false)

func _animate_diff(name: String, val: float) -> void:
	get_node("HBoxContainer/" + name + "/TextDelta").text = _to_str(val, true)

func _animate_store_Water(val: float) -> void:
	_animate_store("Water", val)
func _animate_diff_Water(val: float) -> void:
	_animate_diff("Water", val)
func _animate_store_Food(val: float) -> void:
	_animate_store("Food", val)
func _animate_diff_Food(val: float) -> void:
	_animate_diff("Food", val)
func _animate_store_Oxygen(val: float) -> void:
	_animate_store("Oxygen", val)
func _animate_diff_Oxygen(val: float) -> void:
	_animate_diff("Oxygen", val)
func _animate_store_Energy(val: float) -> void:
	_animate_store("Energy", val)
func _animate_diff_Energy(val: float) -> void:
	_animate_diff("Energy", val)
func _animate_store_Metal(val: float) -> void:
	_animate_store("Metal", val)
func _animate_diff_Metal(val: float) -> void:
	_animate_diff("Metal", val)
func _animate_store_Science(val: float) -> void:
	$ScienceStore.text = _to_str(val, false)
func _animate_diff_Science(val: float) -> void:
	$ScienceDiff.text = _to_str(val, true) + " / mo"
func _animate_store_Colonists(val: float) -> void:
	$ColonistsStore.text = _to_str(val, false)

func _parse_str(val: String) -> float:
	return val.trim_prefix("+").to_float()

func update_graph(resources: GameObjs.Resources, new_resource_dict : Dictionary) -> void:
	resource_dict = new_resource_dict
	resources_saved = resources
	for type in RESOURCE_TYPE_TO_STRING.keys():
		var node_name = RESOURCE_TYPE_TO_STRING.get(type)
		var graph_bar = get_node("HBoxContainer/" + node_name)
		var tween = graph_bar.get_node("Tween")
		var bar = graph_bar.get_node("Bar")

		# set text
		var production = resources.get_income(type)
		var consumption = resources.get_expense(type)
		var reserve = resources.get_reserve(type)
		
		var resource_delta = production - consumption
		var next_reserve = reserve + resource_delta
		
		var max_bar_height = MAX_BAR_HEIGHT + (0 if (next_reserve > 0 and reserve > 0) else -20)
		
		var initial_store = _parse_str(graph_bar.get_node("TextReserve").text)
		tween.interpolate_method(self, "_animate_store_" + node_name, initial_store, reserve, ANIMATION_SPEED, Tween.TRANS_LINEAR, Tween.EASE_OUT)
		var initial_diff = _parse_str(graph_bar.get_node("TextDelta").text)
		tween.interpolate_method(self, "_animate_diff_" + node_name, initial_diff, production - consumption, ANIMATION_SPEED, Tween.TRANS_LINEAR, Tween.EASE_OUT)

		var bar_ratio_denominator = reserve - next_reserve if next_reserve < 0 else next_reserve
		var bar_ratio = reserve / max(1, bar_ratio_denominator)

		bar_ratio = max(0.01, min(1, bar_ratio))

		var bar_y = 0 if next_reserve < 0 else (max_bar_height * (1 - bar_ratio))

		tween.interpolate_property(bar, "rect_size:y", bar.rect_size.y, max_bar_height * bar_ratio, ANIMATION_SPEED, Tween.TRANS_EXPO, Tween.EASE_OUT)
		bar.set_meta("actual_height", max_bar_height * bar_ratio)
		tween.interpolate_property(bar, "rect_position:y", bar.rect_position.y, bar_y, ANIMATION_SPEED, Tween.TRANS_EXPO, Tween.EASE_OUT)
		
		# move reference line and diff label
		var reference_y = 0

		if next_reserve >= reserve:
			reference_y = 0
		elif next_reserve < 0:
			reference_y = max_bar_height
		else:
			reference_y = max_bar_height * (1 - next_reserve / reserve)

		var ref_line = graph_bar.get_node("ReferenceLine")
		tween.interpolate_property(ref_line, "rect_position:y", ref_line.rect_position.y, reference_y, ANIMATION_SPEED, Tween.TRANS_EXPO, Tween.EASE_OUT)
		ref_line.set_meta("actual_y", reference_y)
		
		var diff_text = graph_bar.get_node("TextDelta")
		tween.interpolate_property(diff_text, "rect_position:y", diff_text.rect_position.y, reference_y + (9 if resource_delta < 0 else -20), ANIMATION_SPEED, Tween.TRANS_EXPO, Tween.EASE_OUT)
		diff_text.modulate = Color("#f00") if next_reserve < 0 else Color("#fff")
		
		var triangle = graph_bar.get_node("Arrow/Triangle")
		var arrow_line = graph_bar.get_node("Arrow/Line")
		
		tween.interpolate_property(triangle, "position:y", triangle.position.y, reference_y + (4 if next_reserve > reserve else -1), ANIMATION_SPEED, Tween.TRANS_EXPO, Tween.EASE_OUT)
		tween.interpolate_property(triangle, "scale:y", triangle.scale.y, sign(resource_delta), ANIMATION_SPEED, Tween.TRANS_EXPO, Tween.EASE_OUT)
		
		var line_top = 0
		var line_bottom = 0
		if next_reserve < 0:
			line_top = 0
			line_bottom = max_bar_height - 5
		elif next_reserve > reserve:
			line_top = 5
			line_bottom = bar_y
		else:
			line_top = 0
			line_bottom = reference_y - 5
		
		tween.interpolate_property(arrow_line, "rect_position:y", arrow_line.rect_position.y, line_top, ANIMATION_SPEED, Tween.TRANS_EXPO, Tween.EASE_OUT)
		tween.interpolate_property(arrow_line, "rect_size:y", arrow_line.rect_size.y, line_bottom - line_top, ANIMATION_SPEED, Tween.TRANS_EXPO, Tween.EASE_OUT)
		
		var reserve_text = graph_bar.get_node("TextReserve")
		var reserve_y = 0
		if bar_y < line_top - 5 or (bar_y == line_top and resource_delta < 0):
			# line is below bar
			reserve_y = line_top - 20
		else:
			reserve_y = bar_y + 9
		
		if resource_delta == 0 or abs(line_top - line_bottom) < 5:
			graph_bar.get_node("Arrow").hide()
		else:
			graph_bar.get_node("Arrow").show()
		
		tween.interpolate_property(reserve_text, "rect_position:y", reserve_text.rect_position.y, reserve_y, ANIMATION_SPEED, Tween.TRANS_EXPO, Tween.EASE_OUT)
		
		tween.start()
	
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


extends Control

const MAX_BAR_HEIGHT = 190

const RESOURCE_TYPE_TO_STRING: Dictionary = {
	GameData.ResourceType.WATER: "Water",
	GameData.ResourceType.FOOD: "Food",
	GameData.ResourceType.OXYGEN: "Oxygen",
	GameData.ResourceType.ELECTRICITY: "Energy",
	GameData.ResourceType.METAL: "Metal",
}

var resource_dict : Dictionary

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for type in RESOURCE_TYPE_TO_STRING.keys():
		_set_color(type)
	_on_hover_off()

func _set_color(type: int) -> void:
	assert(GameData.is_resource_type(type))
	var node_name = RESOURCE_TYPE_TO_STRING.get(type)
	var color = GameData.COLORS.get(type)
	var node = get_node("HBoxContainer/" + node_name)
	node.get_node("Bar").color = color
	node.get_node("ResourceName").text = node_name
	node.get_node("ResourceStore").add_color_override("font_color", color)
	
	node.get_node("BackgroundHoverBar").connect("mouse_entered", self, "_on_hover_on", [type])
	node.get_node("BackgroundHoverBar").connect("mouse_exited", self, "_on_hover_off")

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
			total_consumption += -val
			consumption_texts.append([-val, "\n" + building + ": " + str(val)])

	var production_text = "Production: " + str(total_production)
	production_texts.sort_custom(BuildingEffectsSorter, "sort_descending")
	for t in production_texts:
		production_text += t[1]
	var consumption_text = "Consumption: " + str(total_consumption)
	consumption_texts.sort_custom(BuildingEffectsSorter, "sort_descending")
	for t in consumption_texts:
		consumption_text += t[1]

	$ProductionRect/ProductionLabel.text = production_text
	$ConsumptionRect/ConsumptionLabel.text = consumption_text	
	$ProductionRect.show()
	$ConsumptionRect.show()
	
	$ProductionRect.rect_size.y = $ProductionRect/ProductionLabel.rect_size.y + 20
	$ProductionRect.rect_size.x = $ProductionRect/ProductionLabel.rect_size.x + 20
	$ConsumptionRect.rect_size.y = $ConsumptionRect/ConsumptionLabel.rect_size.y + 20
	$ConsumptionRect.rect_size.x = $ConsumptionRect/ConsumptionLabel.rect_size.x + 20
	
	# TODO: move the rectangles to the appropriate position next to the bar

func _on_hover_off() -> void:
	$ProductionRect.hide()
	$ConsumptionRect.hide()

func _to_str(number: float, include_plus: bool, people : float = 0.0) -> String:
	var prefix = "+" if number >= 0 and include_plus else ""
	if not people:
		return prefix + str(floor(number))
	else:
		return prefix + str(floor(people + number) - floor(people))

func update_graph(resources: GameObjs.Resources, new_resource_dict : Dictionary) -> void:
	resource_dict = new_resource_dict
	for type in RESOURCE_TYPE_TO_STRING.keys():
		var node_name = RESOURCE_TYPE_TO_STRING.get(type)
		var graph_bar = get_node("HBoxContainer/" + node_name)

		# set text
		var production = resources.get_income(type)
		var consumption = resources.get_expense(type)
		var reserve = resources.get_reserve(type)
		graph_bar.get_node("ResourceStore").text = _to_str(reserve, false)
		graph_bar.get_node("ResourceDiff").text = _to_str(production - consumption, true)
		
		# resize bar
		var bar_ratio = production / max(consumption, 1)
		bar_ratio = min(1, bar_ratio)
		graph_bar.get_node("Bar").rect_size.y = MAX_BAR_HEIGHT * bar_ratio
		graph_bar.get_node("Bar").rect_position.y = MAX_BAR_HEIGHT * (1 - bar_ratio)
		
		# move reference line and diff label
		var reference_y = 0
		if production > consumption:
			reference_y = MAX_BAR_HEIGHT * (1 - consumption / production)
		graph_bar.get_node("ReferenceLine").rect_position.y = reference_y
		graph_bar.get_node("ResourceDiff").rect_position.y = reference_y + (10 if reference_y < 10 else -20)

	# set science and people labels
	$ScienceStore.text = _to_str(resources.get_reserve(GameData.ResourceType.SCIENCE), false)
	$ScienceDiff.text = _to_str(resources.get_income(GameData.ResourceType.SCIENCE), true) + " / mo"
	$ColonistsStore.text = _to_str(resources.get_reserve(GameData.ResourceType.PEOPLE), false)
	$ColonistsDiff.text = _to_str(resources.get_income(GameData.ResourceType.PEOPLE), true, resources.get_reserve(GameData.ResourceType.PEOPLE)) + " / mo"
	# TODO: set dead colonists correctly:
	var dead = 0
	$ColonistsDead.text = _to_str(dead, false) + " dead"

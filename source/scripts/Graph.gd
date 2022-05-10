extends Control

const MAX_BAR_HEIGHT = 190

const RESOURCE_TYPE_TO_STRING: Dictionary = {
	GameData.ResourceType.WATER: "Water",
	GameData.ResourceType.FOOD: "Food",
	GameData.ResourceType.OXYGEN: "Oxygen",
	GameData.ResourceType.ELECTRICITY: "Energy",
	GameData.ResourceType.METAL: "Metal",
}

const ANIMATION_SPEED = 0.5

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
	
	$ProductionRect/ProductionLabel.text = production_text
	$ConsumptionRect/ConsumptionLabel.text = consumption_text
	$ProductionRect.show()
	$ConsumptionRect.show()
	
	$ProductionRect.rect_size.y = $ProductionRect/ProductionLabel.rect_size.y + 20
	$ProductionRect.rect_size.x = $ProductionRect/ProductionLabel.rect_size.x + 20
	$ConsumptionRect.rect_size.y = $ConsumptionRect/ConsumptionLabel.rect_size.y + 20
	$ConsumptionRect.rect_size.x = $ConsumptionRect/ConsumptionLabel.rect_size.x + 20
	
	var graph_bar = get_node("HBoxContainer/" + node_name)
	$ProductionRect.rect_position.x = graph_bar.rect_position.x + graph_bar.rect_size.x - 9
	$ProductionRect.rect_position.y = graph_bar.rect_position.y + graph_bar.get_node("Bar").rect_position.y
	
	$ConsumptionRect.rect_position.x = graph_bar.rect_position.x - $ConsumptionRect.rect_size.x + 30
	$ConsumptionRect.rect_position.y = graph_bar.rect_position.y + graph_bar.get_node("ReferenceLine").rect_position.y

func _on_hover_off() -> void:
	$ProductionRect.hide()
	$ConsumptionRect.hide()

func _to_str(number: float, include_plus: bool, people : float = 0.0) -> String:
	var prefix = "+" if number >= 0 and include_plus else ""
	if not people:
		return prefix + str(floor(number))
	else:
		return prefix + str(floor(people + number) - floor(people))

func _animate_store(name: String, val: float) -> void:
	get_node("HBoxContainer/" + name + "/ResourceStore").text = _to_str(val, false)

func _animate_diff(name: String, val: float) -> void:
	get_node("HBoxContainer/" + name + "/ResourceDiff").text = _to_str(val, true)

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
	for type in RESOURCE_TYPE_TO_STRING.keys():
		var node_name = RESOURCE_TYPE_TO_STRING.get(type)
		var graph_bar = get_node("HBoxContainer/" + node_name)
		var tween = graph_bar.get_node("Tween")
		var bar = graph_bar.get_node("Bar")

		# set text
		var production = resources.get_income(type)
		var consumption = resources.get_expense(type)
		var reserve = resources.get_reserve(type)
		
		var initial_store = _parse_str(graph_bar.get_node("ResourceStore").text)
		tween.interpolate_method(self, "_animate_store_" + node_name, initial_store, reserve, ANIMATION_SPEED, Tween.TRANS_LINEAR, Tween.EASE_OUT)
		var initial_diff = _parse_str(graph_bar.get_node("ResourceDiff").text)
		tween.interpolate_method(self, "_animate_diff_" + node_name, initial_diff, production - consumption, ANIMATION_SPEED, Tween.TRANS_LINEAR, Tween.EASE_OUT)
		
		var bar_ratio = production / max(consumption, 1)
		bar_ratio = max(0.01, min(1, bar_ratio))
		tween.interpolate_property(bar, "rect_size:y", bar.rect_size.y, MAX_BAR_HEIGHT * bar_ratio, ANIMATION_SPEED, Tween.TRANS_EXPO, Tween.EASE_OUT)
		tween.interpolate_property(bar, "rect_position:y", bar.rect_position.y, MAX_BAR_HEIGHT * (1 - bar_ratio), ANIMATION_SPEED, Tween.TRANS_EXPO, Tween.EASE_OUT)
		
		# move reference line and diff label
		var reference_y = 0
		if production > consumption:
			reference_y = MAX_BAR_HEIGHT * (1 - consumption / production)
		var ref_line = graph_bar.get_node("ReferenceLine")
		tween.interpolate_property(ref_line, "rect_position:y", ref_line.rect_position.y, reference_y, ANIMATION_SPEED, Tween.TRANS_EXPO, Tween.EASE_OUT)
		var diff_text = graph_bar.get_node("ResourceDiff")
		tween.interpolate_property(diff_text, "rect_position:y", diff_text.rect_position.y, reference_y + (10 if reference_y < 10 else -20), ANIMATION_SPEED, Tween.TRANS_EXPO, Tween.EASE_OUT)
		
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

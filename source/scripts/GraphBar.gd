extends Node

const MAX_BAR_HEIGHT = 178
const ANIMATION_SPEED_STAGE_1 = 0.5
const ANIMATION_SPEED_STAGE_2 = 0.5

var node_name: String

var arrow_line_1: Vector2
var arrow_line_2: Vector2

var bar_1: Vector2
var bar_2: Vector2

func _ready() -> void:
	arrow_line_1 = $Arrow/Line2D.points[0]
	arrow_line_2 = $Arrow/Line2D.points[1]
	bar_1 = $Line2D.points[0]
	bar_2 = $Line2D.points[1]

func get_arrow_line_points() -> Array:
	return $Arrow/Line2D.points

func get_bar_line_points() -> Array:
	return $Line2D.points

func calculate_arrow_line_points(a: float, b: float) -> Array:
	var top = min(a, b)
	var bottom = max(a, b)
	return [Vector2(arrow_line_1.x, top), Vector2(arrow_line_2.x, bottom)]

func calculate_bar_line_points(a: float, b: float) -> Array:
	var top = min(a, b)
	var bottom = max(a, b)
	return [Vector2(bar_1.x, top), Vector2(bar_2.x, bottom)]

func set_color_and_name(color: Color, node_name: String) -> void:
	$Line2D.default_color = color
	$ResourceName.text = node_name
	$ResourceName.add_color_override("font_color", color)
	self.node_name = node_name

func _stage_animation(stage: int, tween, object: Object, property: NodePath, initial_val, final_val, trans_type=0, ease_type=2, delay: float=0) -> void:
	var speed = ANIMATION_SPEED_STAGE_1 if stage == 0 else ANIMATION_SPEED_STAGE_2
	delay += 0 if stage == 0 else ANIMATION_SPEED_STAGE_1
	if object == self:
		tween.interpolate_method(object, property, initial_val, final_val, speed, trans_type, ease_type, delay)
	else:
		tween.interpolate_property(object, property, initial_val, final_val, speed, trans_type, ease_type, delay)

func relerp(value: float, val_min: float, val_max: float, out_min: float, out_max: float) -> float:
	return (value - val_min) / (val_max - val_min) * (out_max - out_min) + out_min

func update_bar(is_next_turn_update: bool, production: float, consumption: float, reserve: float) -> void:
	var tween = $Tween
	var ref_line = $ReferenceLine
	
	var resource_delta = production - consumption
	var next_reserve = reserve + resource_delta
	
	var max_bar_height = MAX_BAR_HEIGHT + (0 if (next_reserve > 0 and reserve > 0) else -20)

	var top_value_old = get_meta("top_value")
	var bottom_value_old = get_meta("bottom_value")

	var top_value = max(reserve, next_reserve)
	var bottom_value = min(min(reserve, next_reserve), 0)
	if top_value == bottom_value:
		top_value += 1
	set_meta("top_value", top_value)
	set_meta("bottom_value", bottom_value)

	if top_value_old == null or bottom_value == null:
		top_value_old = top_value
		bottom_value_old = bottom_value
	
	var initial_store = _parse_str($TextReserve.text)
	tween.interpolate_method(self, "_animate_store", initial_store, reserve, ANIMATION_SPEED_STAGE_1, Tween.TRANS_LINEAR, Tween.EASE_OUT)  # first stage
	var initial_next_reserve = _parse_str($TextNextReserve.text)
	tween.interpolate_method(self, "_animate_next_reserve", initial_next_reserve, next_reserve, ANIMATION_SPEED_STAGE_2, Tween.TRANS_LINEAR, Tween.EASE_OUT, ANIMATION_SPEED_STAGE_1 if is_next_turn_update else 0)

	var bar_size = max(3, relerp(reserve, 0, top_value - bottom_value, 0, max_bar_height))
	if reserve == 0 and top_value == 0:
		bar_size = 3
	var bar_y = relerp(reserve, bottom_value, top_value, max_bar_height, 0)
	var bar_y_bottom = bar_y + bar_size
	
	var bar_ps_current = get_bar_line_points()
	var bar_ps = calculate_bar_line_points(bar_y, bar_y_bottom)
	if is_next_turn_update:
		var bar_size_stage_1 = 3 if next_reserve <= 0 else ((bar_ps_current[1].y - bar_ps_current[0].y) - (ref_line.rect_position.y - bar_ps_current[0].y))
		var bar_y_stage_1 = ref_line.rect_position.y
		var bar_ps_stage_1 = calculate_bar_line_points(bar_y_stage_1, bar_y_stage_1 + bar_size_stage_1)

		_stage_animation(0, tween, self, "_animate_bar_1", bar_ps_current[0], bar_ps_stage_1[0], Tween.TRANS_EXPO, Tween.EASE_OUT)
		_stage_animation(0, tween, self, "_animate_bar_2", bar_ps_current[1], bar_ps_stage_1[1], Tween.TRANS_EXPO, Tween.EASE_OUT)
		_stage_animation(1, tween, self, "_animate_bar_1", bar_ps_stage_1[0], bar_ps[0], Tween.TRANS_EXPO, Tween.EASE_OUT)
		_stage_animation(1, tween, self, "_animate_bar_2", bar_ps_stage_1[1], bar_ps[1], Tween.TRANS_EXPO, Tween.EASE_OUT)
	else:
		_stage_animation(1, tween, self, "_animate_bar_1", bar_ps_current[0], bar_ps[0], Tween.TRANS_EXPO, Tween.EASE_OUT)
		_stage_animation(1, tween, self, "_animate_bar_2", bar_ps_current[1], bar_ps[1], Tween.TRANS_EXPO, Tween.EASE_OUT)

	# move reference line and diff label
	var reference_y = relerp(next_reserve, bottom_value, top_value, max_bar_height, 0)
	var reference_y_old = relerp(next_reserve, bottom_value_old, top_value_old, max_bar_height, 0)
	reference_y_old = max(-60, min(reference_y_old, MAX_BAR_HEIGHT + 30))
	
	var diff_text = $TextNextReserve
	diff_text.modulate = Color("#f00" if next_reserve < 0 else "#fff")
	
	var triangle = $Arrow/Triangle
	var arrow_line = $Arrow/Line2D
	
	var line_top = 0
	var line_top_old = 0
	var line_bottom = 0
	var line_bottom_old = 0
	if next_reserve < 0:
		# reserve >= 0 > next_reserve
		line_top = bar_y
		line_bottom = reference_y - 5
		line_top_old = bar_ps_current[0].y
		line_bottom_old = reference_y_old - 5
	elif next_reserve > reserve:
		# next_reserve > reserve >= 0
		line_top = reference_y + 5
		line_bottom = bar_y
		line_top_old = reference_y_old + 5
		line_bottom_old = bar_ps_current[0].y
	else:
		# reserve >= next_reserve >= 0
		line_top = bar_y
		line_bottom = reference_y - 5
		line_top_old = bar_ps_current[0].y
		line_bottom_old = reference_y_old - 5
	
	if node_name == "Water":
		print(production, " - ", consumption, " = ", resource_delta, " -> ", sign(resource_delta))

	var arrow_line_ps_current = get_arrow_line_points()
	var arrow_line_ps = calculate_arrow_line_points(line_top, line_bottom)

	if is_next_turn_update:
		_stage_animation(1, tween, ref_line, "rect_position:y", null, reference_y, Tween.TRANS_EXPO, Tween.EASE_OUT)
		_stage_animation(1, tween, diff_text, "rect_position:y", null, reference_y + (9 if resource_delta < 0 else -20), Tween.TRANS_EXPO, Tween.EASE_OUT)
		
		_stage_animation(1, tween, triangle, "position:y", null, reference_y + (4 if next_reserve > reserve else -4), Tween.TRANS_EXPO, Tween.EASE_OUT)
		# if node_name == "Water":
		# 	print("[NTU] Setting scale:y to ", sign(resource_delta))
		_stage_animation(1, tween, triangle, "scale:y", null, sign(resource_delta), Tween.TRANS_EXPO, Tween.EASE_OUT)

		_stage_animation(1, tween, self, "_animate_arrow_line_1", arrow_line_ps_current[0], arrow_line_ps[0], Tween.TRANS_EXPO, Tween.EASE_OUT)
		_stage_animation(1, tween, self, "_animate_arrow_line_2", arrow_line_ps_current[1], arrow_line_ps[1], Tween.TRANS_EXPO, Tween.EASE_OUT)
	else:
		_stage_animation(0, tween, ref_line, "rect_position:y", null, reference_y_old, Tween.TRANS_EXPO, Tween.EASE_OUT)
		_stage_animation(1, tween, ref_line, "rect_position:y", reference_y_old, reference_y, Tween.TRANS_EXPO, Tween.EASE_OUT)

		var diff_text_y_stage_1 = reference_y_old + (9 if resource_delta < 0 else -20)
		_stage_animation(0, tween, diff_text, "rect_position:y", null, diff_text_y_stage_1, Tween.TRANS_EXPO, Tween.EASE_OUT)
		_stage_animation(1, tween, diff_text, "rect_position:y", diff_text_y_stage_1, reference_y + (9 if resource_delta < 0 else -20), Tween.TRANS_EXPO, Tween.EASE_OUT)
		
		_stage_animation(0, tween, triangle, "position:y", null, reference_y_old + (4 if next_reserve > reserve else -4), Tween.TRANS_EXPO, Tween.EASE_OUT)
		if node_name == "Water":
			print("[B] Setting scale:y to ", sign(resource_delta))
		_stage_animation(0, tween, triangle, "scale:y", null, sign(resource_delta), Tween.TRANS_EXPO, Tween.EASE_OUT)
		_stage_animation(1, tween, triangle, "position:y", reference_y_old + (4 if next_reserve > reserve else -4), reference_y + (4 if next_reserve > reserve else -4), Tween.TRANS_EXPO, Tween.EASE_OUT)

		var arrow_line_ps_stage_1 = calculate_arrow_line_points(line_top_old, line_bottom_old)

		_stage_animation(0, tween, self, "_animate_arrow_line_1", arrow_line_ps_current[0], arrow_line_ps_stage_1[0], Tween.TRANS_EXPO, Tween.EASE_OUT)
		_stage_animation(0, tween, self, "_animate_arrow_line_2", arrow_line_ps_current[1], arrow_line_ps_stage_1[1], Tween.TRANS_EXPO, Tween.EASE_OUT)
		_stage_animation(1, tween, self, "_animate_arrow_line_1", arrow_line_ps_stage_1[0], arrow_line_ps[0], Tween.TRANS_EXPO, Tween.EASE_OUT)
		_stage_animation(1, tween, self, "_animate_arrow_line_2", arrow_line_ps_stage_1[1], arrow_line_ps[1], Tween.TRANS_EXPO, Tween.EASE_OUT)
	
	var reserve_text = $TextReserve
	var reserve_y = 0
	if bar_y < line_top - 5 or (bar_y == line_top and resource_delta < 0):
		# line is below bar
		reserve_y = line_top - 20
	else:
		reserve_y = bar_y + 9
	
	var should_hide_arrow = resource_delta == 0 or abs(line_top - line_bottom) < 5
	if should_hide_arrow:
		triangle.hide()
	else:
		triangle.show()
	_stage_animation(0, tween, arrow_line, "default_color", null, Color(0 if should_hide_arrow else "#fff"), Tween.TRANS_EXPO, Tween.EASE_OUT)
	
	_stage_animation(1, tween, reserve_text, "rect_position:y", reserve_text.rect_position.y, reserve_y, Tween.TRANS_EXPO, Tween.EASE_OUT)
	
	tween.start()



func _to_str(number: float, include_plus: bool, people : float = 0.0) -> String:
	var prefix = "+" if number >= 0 and include_plus else ""
	if not people:
		return prefix + str(floor(number))
	else:
		return prefix + str(floor(people + number) - floor(people))

func _parse_str(val: String) -> float:
	return val.trim_prefix("+").to_float()

func _animate_store(val: float) -> void:
	$TextReserve.text = _to_str(val, false)

func _animate_next_reserve(val: float) -> void:
	$TextNextReserve.text = _to_str(val, false)

func _animate_bar_1(val: Vector2) -> void:
	$Line2D.points[0] = val
func _animate_bar_2(val: Vector2) -> void:
	$Line2D.points[1] = val
func _animate_arrow_line_1(val: Vector2) -> void:
	$Arrow/Line2D.points[0] = val
func _animate_arrow_line_2(val: Vector2) -> void:
	$Arrow/Line2D.points[1] = val

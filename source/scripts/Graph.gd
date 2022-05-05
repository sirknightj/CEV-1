extends Node2D

const HEIGHT : float = 200.0
const WIDTH : float = 500.0 # the width of this graph

const BIG_SPACING : float = 10.0  # the space between the different resource bars
const SMALL_SPACING : float = 5.0 # the space between the income/usage bars

const LINE_THICKNESS : float = 2.0 # the thickness of each line
const BOTTOM_SPACING : float = 20.0 # the spacing where the bar labels will go
const TOP_SPACING : float = 20.0 # the spacing between the highest bar and the top of the graph

const LABEL_TEXT_COLOR : Color = Color("#000001") # the color of graph text labels
const LINE_COLOR : Color = Color("#000000") # the color of the lines in the graph
const INCOME_BAR_COLOR : Color = Color("#00FF00") # the color of the income bar
const EXPENSE_BAR_COLOR : Color = Color("#FF0000") # the color of the expense bar

# Called when the node enters the scene tree for the first time.
func _ready():
	var bg : ColorRect = ColorRect.new()
	bg.rect_size = Vector2(WIDTH, HEIGHT)
	add_child(bg)

func update_graph(resourceDict : Dictionary) -> void:
	for child in get_children():
		remove_child(child)

	var bg : ColorRect = ColorRect.new()
	bg.rect_size = Vector2(WIDTH, HEIGHT)
	add_child(bg)
	
	print(resourceDict)
	print(resourceDict.keys().size())
	var sums : Dictionary = {}
	var neg_sums : Dictionary = {}
	for resource in resourceDict:
		if not sums.has(resource):
			sums[resource] = 0
		if not neg_sums.has(resource):
			neg_sums[resource] = 0
		for building in resourceDict[resource]:
			if resourceDict[resource][building] > 0:
				sums[resource] += resourceDict[resource][building]
			else:
				neg_sums[resource] -= resourceDict[resource][building]
	
	var highest_sum : float = 0
	for resource in sums:
		if sums[resource] > highest_sum:
			highest_sum = sums[resource]
		if neg_sums[resource] > highest_sum:
			highest_sum = neg_sums[resource]

	# The width of the longest label
	var largest_width : int = 0
	# Draw the y-axis
	# The number of labels to have
	var NUM_LABELS : int = 5
	var offset : int = 0
	for i in range(NUM_LABELS):
		var label_range = highest_sum / NUM_LABELS
		var label_text : String = str(label_range * i) 
		var label : Label = Label.new()
		label.text = label_text
		label.add_color_override("font_color", LABEL_TEXT_COLOR)
		label.set_position(Vector2(0, HEIGHT - ((HEIGHT - BOTTOM_SPACING - TOP_SPACING) / NUM_LABELS) * i - label.get_line_height() - BOTTOM_SPACING))
		add_child(label)
		
		var font = label.get_font("font")
		var label_width : float = font.get_string_size(label_text).x
		
		var line : Line2D = Line2D.new()
		line.add_point(Vector2(label_width + SMALL_SPACING, HEIGHT - ((HEIGHT - BOTTOM_SPACING - TOP_SPACING) / NUM_LABELS) * i - label.get_line_height() / 2 - BOTTOM_SPACING))
		line.add_point(Vector2(WIDTH - SMALL_SPACING, HEIGHT - ((HEIGHT - BOTTOM_SPACING - TOP_SPACING) / NUM_LABELS) * i - label.get_line_height() / 2 - BOTTOM_SPACING))
		offset = label.get_line_height() / 2
		line.width = LINE_THICKNESS
		line.default_color = LINE_COLOR
		add_child(line)
		
		if label_width > largest_width:
			largest_width = label_width
	
	print("The longest label has width = " + str(largest_width))
	
	var bars : int = resourceDict.keys().size()
	var BAR_WIDTH : float = (WIDTH - (bars + 1) * BIG_SPACING - bars * SMALL_SPACING - largest_width) / bars / 2
	
	print(BAR_WIDTH * bars * 2 + (1 + BIG_SPACING) * bars + bars * SMALL_SPACING)
	print("Each bar has width = " + str(BAR_WIDTH))
	
	# Draw the bars
	for i in range(bars):
		var bar_range : float = HEIGHT - offset - LINE_THICKNESS / 2 - BOTTOM_SPACING - TOP_SPACING # The height of our tallest bar
		var income_height : float = sums[i] / highest_sum * bar_range # The height of the income bar
		var spending_height : float = neg_sums[i] / highest_sum * bar_range # The height of our spending bar
		
		var income_bar : ColorRect = ColorRect.new()
		income_bar.rect_size = Vector2(BAR_WIDTH, income_height)
		income_bar.set_position(Vector2(BIG_SPACING * (i + 1) + (BAR_WIDTH * 2 + SMALL_SPACING) * i + largest_width, bar_range - income_height + TOP_SPACING))
		income_bar.color = INCOME_BAR_COLOR
		add_child(income_bar)
		
		var spending_bar : ColorRect = ColorRect.new()
		spending_bar.rect_size = Vector2(BAR_WIDTH, spending_height)
		spending_bar.set_position(Vector2(BIG_SPACING * (i + 1) + (BAR_WIDTH * 2 + SMALL_SPACING) * i + BAR_WIDTH + SMALL_SPACING + largest_width, bar_range - spending_height + TOP_SPACING))
		spending_bar.color = EXPENSE_BAR_COLOR
		add_child(spending_bar)
		
		var label : Label = Label.new()
		label.add_color_override("font_color", LABEL_TEXT_COLOR)
		
		label.text = GameData.ResourceType.keys()[i].capitalize()
		
		var font = label.get_font("font")
		var label_width : float = font.get_string_size(label.text).x
		label.set_position(Vector2(BIG_SPACING * (i + 1) + (BAR_WIDTH * 2 + SMALL_SPACING) * i + largest_width + BAR_WIDTH + SMALL_SPACING / 2 - label_width / 2, bar_range + BOTTOM_SPACING / 2 + TOP_SPACING))
		add_child(label)

extends Control

signal upgrade_changed

# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"

var tree_json = "res://assets/data/tree.json"
var tree_dict : Dictionary = {} # upgrade name -> upgrade data
var all_links : Array # Array of Line2Ds

var item_scene = preload("res://scenes/TreeItem.tscn")

var selected_upgrade : String = ""
var hovered_upgrade : String = ""

class Upgrade:
	var name: String
	var prereqs: Array
	var type: String
	var description: String
	var effects: String
	var unlocks: String
	var science_cost: int
	var unlocked: bool
	var available: bool
	var enabled: bool
	var node: Node
	var links: Array
	var pos: Vector2
	var tree
	
	func _init(data, parent_tree) -> void:
		name = data.name
		prereqs = data.prereqs if data.prereqs else []
		type = data.type
		description = data.description
		effects = data.effects
		unlocks = data.unlocks
		science_cost = -data.science_cost
		node = null
		unlocked = data.starting
		available = false # correctly set by recalculate_available later
		enabled = data.starting
		tree = parent_tree
		
		var minX = 0.7
		var maxX = 9.1
		var minY = 0.7
		var maxY = 9.1
		
		var minScreenX = 100
		var maxScreenX = 800
		var minScreenY = 100
		var maxScreenY = 720 - 90
		
		var x = (data.x-minX) / (maxX-minX) * (maxScreenX-minScreenX) + minScreenX
		var y = (data.y-minY) / (maxY-minY) * (maxScreenY-minScreenY) + minScreenY
		pos = Vector2(x, y)
	
	func unlock() -> void:
		assert(not unlocked and available)
		unlocked = true
		enabled = true
		tree.recalculate_available()
	
	func recalculate_available() -> void:
		if available:
			return
		for p in prereqs:
			if not tree.tree_dict.get(p).unlocked:
				return
		available = true
	
	func get_all_pre_links() -> Array:
		var res = links.duplicate()
		for p in prereqs:
			res += tree.tree_dict.get(p).get_all_pre_links()
		return res

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_tree_json()
	add_nodes()
	recalculate_available()
	_on_item_hover_off("")
	$SelectedUpgrade/BuyButton.connect("gui_input", self, "_on_BuyButton_gui_input")

"""
	Loads upgrades configuration file
"""
func load_tree_json() -> void:
	var file = File.new()
	assert (file.file_exists(tree_json))
	file.open(tree_json, File.READ)
	var data = parse_json(file.get_as_text())
	for upgrade in data:
		tree_dict[upgrade.name] = Upgrade.new(upgrade, self)
	print("Loaded the upgrades: " + str(tree_dict.keys()))
	file.close()

func add_nodes() -> void:
	for upgrade in tree_dict.values():
		var links = []
		for p in upgrade.prereqs:
			var line = Line2D.new()
			line.clear_points()
			line.add_point(upgrade.pos)
			line.add_point(tree_dict.get(p).pos)
			line.width = 10
			line.set_meta('pre', p)
			line.set_meta('post', upgrade.name)
			add_child(line)
			links.append(line)
		upgrade.links = links
		all_links.append_array(links)

	for upgrade in tree_dict.values():
		var item = item_scene.instance()
		item.position = upgrade.pos
		add_child(item)
		var label = item.get_node("NameLabel")
		label.text = upgrade.name

		item.item_name = upgrade.name
		item.connect("hover_on", self, "_on_item_hover_on")
		item.connect("hover_off", self, "_on_item_hover_off")
		item.connect("click", self, "_on_item_click")
		upgrade.node = item

func set_node_styles() -> void:
	for upgrade in tree_dict.values():
		var item = upgrade.node
		var background = "171c40" if upgrade.available else "BCC3F1"
		var border = "EEEEEE"
		if upgrade.unlocked:
			border = "049F0C"
		elif upgrade.available:
			border = "C79200"
		item.get_node("BackgroundRect").color = Color(background)
		item.get_node("BorderRect").color = Color(border)

func recalculate_available() -> void:
	for v in tree_dict.values():
		v.recalculate_available()
	set_node_styles()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass

func set_sidebar(name: String) -> void:
	var upgrade : Upgrade = tree_dict.get(name)
	var desc : String = upgrade.description
	if not desc:
		desc = "TODO"
	var effects : String = upgrade.effects
	if upgrade.unlocks:
		if effects:
			effects += "\n"
		effects += "Unlocks: " + upgrade.unlocks

	$SelectedUpgrade/Name.text = name
	$SelectedUpgrade/Cost.text = "Cost: " + str(upgrade.science_cost) + " science"
	var can_afford : bool = GameStats.resources.get_reserve(GameData.ResourceType.SCIENCE) >= upgrade.science_cost
	if not upgrade.unlocked and upgrade.available and can_afford:
		$SelectedUpgrade/BuyButton.show()
	else:
		$SelectedUpgrade/BuyButton.hide()
	$SelectedUpgrade/Description.text = desc
	$SelectedUpgrade/Effects.text = effects
	$Instructions.hide()
	$SelectedUpgrade.show()

func clear_sidebar() -> void:
	$SelectedUpgrade.hide()
	$Instructions.show()

func set_link_colors() -> void:
	var name = hovered_upgrade
	if not name:
		name = selected_upgrade
	
	# clear all link colors
	for line in all_links:
		line.default_color = Color("#AA171c40")
	# set link colors of name
	if name:
		var links = tree_dict.get(name).get_all_pre_links()
		for line in links:
			var pre = tree_dict.get(line.get_meta('pre'))
			var post = tree_dict.get(line.get_meta('post'))
			var color = "#FFB0B6E3"
			if post.unlocked:
				color = "049F0C"
			elif post.available:
				color = "C79200"
			line.default_color = Color(color)

func _on_item_hover_on(name: String) -> void:
	if selected_upgrade == "":
		set_sidebar(name)
	if name == "":
		return
	hovered_upgrade = name
	set_link_colors()

func _on_item_hover_off(name: String) -> void:
	if selected_upgrade == "":
		clear_sidebar()
	hovered_upgrade = ""
	set_link_colors()

func _on_item_click(name: String) -> void:
	if selected_upgrade == name:
		selected_upgrade = ""
		clear_sidebar()
	else:
		selected_upgrade = name
		set_sidebar(name)

func _on_Control_upgrade_changed() -> void:
	print("upgrade_changed signal received")


func _on_BuyButton_gui_input(event: InputEvent) -> void:
	var is_left_click = event is InputEventMouseButton and event.button_index == 1 and not event.pressed
	if not is_left_click:
		return
	var upgrade : Upgrade = tree_dict.get(selected_upgrade)
	
	GameStats.resources.consume(GameData.ResourceType.SCIENCE, upgrade.science_cost)
	print(GameStats.resources.to_string())
	upgrade.unlock()
	print("Unlocked ", upgrade.name)
	set_sidebar(upgrade.name)

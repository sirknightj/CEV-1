extends Control

var all_links : Array # Array of Line2Ds

var item_scene = preload("res://scenes/TreeItem.tscn")

var selected_upgrade : String = ""
var hovered_upgrade : String = ""

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_nodes()
	set_node_styles()
	_on_item_hover_off("")
	$SelectedUpgrade/BuyButton.connect("gui_input", self, "_on_BuyButton_gui_input")

func add_nodes() -> void:
	var tree_dict = GameStats.upgrade_tree.tree_dict
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
	for upgrade in GameStats.upgrade_tree.tree_dict.values():
		var item = upgrade.node
		var background = "171c40" if upgrade.available else "BCC3F1"
		var border = "EEEEEE"
		if upgrade.unlocked:
			border = "049F0C"
		elif upgrade.available:
			border = "C79200"
		item.get_node("BackgroundRect").color = Color(background)
		item.get_node("BorderRect").color = Color(border)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass

func set_sidebar(name: String) -> void:
	var upgrade : GameObjs.Upgrade = GameStats.upgrade_tree.tree_dict.get(name)
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
	
	var tree_dict = GameStats.upgrade_tree.tree_dict
	
	# clear all link colors
	for line in all_links:
		line.default_color = Color("#AA171c40")
	# set link colors of name
	if name:
		var links = tree_dict.get(name).get_all_pre_links()
		for line in links:
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

func _on_item_hover_off(_name: String) -> void:
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


func _on_BuyButton_gui_input(event: InputEvent) -> void:
	var is_left_click = event is InputEventMouseButton and event.button_index == BUTTON_LEFT and not event.pressed
	if not is_left_click:
		return
	var upgrade : GameObjs.Upgrade = GameStats.upgrade_tree.tree_dict.get(selected_upgrade)
	
	GameStats.resources.consume(GameData.ResourceType.SCIENCE, upgrade.science_cost)
	print(GameStats.resources.to_string())
	upgrade.unlock()
	print("Unlocked ", upgrade.name)
	set_node_styles()
	set_sidebar(upgrade.name)

"""
	Called when the Back button is pressed
"""
func _on_Back_gui_input(event):
	if (event is InputEventMouseButton && event.pressed && event.button_index == BUTTON_LEFT):
		GameStats.logger.log_action_with_no_level(Logger.Actions.UpgradeMenuBackClicked)
		self.hide()

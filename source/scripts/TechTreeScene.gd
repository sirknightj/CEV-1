extends Control

var all_links : Array # Array of Line2Ds

var item_scene = preload("res://scenes/TreeItem.tscn")

var selected_upgrade : int = -1
var hovered_upgrade : int = -1

var COLORS : Dictionary = {
	"unlocked" : [Color("#049F0C"), Color("#049F0C").darkened(0.4)],
	"available" : [Color("#CCA700"), Color("#CCA700").darkened(0.4)],
	"locked" : [Color("#FFFFFF"), Color("#D4C2BF")]
}
const DEFAULT_LINK_COLOR = Color("#4AD0CCD0")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameStats.upgrade_tree.load_upgrade_tree(self)
	add_nodes()
	set_node_styles()
	_on_item_hover_off(-1)
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
			line.set_meta('pre', p)
			line.set_meta('post', upgrade.id)
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

		item.item_name = upgrade.id
		item.connect("hover_on", self, "_on_item_hover_on")
		item.connect("hover_off", self, "_on_item_hover_off")
		item.connect("click", self, "_on_item_click")
		upgrade.node = item

func set_node_styles() -> void:
	for upgrade in GameStats.upgrade_tree.tree_dict.values():
		var item = upgrade.node
		var type = "locked"
		if upgrade.unlocked:
			type = "unlocked"
		elif upgrade.available:
			type = "available"
		item.get_node("BackgroundRect").color = COLORS[type][1]
		item.get_node("BorderRect").color = COLORS[type][0]

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass

func _update_reserve_text() -> void:
	$ScienceReserve.text = "Science: " + str(int(GameStats.resources.get_reserve(GameData.ResourceType.SCIENCE)))

func set_sidebar(name: int) -> void:
	var upgrade : GameObjs.UpgradeTreeNode = GameStats.upgrade_tree.tree_dict.get(name)
	var desc : String = upgrade.description
	if not desc:
		desc = "TODO"
	var effects : String = upgrade.effects

	$SelectedUpgrade/Name.text = upgrade.name
	$SelectedUpgrade/Cost.text = "Cost: "
	for resource_type in upgrade.cost.keys():
		$SelectedUpgrade/Cost.text += (str(upgrade.cost[resource_type])
				+ " " + str(GameData.ResourceType.keys()[resource_type]).to_lower()) + "\n"
	var can_afford : bool = upgrade.can_afford()
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
		line.default_color = DEFAULT_LINK_COLOR
		line.width = 9
	# set link colors of name
	if name != -1:
		var links = tree_dict.get(name).get_all_pre_links()
		for line in links:
			var post = tree_dict.get(line.get_meta('post'))
			var type = "locked"
			if post.unlocked:
				type = "unlocked"
			elif post.available:
				type = "available"
			line.default_color = COLORS[type][0]
			line.width = 12

func _on_item_hover_on(name: int) -> void:
	if selected_upgrade == -1:
		set_sidebar(name)
	if name == -1:
		return
	hovered_upgrade = name
	set_link_colors()

func _on_item_hover_off(_name: int) -> void:
	if selected_upgrade == -1:
		clear_sidebar()
	hovered_upgrade = _name
	set_link_colors()

func _on_item_click(_name: int) -> void:
	if selected_upgrade == _name:
		selected_upgrade = -1
		clear_sidebar()
	else:
		selected_upgrade = _name
		set_sidebar(_name)

func show() -> void:
	_update_reserve_text()
	.show()  # Godot equivalent of super.show()

func _on_BuyButton_gui_input(event: InputEvent) -> void:
	var is_left_click = event is InputEventMouseButton and event.button_index == BUTTON_LEFT and not event.pressed
	if not is_left_click:
		return
	var upgrade : GameObjs.UpgradeTreeNode = GameStats.upgrade_tree.tree_dict.get(selected_upgrade)
	
	upgrade.unlock()
	print("Unlocked ", upgrade.name)
	set_node_styles()
	set_link_colors()
	set_sidebar(upgrade.id)
	_update_reserve_text()

"""
	Called when the Back button is pressed
"""
func _on_Back_gui_input(event):
	if (event is InputEventMouseButton && event.pressed && event.button_index == BUTTON_LEFT):
		GameStats.logger.log_action_with_no_level(Logger.Actions.UpgradeMenuBackClicked)
		self.hide()

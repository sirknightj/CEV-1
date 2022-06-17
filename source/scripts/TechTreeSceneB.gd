extends Control

var all_links : Array # Array of Line2Ds

var item_scene = preload("res://scenes/TreeItemB.tscn")

var selected_upgrade : int
var hovered_upgrade : int
var just_purchased : bool

var COLORS : Dictionary = {
	"unlocked" : [Color("#238A0F"), Color("#238A0F").darkened(0.4)],
	"available" : [Color("#0580D1"), Color("#0580D1").darkened(0.4)],
	"locked" : [Color("#444"), Color("#444").darkened(0.3)],
	"locked_highlight" : [Color("#AAA"), Color("#AAA")]
}
const DEFAULT_LINK_COLOR = Color("#66DDCFDD")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	selected_upgrade = -1
	hovered_upgrade = -1
	just_purchased = false
	GameStats.upgrade_tree.load_upgrade_tree(self)
	$SelectedUpgrade/BuyButton.connect("gui_input", self, "_on_BuyButton_gui_input")
	
	$Legend/ColorRect4/Tween.interpolate_property($Legend/ColorRect4.get_material(), "shader_param/progress", 0, 1, 2.1, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	$Legend/ColorRect4/Tween.start()

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
		var label = item.get_node_or_null("NameLabel")
		label.text = upgrade.name

		item.item_name = upgrade.id
		item.connect("hover_on", self, "_on_item_hover_on")
		item.connect("hover_off", self, "_on_item_hover_off")
		item.connect("click", self, "_on_item_click")
		upgrade.node = item
		
		item.set_always_animate(upgrade.name == "Cryonics")
	
	set_node_styles()
	_on_item_hover_off(-1)

func set_node_styles(reset_animations: bool = true) -> void:
	for upgrade in GameStats.upgrade_tree.tree_dict.values():
		var item = upgrade.node
		var type = "locked"
		if upgrade.unlocked:
			type = "unlocked"
		elif upgrade.available:
			type = "available"
		item.get_node_or_null("BackgroundRect").color = COLORS[type][1]
		item.get_node_or_null("BorderRect").color = COLORS[type][1]
		item.set_locked(type == "locked")

		if upgrade.id == selected_upgrade || (selected_upgrade == -1 && upgrade.id == hovered_upgrade):
			item.get_node_or_null("BackgroundRect").color = COLORS[type][0]
			item.get_node_or_null("BorderRect").color = COLORS[type][0].lightened(0.45)
		
		if reset_animations:
			item.set_gradient_animation(not upgrade.unlocked and upgrade.available and upgrade.can_afford())

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
	
	if upgrade.unlocked:
		if upgrade.cost[GameData.ResourceType.SCIENCE] == 0:
			$SelectedUpgrade/Cost.text = "Unlocked for free"
		else:
			$SelectedUpgrade/Cost.text = "Unlocked for %s science" % upgrade.cost[GameData.ResourceType.SCIENCE]
	else:
		$SelectedUpgrade/Cost.text = "Cost: %s science\n" % upgrade.cost[GameData.ResourceType.SCIENCE]
	if not upgrade.unlocked and upgrade.available and upgrade.can_afford():
		$SelectedUpgrade/BuyButton.show()
	else:
		var prereqs = upgrade.recalculate_available()
		if not prereqs.empty():
			var names : Array = [];
			for upgr in prereqs:
				names.append(upgr.name)
			$SelectedUpgrade/Cost.text += "Needs: " + PoolStringArray(names).join(", ")
		$SelectedUpgrade/BuyButton.hide()
	$SelectedUpgrade/Description.text = desc
	$SelectedUpgrade/Effects.text = effects
	$Instructions.hide()
	$SelectedUpgrade.show()

func clear_sidebar() -> void:
	$SelectedUpgrade.hide()
	$Instructions.show()

func set_link_colors() -> void:
	var name = selected_upgrade
	if name == -1:
		name = hovered_upgrade
	
	var tree_dict = GameStats.upgrade_tree.tree_dict
	
	# clear all link colors
	for line in all_links:
		line.default_color = DEFAULT_LINK_COLOR
		line.width = 9
	
	# set link colors of name
	if name != -1:
		var links = tree_dict.get(name).get_all_pre_links()
		for line in links:
			assert(line.has_meta("pre"))
			var pre = tree_dict.get(line.get_meta('pre'))
			var type = "locked_highlight"
			if pre.unlocked:
				type = "unlocked"
			elif pre.available:
				type = "available"
			line.default_color = COLORS[type][0]
			line.width = 12

func _on_item_hover_on(name: int) -> void:
	if selected_upgrade == -1 or just_purchased:
		set_sidebar(name)
		just_purchased = false
	if name == -1:
		return
	hovered_upgrade = name
	set_link_colors()
	set_node_styles(false)

	var item = GameStats.upgrade_tree.tree_dict.get(name)
	var border_rect = item.node.get_node_or_null("BorderRect")
	if item.unlocked or item.available:
		border_rect.mouse_default_cursor_shape = Input.CURSOR_POINTING_HAND
	else:
		border_rect.mouse_default_cursor_shape = Input.CURSOR_FORBIDDEN

func _on_item_hover_off(_name: int) -> void:
	if selected_upgrade == -1:
		clear_sidebar()
	hovered_upgrade = -1
	set_link_colors()
	set_node_styles(false)

func _on_item_click(_name: int) -> void:
	var action
	if selected_upgrade == _name:
		action = Logger.Actions.UpgradeClickOff
		selected_upgrade = -1
		clear_sidebar()
	else:
		action = Logger.Actions.UpgradeClickOn
		var upgrade : GameObjs.UpgradeTreeNode = GameStats.upgrade_tree.tree_dict.get(_name)
		if upgrade.recalculate_available().empty():
			selected_upgrade = _name
			set_sidebar(_name)
	if not GameStats.upgrade_tree.tree_dict.get(_name).available:
		selected_upgrade = -1
		set_sidebar(_name)
	GameStats.logger.log_level_action(action, {
		"upgrade": _name
	})
	set_link_colors()
	set_node_styles(false)

func show() -> void:
	_update_reserve_text()
	set_node_styles()
	.show()  # Godot equivalent of super.show()

func _on_BuyButton_gui_input(event: InputEvent) -> void:
	var is_left_click = event is InputEventMouseButton and event.button_index == BUTTON_LEFT and not event.pressed
	if not is_left_click:
		return
	var upgrade : GameObjs.UpgradeTreeNode = GameStats.upgrade_tree.tree_dict.get(selected_upgrade)
	
	upgrade.unlock()
	get_node_or_null("/root/MainGameScene/AudioUnlock").play()
	GameStats.logger.log_level_action(Logger.Actions.UpgradeBought, {
		"upgrade": upgrade.name
	})
	set_node_styles()
	set_link_colors()
	set_sidebar(upgrade.id)
	_update_reserve_text()
	just_purchased = true
	selected_upgrade = -1
	GameStats.game.update_all()

"""
	Called when the Back button is pressed
"""
func _on_Back_gui_input(event):
	if (event is InputEventMouseButton && event.pressed && event.button_index == BUTTON_LEFT):
		GameStats.logger.log_level_action(Logger.Actions.UpgradeMenuBackClicked)
		selected_upgrade = -1
		clear_sidebar()
		self.hide()
		if GameStats.scroll_down_queued:
			GameStats.game.get_node_or_null("UILayer/Sidebar").scroll_down()
			GameStats.scroll_down_queued = false

func _unhandled_input(event : InputEvent):
	if event.is_action_pressed("ui_cancel") and is_visible_in_tree():
		get_tree().set_input_as_handled()
		.hide()

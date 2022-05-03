extends Control


# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"

var tree_json = "res://assets/data/tree.json"
var tree_dict : Dictionary = {} # upgrade_name -> upgrade data

var item_scene = preload("res://scenes/TreeItem.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_tree_json()
	add_nodes()

"""
	Loads upgrades configuration file
"""
func load_tree_json() -> void:
	var file = File.new()
	assert (file.file_exists(tree_json))
	file.open(tree_json, File.READ)
	var data = parse_json(file.get_as_text())
	for upgrade in data:
		if not upgrade.prereqs:
			upgrade.prereqs = [];
		tree_dict[upgrade.name] = upgrade
	print("Loaded the upgrades: " + str(tree_dict.keys()))
	file.close()

func _get_position(upgrade) -> Vector2:
	var minX = 0.7
	var maxX = 9.1
	var minY = 0.7
	var maxY = 9.1
	
	var minScreenX = 100
	var maxScreenX = 800
	var minScreenY = 100
	var maxScreenY = 720 - 90
	
	var x = (upgrade.x-minX) / (maxX-minX) * (maxScreenX-minScreenX) + minScreenX
	var y = (upgrade.y-minY) / (maxY-minY) * (maxScreenY-minScreenY) + minScreenY
	return Vector2(x, y)

func add_nodes() -> void:
	for upgrade in tree_dict.values():
		for p in upgrade.prereqs:
			var line = Line2D.new()
			line.clear_points()
			line.add_point(_get_position(upgrade))
			line.add_point(_get_position(tree_dict.get(p)))
			line.width = 10
			line.default_color = Color("#AA171c40")
			add_child(line)
	
	for upgrade in tree_dict.values():
		var item = item_scene.instance()
		var mePos = _get_position(upgrade)
		item.position = mePos
		if not upgrade.starting:
			item.get_node("ColorRect").color = Color("ACB3E1")
		add_child(item)
		var label = item.get_node("NameLabel")
		label.text = upgrade.name

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass

extends Node2D

var LINE_COLOR : Color = Color("#242424")

onready var _screen_size = get_viewport().get_visible_rect().size
onready var sidebar = $"../UILayer/Sidebar"

func _ready():
	_set_camera(GameStats.grid_size)

func set_grid_size(size : int):
	GameStats.grid_size = size
	update()
	_set_camera(GameStats.grid_size)

func _set_camera(grid_size : float):
	var size : float = float(grid_size * GameData.SQUARE_SIZE)
	var factor : float = (size / _screen_size.y) * 1.05
	$Camera.zoom = Vector2(factor, factor)
	$Camera.position = Vector2((sidebar.rect_size.x / 2) * factor + GameData.SQUARE_SIZE / 2, GameData.SQUARE_SIZE / 2)

# Centered at (0, 0)
func _draw():
	var mid = GameStats.grid_size / 2
	var points : PoolVector2Array = PoolVector2Array()
	for x in range(-mid, mid + 2):
		for y in range(-mid, mid + 2):
			print(x, " ", y)
			# Horizontal line
			points.append(Vector2(GameData.SQUARE_SIZE * -mid, y * GameData.SQUARE_SIZE))
			points.append(Vector2(GameData.SQUARE_SIZE * (mid + 1), y * GameData.SQUARE_SIZE))
			# Vertical line
			points.append(Vector2(x * GameData.SQUARE_SIZE, -mid * GameData.SQUARE_SIZE))
			points.append(Vector2(x * GameData.SQUARE_SIZE, (mid + 1) * GameData.SQUARE_SIZE))
	draw_multiline(points, LINE_COLOR)

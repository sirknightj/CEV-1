extends Upgrade

export(int) var size

func _ready():
	assert(size != null)
	self.effects = "Increases plot size to " + str(size) + "x" + str(size)

func apply():
	GameStats.grid.set_grid_size(size)

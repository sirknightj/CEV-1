package;

import flixel.FlxG;
import flixel.FlxSprite;

class BuildingSprite extends FlxSprite {
	private var grid:Grid;
	private var building:Building;
	var hovering:Bool = false;

	public function new(b:Building, grid:Grid) {
		var x = b.x;
		var y = b.y;
		super(x, y);
		building = b;
		var type = b.type;
		this.grid = grid;
		loadGraphic('assets/images/${type.id}.png', true, type.width, type.height);

		setGraphicSize(type.width * grid.cellSize);
		updateHitbox();
		setPosition(x * grid.cellSize, y * grid.cellSize);
	}

	function isMouseOverlapping():Bool {
		if (!FlxG.mouse.overlaps(this)) {
			return false;
		}
		var mousePos = FlxG.mouse.getScreenPosition();
		var myPos = getScreenPosition();
		var mx = Math.floor((mousePos.x - myPos.x) / grid.cellSize) + building.x;
		var my = Math.floor((mousePos.y - myPos.y) / grid.cellSize) + building.y;

		for (p in building.points) {
			if (p.x == mx && p.y == my) {
				return true;
			}
		}
		return false;
	}

	override function update(elapsed:Float) {
		hovering = FlxG.mouse.overlaps(this) && isMouseOverlapping();
		if (hovering && FlxG.mouse.justPressed) {
			trace('Just clicked on ${this.building.type.name} (${building.x},${building.y})');
		}
		alpha = hovering ? 1 : 0.6;
		super.update(elapsed);
	}
}

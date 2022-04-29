package;

import Building.Rotation;
import Tree.Upgrade;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import openfl.geom.Point;

class Grid extends FlxSprite {
	public var size(default, null):Int;

	var buildings:Array<Building> = [];
	private var totalSize:Int;
	private var buildingSprites:FlxTypedSpriteGroup<BuildingSprite>;

	public var cellSize(default, null):Int;

	override public function new(position:Point, totalSize:Int, buildingSprites:FlxTypedSpriteGroup<BuildingSprite>) {
		final thickness = 2;
		super(position.x - thickness / 2, position.y - thickness / 2);

		size = 15;
		this.totalSize = totalSize;
		cellSize = Math.floor(totalSize / size);
		final lineOptions:LineStyle = {
			color: FlxColor.fromInt(0xFF333333),
			thickness: thickness
		};

		makeGraphic(size * cellSize + thickness, size * cellSize + thickness, FlxColor.TRANSPARENT, true);

		for (x in 0...size + 1) {
			var xs = x * cellSize + thickness / 2;
			FlxSpriteUtil.drawLine(this, xs, 0, xs, height, lineOptions);
		}
		for (y in 0...size + 1) {
			var ys = y * cellSize + thickness / 2;
			FlxSpriteUtil.drawLine(this, 0, ys, width, ys, lineOptions);
		}

		this.buildingSprites = buildingSprites;
	}

	/** Returns true iff building type can be placed with the given rotation at the location. **/
	public function isPlacementAllowed(type:BuildingType, x:Int, y:Int, rotation:Rotation):Bool {
		if (rotation != NONE) {
			// TODO
			throw 'Rotations are not yet implemented';
		}

		// obviously out of bounds
		if (x < 0 || y < 0 || x + type.width > size || y + type.height > size) {
			return false;
		}

		// verify no intersections with other buildings
		var building = new Building(type, x, y, rotation);
		for (b in buildings) {
			if (building.intersects(b)) {
				return false;
			}
		}
		return true;
	}

	/** Returns all placed buildings (do not modify return value). **/
	public function getAll():Array<Building> {
		return buildings;
	}

	/** Returns the building at the given coordinate. Return value may be null. **/
	public function getAtPosition(x:Int, y:Int):Building {
		if (x < 0 || y < 0 || x >= size || y >= size) {
			throw 'Arguments are out of bounds';
		}

		for (b in buildings) {
			for (p in b.points) {
				if (p.x == x && p.y == y) {
					return b;
				}
			}
		}
		return null;
	}

	/** Places and returns the building at the given location. Throws error if illegal to place building. **/
	public function place(type:BuildingType, x:Int, y:Int, rotation:Rotation = NONE):Building {
		if (!isPlacementAllowed(type, x, y, rotation)) {
			throw 'Placement of building type ${type} at ($x, $y, $rotation) not allowed';
		}
		var building = new Building(type, x, y, rotation);
		buildings.push(building);
		buildingSprites.add(new BuildingSprite(building, this));
		return building;
	}

	/** Removes building. Throws error if building does not exist on grid. **/
	public function remove(building:Building) {
		if (!buildings.remove(building)) {
			throw 'Building $building not found on grid';
		}
	}

	public function onNewUpgrade(upgrade:Upgrade) {
		switch (upgrade.name) {
			case "Ecopoeisis":
				if (size >= 20) {
					throw 'Illegal state: new upgrade ${upgrade.name} but size is $size';
				}
				size = 20;
			case "Terraforming":
				if (size >= 25) {
					throw 'Illegal state: new upgrade ${upgrade.name} but size is $size';
				}
				size = 25;
			case "Planetary engineering":
				if (size >= 30) {
					throw 'Illegal state: new upgrade ${upgrade.name} but size is $size';
				}
				size = 30;
		}
		cellSize = Math.floor(totalSize / size);
	}
}

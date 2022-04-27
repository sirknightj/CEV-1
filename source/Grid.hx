package;

import Building.Rotation;
import Tree.Upgrade;

class Grid {
	public var size(default, null):Int;

	var buildings:Array<Building>;

	public function new() {
		size = 15;
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
	public function place(type:BuildingType, x:Int, y:Int, rotation:Rotation):Building {
		if (!isPlacementAllowed(type, x, y, rotation)) {
			throw 'Placement of building type ${type} at ($x, $y, $rotation) not allowed';
		}
		var building = new Building(type, x, y, rotation);
		buildings.push(building);
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
	}
}

package;

enum Rotation {
	NONE; // no rotation
	LEFT; // 90 degrees clockwise
	HALF; // 180 degrees
	RIGHT; // 90 degrees counterclockwise
}

typedef IntPoint = {
	var x:Int;
	var y:Int;
}

class Building {
	public var type(default, null):BuildingType;
	public var x(default, null):Int;
	public var y(default, null):Int;
	public var rotation(default, null):Rotation;

	public var points(default, null):Array<IntPoint> = [];

	public function new(type:BuildingType, x:Int, y:Int, rotation:Rotation) {
		this.type = type;
		this.x = x;
		this.y = y;
		this.rotation = rotation;

		for (i in 0...type.width) {
			for (j in 0...type.height) {
				if (type.shape[j][i]) {
					points.push({
						x: x + i,
						y: y + j
					});
				}
			}
		}
	}

	public function intersects(other:Building):Bool {
		// one of the buildings is to the left or above the other building
		if (x >= other.x + other.type.width || other.x >= x + type.width || y >= other.y + other.type.height || other.y >= y + type.height) {
			return false;
		}
		// check each point
		for (p1 in points) {
			for (p2 in other.points) {
				if (p1.x == p2.x && p1.y == p2.y) {
					return false;
				}
			}
		}
		return true;
	}
}

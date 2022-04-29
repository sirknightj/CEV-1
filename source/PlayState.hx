package;

import Building.Rotation;
import BuildingType.BuildingTypeFactory;
import flixel.FlxState;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import openfl.geom.Point;

class PlayState extends FlxState {
	public static final gridSize = 750;
	public static final gridPosition = new Point(50, 10);

	public var grid(default, null):Grid;
	public var tree(default, null):Tree;

	var buildingSprites:FlxTypedSpriteGroup<BuildingSprite>;

	override public function create() {
		super.create();

		buildingSprites = new FlxTypedSpriteGroup<BuildingSprite>();
		grid = new Grid(gridPosition, gridSize, buildingSprites);
		add(grid);
		tree = new Tree();
		add(buildingSprites);
		buildingSprites.setPosition(gridPosition.x, gridPosition.y);
		grid.place(BuildingTypeFactory.getById('food1'), 0, 0);
		grid.place(BuildingTypeFactory.getById('elec1'), 5, 0);
		grid.place(BuildingTypeFactory.getById('sci1'), 2, 5);
		grid.place(BuildingTypeFactory.getById('water1'), 4, 2);
	}

	public function placeBuilding(buildingTypeId:String, x:Int, y:Int) {
		var type = BuildingTypeFactory.getById(buildingTypeId);
		grid.place(type, x, y, Rotation.NONE);
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);
	}
}

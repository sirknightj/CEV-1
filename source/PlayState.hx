package;

import Building.Rotation;
import BuildingType.BuildingTypeFactory;
import Tree.Upgrade;
import flixel.FlxState;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import openfl.geom.Point;

// TODO: make intro state?
// TODO: make MenuState
// TODO: make TreeState
// TODO: make EndState

class PlayState extends FlxState {
	public static final gridSize = 750; // px width and height of the grid
	public static final gridPosition = new Point(50, 10); // (x,y) offset for the grid

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

	public function onNewUpgrade(upgrade:Upgrade) {
		// TODO: handle upgrades changing population effects
		// TODO: also call onNewUpgrade() on Grid and all the building types
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);
	}
}

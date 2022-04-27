package;

import BuildingType.BuildingTypeFactory;
import flixel.FlxState;

class PlayState extends FlxState {
	override public function create() {
		super.create();

		var text = new flixel.text.FlxText(0, 0, 0, "Hello World", 64);
		text.screenCenter();
		add(text);
		var grid = new Grid();
		var tree = new Tree();
		var buildingManager = new BuildingTypeFactory();
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);
	}
}

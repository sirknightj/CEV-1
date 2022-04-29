package;

import Tree.Upgrade;
import openfl.Assets;

class BuildingType {
	public var id(default, null):String;
	public var name(default, null):String;
	public var unlocked(default, null):Bool;
	public var shape(default, null):Array<Array<Bool>>;
	public var width(default, null):Int;
	public var height(default, null):Int;

	public var foodCost(default, null):Int;
	public var waterCost(default, null):Int;
	public var oxygenCost(default, null):Int;
	public var energyCost(default, null):Int;
	public var metalCost(default, null):Int;
	public var scienceCost(default, null):Int;

	public var foodEffect(default, null):Int;
	public var waterEffect(default, null):Int;
	public var oxygenEffect(default, null):Int;
	public var energyEffect(default, null):Int;
	public var metalEffect(default, null):Int;
	public var scienceEffect(default, null):Int;

	public function new(b:BuildingTypeJson) {
		this.id = b.id;
		this.name = b.name;
		this.unlocked = false;
		this.shape = b.shape;
		this.width = b.shape[0].length;
		this.height = b.shape.length;

		this.foodCost = b.food_cost;
		this.waterCost = b.water_cost;
		this.oxygenCost = b.oxygen_cost;
		this.energyCost = b.electricity_cost;
		this.metalCost = b.metal_cost;
		this.scienceCost = b.science_cost;
		this.foodEffect = b.food_effect;
		this.waterEffect = b.water_effect;
		this.oxygenEffect = b.oxygen_effect;
		this.energyEffect = b.electricity_effect;
		this.metalEffect = b.metal_effect;
		this.scienceEffect = b.science_effect;
	}

	public function onNewUpgrade(upgrade:Upgrade) {
		if (upgrade.unlocks == name) {
			if (unlocked) {
				throw 'Illegal state: ${upgrade.name} Unlocked ${name} (already unlocked)';
			}
			unlocked = true;
		}

		if (upgrade.name == "Genetic modification" && ["Farm", "Hydroponics farm", "Aeroponics farm"].contains(name)) {
			this.foodEffect *= 2;
		} else if (upgrade.name == "Automated mines" && ["Mine", "Automated mine"].contains(name)) {
			this.metalEffect *= 2;
		}
	}
}

typedef BuildingTypeJson = {
	var name:String;
	var id:String;
	var shape:Array<Array<Bool>>;
	var food_cost:Int;
	var water_cost:Int;
	var oxygen_cost:Int;
	var electricity_cost:Int;
	var metal_cost:Int;
	var science_cost:Int;
	var food_effect:Int;
	var water_effect:Int;
	var oxygen_effect:Int;
	var electricity_effect:Int;
	var metal_effect:Int;
	var science_effect:Int;
}

/** Singleton **/
class BuildingTypeFactory {
	private static var instance:BuildingTypeFactory;

	var buildingTypes = new Map<String, BuildingType>(); // name of BuildingType -> BuildingType

	private function new() {
		var data:Array<BuildingTypeJson> = haxe.Json.parse(Assets.getText(AssetPaths.buildings__json));
		for (v in data) {
			buildingTypes.set(v.id, new BuildingType(v));
		}
	}

	/**
		Ensures that the singleton is initialized. The reason this has to be a separate method is that the Assets library might not be available when the class is first run. Make sure to call this function in the beginning of every function.
	**/
	private static function make() {
		if (instance == null) {
			instance = new BuildingTypeFactory();
		}
	}

	/** Returns all building types. **/
	public static function getAll():Array<BuildingType> {
		make();
		return [for (v in instance.buildingTypes.iterator()) v];
	}

	/** Returns all unlocked building types. **/
	public static function getUnlocked():Array<BuildingType> {
		make();
		return [for (v in instance.buildingTypes.iterator()) if (v.unlocked) v];
	}

	public static function getByName(name:String):BuildingType {
		make();
		for (b in instance.buildingTypes.iterator()) {
			if (b.name == name) {
				return b;
			}
		}
		throw 'No building type exists with name "$name"';
	}

	public static function getById(id:String):BuildingType {
		make();
		if (!instance.buildingTypes.exists(id)) {
			throw 'No building type exists with id "$id"';
		}
		return instance.buildingTypes.get(id);
	}

	public static function onNewUpgrade(upgrade:Upgrade) {
		make();
		for (b in instance.buildingTypes) {
			b.onNewUpgrade(upgrade);
		}
	}
}

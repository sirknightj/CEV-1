package;

import haxe.ds.ReadOnlyArray;
import openfl.Assets;

typedef UpgradeJson = {
	var name:String;
	var prereqs:Array<String>;
	var type:String;
	var description:String;
	var effects:String;
	var unlocks:String;
	var electricity_cost:Int;
	var metal_cost:Int;
	var science_cost:Int;
	var starting:Bool;
	var x:Int;
	var y:Int;
}

enum UpgradeType {
	Science;
	Building;
}

class Upgrade {
	public var name(default, null):String;
	public var prereqs(default, null):ReadOnlyArray<String>;
	public var type(default, null):UpgradeType;
	public var description(default, null):String;
	public var effects(default, null):String;
	public var unlocks(default, null):String; // building that this unlocks
	public var electricity_cost(default, null):Int;
	public var metal_cost(default, null):Int;
	public var science_cost(default, null):Int;
	public var unlocked(default, null):Bool; // true iff upgrade bought
	public var available(default, null):Bool; // true iff all prereqs bought (available items are a subset of unlocked items)
	public var x(default, null):Int; // x position of node in tree layout
	public var y(default, null):Int; // y position of node in tree layout

	var tree(null, null):Tree; // reference to the containing Tree

	public function new(u:UpgradeJson, tree:Tree) {
		this.name = u.name;
		this.prereqs = u.prereqs == null ? new Array<String>() : u.prereqs;
		this.type = u.type.toLowerCase() == "science" ? UpgradeType.Science : UpgradeType.Building;
		this.description = u.description;
		this.effects = u.effects;
		this.unlocks = u.unlocks;
		this.electricity_cost = u.electricity_cost;
		this.metal_cost = u.metal_cost;
		this.science_cost = u.science_cost;
		this.unlocked = u.starting;
		this.available = false; // correctly set by recalculateAvailable later
		this.x = u.x;
		this.y = u.y;
		this.tree = tree;
	}

	public function unlock() {
		if (unlocked) {
			throw 'Upgrade "${name}" is already unlocked';
		} else if (!available) {
			throw 'Upgrade "${name}" is unavailable';
		}

		unlocked = true;
		tree.recalculateAvailable();
	}

	public function recalculateAvailable() {
		if (!available) {
			for (p in prereqs) {
				if (!tree.get(p).unlocked) {
					return;
				}
			}
			available = true;
		}
	}
}

class Tree {
	var upgrades = new Map<String, Upgrade>(); // name of Upgrade -> Upgrade

	public function new() {
		var upgradeData:Array<UpgradeJson> = haxe.Json.parse(Assets.getText(AssetPaths.tree__json));
		for (v in upgradeData) {
			upgrades.set(v.name, new Upgrade(v, this));
		}
		recalculateAvailable();
	}

	public function getAll():Array<Upgrade> {
		return [for (v in upgrades.iterator()) v];
	}

	/** Returns all unlocked upgrades. **/
	public function getUnlocked():Array<Upgrade> {
		return [for (v in upgrades.iterator()) if (v.unlocked) v];
	}

	/** Returns all available upgrades. This is a superset of unlocked upgrades. **/
	public function getAvailable():Array<Upgrade> {
		return [for (v in upgrades.iterator()) if (v.available) v];
	}

	/** Returns all available upgrades that have not been unlocked. **/
	public function getLockedAvailable():Array<Upgrade> {
		return [for (v in upgrades.iterator()) if (v.available && !v.unlocked) v];
	}

	/** Returns the Upgrade with the given name. **/
	public function get(name:String):Upgrade {
		if (!upgrades.exists(name)) {
			throw 'No upgrade exists with name "$name"';
		}
		return upgrades.get(name);
	}

	/** (Called internally by Upgrade) Recalculates the `available` field of all Upgrades. **/
	public function recalculateAvailable() {
		for (v in upgrades) {
			v.recalculateAvailable();
		}
	}
}
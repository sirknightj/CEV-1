# CEV-1

CEV-1 is a tile-based resource management game. The player is an AI in charge of a new Mars colony. The objective function is to "ensure colonists survive" by placing buildings onto a grid that generate resources such as food and water which colonists consume. The player can "research" upgrades and unlock new, more efficient buildings through a tech tree, allowing them to support an exponentially growing population. The player wins when they create a post-scarcity economy where no humans can die and resource production is greater than resource consumption.

You can try out the game on [itch.io](https://sirknightj.itch.io/cev-1) or on [crazygames.com](https://www.crazygames.com/game/cev-1).

### Developer Contact

* Vishal - vishald [at] cs [dot] washington [dot] edu
* Jeremy - jeremyg1 [at] cs [dot] washington [dot] edu
* Joshua - froast [at] cs [dot] washington [dot] edu

# Developing CEV-1

TODO: Write CEV-1's behind the scenes

## Prerequisites

Install GODOT from the [website](https://godotengine.org/download).

* Unzip the file and run the executable.

Also make sure to have [nodejs](https://nodejs.org/en/) installed. We use this to test the game outside of the GODOT editor.

## Development

* On the GODOT opening screen, import the project by clicking "Import" and then locating the file [`source/project.godot`](source/project.godot).

## Playing the game in the editor

* Click the `Play` button in the top-right corner of the GODOT editor.
* A game window will pop up.

## Preparing for release:

* Export the game by heading to `Project > Export` on the top-left of the GODOT editor.
* Use the `HTML5 (Runnable)` preset and choose `Export All`.
* This will output the project into the `export/` directory.
* In a terminal window, `cd` into the `export/` directory and use `npx http-server` to start up a local web server to serve you the game files.
* Visit any of the URLs that `http-server` outputs to test that the game is working as intended.

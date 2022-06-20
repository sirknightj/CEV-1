# CEV-1

## Prerequisites

Install GODOT from the [website](https://godotengine.org/download).

Unzip the file and run the executable.

Also make sure to have [nodejs](https://nodejs.org/en/) installed.

## Development

* Import the project by clicking "Import" and then locating the file `source/project.godot`.

## Playing the game in the editor

* Click the `Play` button in the top-right corner of the GODOT editor.
* A game window will pop up.

## Preparing for release:

* Export the game by heading to `Project > Export` on the top-left of the GODOT editor.
* Use the `HTML5 (Runnable)` preset and choose `Export All`.
* This will output the project into the `export/` directory.
* In a terminal window, `cd` into the `export/` directory and use `npx http-server` to start up a local web server to serve you the game files.
* Visit any of the URLs that `http-server` outputs to test that the game is working as intended.

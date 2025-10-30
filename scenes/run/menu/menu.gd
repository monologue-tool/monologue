## Menu control for the dialogue run/playback window.
##
## Provides options to run the dialogue or exit, with support for custom
## starting nodes and language selection.
extends Control

## Path to the dialogue file being run.
var file_path: String

## Optional custom starting node ID.
var from_node: Variant


## Initializes the menu and shows custom node label if applicable.
func _ready():
	%CustomIDLabel.hide()
	if from_node != null and from_node != "":
		%CustomIDLabel.text = "(custom start node: " + from_node + ")"
		%CustomIDLabel.show()


## Loads and runs the dialogue scene.
##
## [param scene] The PackedScene to instantiate and run.
func load_scene(scene):
	var main_scene = scene.instantiate()
	main_scene.from_node = from_node if from_node else ""
	main_scene.file_path = file_path
	main_scene.locale = str(GlobalVariables.language_switcher.get_current_language())
	get_window().add_scene(main_scene)
	queue_free()


## Handles the leave button press by closing the window.
func _on_leave_button_pressed():
	get_window().queue_free()


## Handles the run button press by loading the main dialogue scene.
func _on_run_button_pressed():
	var scene = preload("res://scenes/run/main/main.tscn")
	load_scene(scene)

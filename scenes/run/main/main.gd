## Main dialogue playback control.
##
## Manages the MonologueProcess for executing dialogue timelines.
## Handles starting dialogue and returning to the menu.
extends Control


## Reference to the MonologueProcess for timeline execution.
@onready var process: MonologueProcess = $MonologueProcess

## Optional custom starting node ID.
var from_node: String

## Path to the dialogue file being played.
var file_path: String

## Locale/language for dialogue playback.
var locale: String


## Initializes and starts dialogue timeline playback.
func _ready() -> void:
	var timeline: MonologueTimeline = process.preload_timeline(file_path)
	process.start_timeline(timeline, from_node)


## Handles quit button press by returning to the menu.
func _on_quit_btn_pressed() -> void:
	var menu_instance = load("res://scenes/run/menu/menu.tscn")
	var menu_scene_instance = menu_instance.instantiate()
	menu_scene_instance.from_node = from_node
	menu_scene_instance.file_path = file_path
	get_window().add_scene(menu_scene_instance)
	
	queue_free()

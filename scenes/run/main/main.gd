extends Control


@onready var process: MonologueProcess = $MonologueProcess

var from_node: String
var file_path: String
var locale: String


func _ready() -> void:
	var timeline: MonologueTimeline = process.preload_timeline(file_path)
	process.start_timeline(timeline, from_node)


func _on_quit_btn_pressed() -> void:
	var menu_instance = load("res://scenes/run/menu/menu.tscn")
	var menu_scene_instance = menu_instance.instantiate()
	menu_scene_instance.from_node = from_node
	menu_scene_instance.file_path = file_path
	get_window().add_scene(menu_scene_instance)
	
	queue_free()

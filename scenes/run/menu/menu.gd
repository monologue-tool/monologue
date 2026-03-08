extends Control

var file_path: String
var from_node: Variant


func _ready() -> void:
	%CustomIDLabel.hide()
	if from_node != null and from_node != "":
		%CustomIDLabel.text = "(custom start node: " + from_node + ")"
		%CustomIDLabel.show()


func load_scene(scene: PackedScene) -> void:
	var main_scene: Node = scene.instantiate()
	main_scene.from_node = from_node if from_node else ""
	main_scene.file_path = file_path
	var storyline := StorylineManager.get_active_storyline()
	main_scene.locale = storyline.active_language_code if storyline else "en"
	get_window().add_scene(main_scene)
	queue_free()


func _on_leave_button_pressed() -> void:
	get_window().queue_free()


func _on_run_button_pressed() -> void:
	var scene: PackedScene = preload("res://scenes/run/main/main.tscn")
	load_scene(scene)

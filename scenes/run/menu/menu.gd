extends Control


var file_path: String
var from_node: Variant


func _ready():
	%CustomIDLabel.hide()
	if from_node != null:
		%CustomIDLabel.text = "(custom start node: " + from_node + ")"
		%CustomIDLabel.show()

func load_scene(scene):
	var main_scene = scene.instantiate()
	main_scene.from_node = from_node
	main_scene.file_path = file_path
	main_scene.locale = str(GlobalVariables.language_switcher.get_current_language())
	get_window().add_child(main_scene)
	
	queue_free()


func _on_leave_button_pressed():
	get_window().queue_free()

func _on_run_button_pressed():
	var scene = preload("res://scenes/run/main/main.tscn")
	load_scene(scene)

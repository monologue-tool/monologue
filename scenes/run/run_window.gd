## Window for running/playing dialogue in test mode.
##
## Creates a separate window with a viewport for testing dialogue playback
## from the editor. Supports starting from a custom node.
class_name RunWindow extends Window

## Preloaded menu scene for the run window.
@onready var test_instance := preload("res://scenes/run/menu/menu.tscn")

## Path to the dialogue file to run.
var file_path: String

## Optional custom starting node ID.
var from_node: Variant


## Initializes and shows the run window.
##
## Creates the menu scene and displays it in a subviewport.
func _ready() -> void:
	hide()
	close_requested.connect(_on_close_requested)
	size = Vector2(1440, 810)
	force_native = true
	transient = true

	var test_scene = test_instance.instantiate()
	if from_node:
		test_scene.from_node = from_node
	test_scene.file_path = file_path
	add_scene(test_scene)

	move_to_center.call_deferred()
	show()


## Handles window close requests by freeing the window.
func _on_close_requested() -> void:
	queue_free()
	

## Adds a scene to the run window's subviewport.
##
## [param child] The node to add as a scene.
func add_scene(child: Node) -> void:
	$SubViewportContainer/SubViewport.add_child(child)

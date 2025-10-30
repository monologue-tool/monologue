class_name RunWindow extends Window

@onready var test_instance := preload("res://scenes/run/menu/menu.tscn")

var file_path: String
var from_node: Variant


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


func _on_close_requested() -> void:
	queue_free()
	

func add_scene(child: Node) -> void:
	$SubViewportContainer/SubViewport.add_child(child)

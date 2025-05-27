class_name GraphNodePicker extends Window


## Reference to the tab switcher so that the picker knows which tab it is in.
@export var switcher: GraphEditSwitcher


## The node in which the picker was spawned/dragged from.
var from_node: String
## The port in which the picker was spawned/dragged from.
var from_port: int
## Mouse release global position.
var release = null
## Release position adjusted to the graph's scroll and zoom.
var graph_release = null
## Center position of the graph.
var center = null


func _ready():
	hide()
	force_native = true
	GlobalSignal.add_listener("enable_picker_mode", _on_enable_picker_mode)


func _on_enable_picker_mode(node: String = "", port: int = -1, mouse_pos = null,
			graph_release_pos = null, center_pos = null):
	if switcher.current.file_path:
		from_node = node
		from_port = port
		release = mouse_pos
		graph_release = graph_release_pos
		center = center_pos
		
		if from_node != "":
			position = Vector2i(release) + get_tree().get_root().position
		else:
			var mouse_position =  Vector2i(get_parent().get_global_mouse_position())
			position = get_tree().get_root().position + mouse_position
		current_screen = get_tree().get_root().current_screen
		
		%Tree._load()
		show()


func close() -> void:
	hide()


func flush() -> void:
	from_node = ""
	from_port = -1
	release = null
	graph_release = null
	center = null


func _on_close_requested() -> void: close()
func _on_cancel_button_pressed() -> void: close()
func _on_create_button_pressed() -> void: close()


func _on_visibility_changed() -> void:
	var root_screen: int = get_tree().get_root().current_screen
	current_screen = root_screen


func _on_tree_button_clicked(_item: TreeItem, _column: int, id: int, _mouse_button_index: int) -> void:
	if id == 1:
		GlobalSignal.emit("add_graph_node", ["DefineCustom", self])
		close()

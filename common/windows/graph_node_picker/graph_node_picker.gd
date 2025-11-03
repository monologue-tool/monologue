class_name GraphNodePicker extends Window

## Reference to the tab switcher so that the picker knows which tab it is in.
@onready var switcher := %GraphEditSwitcher
@onready var node_tree := %GraphNodeTree

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


func _on_enable_picker_mode(
	node: String = "",
	port: int = -1,
	mouse_pos = null,
	graph_release_pos = null,
	center_pos = null,
	center_window: bool = false
):
	open_for_node(node, port, mouse_pos, graph_release_pos, center_pos, center_window)


#
#if from_node != "":
#position = Vector2i(release) + get_tree().get_root().position
#else:
#var mouse_position = Vector2i(get_parent().get_global_mouse_position())
#position = get_tree().get_root().position + mouse_position
#current_screen = get_tree().get_root().current_screen
#show()
#
#if center_window:
#move_to_center()


func close() -> void:
	hide()


func flush() -> void:
	from_node = ""
	from_port = -1
	release = null
	graph_release = null
	center = null


func open_for_node(
	node: String = "",
	port: int = -1,
	mouse_pos = null,
	graph_release_pos = null,
	center_pos = null,
	_center_window: bool = false
) -> void:
	flush()
	from_node = node
	from_port = port
	release = mouse_pos
	graph_release = graph_release_pos
	center = center_pos

	if node_tree:
		node_tree.reload_tree()
		node_tree.grab_focus()

	popup()
	move_to_center()

	var root_window := get_tree().get_root()
	if root_window:
		current_screen = root_window.current_screen

	grab_focus()


func _on_close_requested() -> void:
	close()


func _on_cancel_button_pressed() -> void:
	close()


func _on_create_button_pressed() -> void:
	if node_tree.create_selected_descriptor():
		close()


func _on_visibility_changed() -> void:
	var root_screen: int = get_tree().get_root().current_screen
	current_screen = root_screen

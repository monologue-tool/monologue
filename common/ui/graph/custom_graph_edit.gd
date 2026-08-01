## Represents the graph area which creates and connects MonologueGraphNodes.
class_name CustomGraphEdit extends GraphEdit

const SCROLLBAR_OVERRIDE_KEYS: Array[String] = ["grabber", "scroll"]

## True while the user is dragging a wire. Rebuilding a node during that window moves
## the ports out from under GraphEdit mid-drag, which is what used to leave a box
## selection behind instead of a connection.
var connecting_mode: bool
var mouse_hovering: bool = false


func _ready() -> void:
	_hide_default_scrollbars()

	connection_drag_started.connect(_on_connection_drag_started)
	connection_drag_ended.connect(_on_connection_drag_ended)


func scroll_to_node(graph_node: GraphNode) -> void:
	for child: Node in get_children():
		if child is GraphNode:
			(child as GraphNode).selected = false
	graph_node.selected = true

	var node_center: Vector2 = graph_node.position_offset + graph_node.size / 2.0
	scroll_offset = node_center * zoom - get_rect().size / 2.0


func _hide_default_scrollbars() -> void:
	for child: Node in get_children(true):
		if child is GraphNode:
			continue
		for subchild: Node in child.get_children(true):
			if not subchild is ScrollBar:
				continue
			for key: String in SCROLLBAR_OVERRIDE_KEYS:
				subchild.add_theme_stylebox_override(key, StyleBoxEmpty.new())


func _on_connection_to_empty(node: String, port: int, release: Vector2) -> void:
	var center: Vector2 = (get_local_mouse_position() + scroll_offset) / zoom
	var graph_release: Vector2 = (release + scroll_offset) / zoom
	EventBus.enable_picker_mode.emit(node, port, release, graph_release, center)


func _on_gui_input(event: InputEvent) -> void:
	if mouse_hovering:
		var cursor_drag: bool = Input.is_action_pressed("Spacebar")
		var cursor_hand_closed: bool = (
			cursor_drag and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		)
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
			cursor_hand_closed = true
		if cursor_hand_closed:
			DisplayServer.cursor_set_custom_image(Cursor.CLOSED_HAND)
		elif cursor_drag:
			DisplayServer.cursor_set_custom_image(Cursor.HAND)
		else:
			DisplayServer.cursor_set_custom_image(Cursor.ARROW)

	if (
		event is InputEventMouseButton
		and event.is_pressed()
		and event.button_index == MOUSE_BUTTON_LEFT
	):
		EventBus.show_languages.emit(false)


func _on_connection_drag_started(_from_node: StringName, _from_port: int, _is_output: bool) -> void:
	connecting_mode = true


func _on_connection_drag_ended() -> void:
	connecting_mode = false


func _on_mouse_entered() -> void:
	mouse_hovering = true


func _on_mouse_exited() -> void:
	DisplayServer.cursor_set_custom_image(null)
	mouse_hovering = false

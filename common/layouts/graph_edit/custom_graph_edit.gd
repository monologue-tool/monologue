## Represents the graph area which creates and connects MonologueGraphNodes.
class_name CustomGraphEdit extends GraphEdit

const SCROLLBAR_OVERRIDE_KEYS := ["grabber", "scroll"]

var undo_redo: HistoryHandler:
	get = get_undo_redo

var context_id: String = IDGen.generate()
var version: int

var connecting_mode: bool
var mouse_hovering: bool = false


func _ready() -> void:
	UndoRedoService.create_context(context_id)
	version = undo_redo.get_version()
	_hide_default_scrollbars()


func get_undo_redo() -> HistoryHandler:
	return UndoRedoService.get_context(context_id)


func update_version() -> void:
	version = undo_redo.get_version()


func is_unsaved() -> bool:
	return version != undo_redo.get_version()


func _hide_default_scrollbars() -> void:
	for child in get_children(true):
		if child is GraphNode:
			continue
		for subchild in child.get_children(true):
			if subchild is ScrollBar:
				for key in SCROLLBAR_OVERRIDE_KEYS:
					subchild.add_theme_stylebox_override(key, StyleBoxEmpty.new())


func _on_connection_drag_started(_from_node, _from_port, _is_output) -> void:
	connecting_mode = true


func _on_connection_drag_ended() -> void:
	connecting_mode = false


func _on_disconnection_request(
	from_node: StringName, from_port: int, to_node: StringName, to_port: int
) -> void:
	var storyline_id: String = get("storyline_id")
	var from_property := ""
	var to_property := ""
	if has_method("get_property_name_at_port"):
		var from_value = call("get_property_name_at_port", from_node, from_port, true)
		var to_value = call("get_property_name_at_port", to_node, to_port, false)
		if typeof(from_value) == TYPE_STRING:
			from_property = from_value
		if typeof(to_value) == TYPE_STRING:
			to_property = to_value

	if storyline_id.is_empty() or from_property.is_empty() or to_property.is_empty():
		disconnect_node(from_node, from_port, to_node, to_port)
		return

	var storyline: StorylineDocument = StorylineManager.get_storyline(storyline_id)
	if not storyline or not storyline.history:
		disconnect_node(from_node, from_port, to_node, to_port)
		return

	var command := NodeConnectionCommand.new(self, from_node, to_node, from_property, to_property)
	storyline.history.execute(command)


func _on_connection_to_empty(node: String, port: int, release: Vector2) -> void:
	var center = (get_local_mouse_position() + scroll_offset) / zoom
	var graph_release = (release + scroll_offset) / zoom
	GlobalSignal.emit("enable_picker_mode", [node, port, release, graph_release, center])


func _on_gui_input(event: InputEvent) -> void:
	if mouse_hovering:
		var cursor_drag := Input.is_action_pressed("Spacebar")
		var cursor_hand_closed := cursor_drag and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
			cursor_hand_closed = true
		if cursor_hand_closed:
			DisplayServer.cursor_set_custom_image(Cursor.closed_hand)
		elif cursor_drag:
			DisplayServer.cursor_set_custom_image(Cursor.hand)
		else:
			DisplayServer.cursor_set_custom_image(Cursor.arrow)

	if (
		event is InputEventMouseButton
		and event.is_pressed()
		and event.button_index == MOUSE_BUTTON_LEFT
	):
		GlobalSignal.emit("show_languages", [false])


func _on_mouse_entered() -> void:
	mouse_hovering = true


func _on_mouse_exited() -> void:
	DisplayServer.cursor_set_custom_image(null)
	mouse_hovering = false

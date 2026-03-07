## Represents the graph area which creates and connects MonologueGraphNodes.
class_name CustomGraphEdit extends GraphEdit

const SCROLLBAR_OVERRIDE_KEYS := ["grabber", "scroll"]

var connecting_mode: bool
var mouse_hovering: bool = false


func _ready() -> void:
	_hide_default_scrollbars()


func _hide_default_scrollbars() -> void:
	for child in get_children(true):
		if child is GraphNode:
			continue
		for subchild in child.get_children(true):
			if subchild is ScrollBar:
				for key in SCROLLBAR_OVERRIDE_KEYS:
					subchild.add_theme_stylebox_override(key, StyleBoxEmpty.new())


func _on_connection_to_empty(node: String, port: int, release: Vector2) -> void:
	var center = (get_local_mouse_position() + scroll_offset) / zoom
	var graph_release = (release + scroll_offset) / zoom
	EventBus.enable_picker_mode.emit(node, port, release, graph_release, center)


func _on_gui_input(event: InputEvent) -> void:
	if mouse_hovering:
		var cursor_drag := Input.is_action_pressed("Spacebar")
		var cursor_hand_closed := cursor_drag and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
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


func _on_mouse_entered() -> void:
	mouse_hovering = true


func _on_mouse_exited() -> void:
	DisplayServer.cursor_set_custom_image(null)
	mouse_hovering = false

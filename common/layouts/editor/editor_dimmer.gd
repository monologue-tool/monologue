extends ColorRect

var _focus_nodes: Array = []
var request_count: int = 0


func _ready() -> void:
	hide()
	GlobalSignal.add_listener("show_dimmer", _on_show_dimmer)
	GlobalSignal.add_listener("hide_dimmer", _on_hide_dimmer)


func _on_show_dimmer(focus_node: Node = null) -> void:
	if focus_node and not focus_node in _focus_nodes:
		_focus_nodes.append(focus_node)

	request_count = max(1, request_count + 1)
	show()


func _on_hide_dimmer(focus_node: Node = null) -> void:
	if focus_node and focus_node in _focus_nodes:
		focus_node.hide()
		_focus_nodes.erase(focus_node)

	request_count = max(0, request_count - 1)
	if request_count == 0:
		hide()


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		for node in _focus_nodes:
			node.hide()
		request_count = 0
		hide()

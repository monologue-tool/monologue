extends ColorRect


var request_count: int = 0


func _ready() -> void:
	hide()
	GlobalSignal.add_listener("show_dimmer", _on_show_dimmer)
	GlobalSignal.add_listener("hide_dimmer", _on_hide_dimmer)


func _on_show_dimmer(_focus_node: Node = null) -> void:
	request_count = max(1, request_count+1)
	show()


func _on_hide_dimmer(_focus_node: Node = null) -> void:
	request_count = max(0, request_count-1)
	if request_count == 0:
		hide()

extends PanelContainer

const SCROLL_CONTAINER_MAX_SIZE: int = 200

@export var graph_edit_switcher: GraphEditSwitcher

@onready var line_edit: LineEdit = %LineEdit


func focus() -> void:
	line_edit.grab_focus()
	line_edit.select_all()
	
	_on_h_box_resized()


func _on_line_edit_text_changed(new_text: String) -> void:
	var graph_edit: MonologueGraphEdit = graph_edit_switcher.current
	var all_nodes: Array = graph_edit.get_nodes()
	
	for node: MonologueGraphNode in all_nodes:
		if node.node_type.containsn(new_text):
			continue


func _on_h_box_resized() -> void:
	%ScrollContainer.custom_minimum_size.y = min(%HintVBox.size.y, SCROLL_CONTAINER_MAX_SIZE)

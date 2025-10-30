## Search bar for filtering nodes in the graph editor.
##
## Provides a text input for searching nodes by type, with automatic
## scroll container sizing for search results.
extends PanelContainer

## Maximum height for the scroll container showing search results.
const SCROLL_CONTAINER_MAX_SIZE: int = 200

## Reference to the graph edit switcher containing the active graph.
@export var graph_edit_switcher: GraphEditSwitcher

## Reference to the search input line edit.
@onready var line_edit: LineEdit = %LineEdit


## Focuses the search bar and selects all text.
##
## Also adjusts the scroll container size.
func focus() -> void:
	line_edit.grab_focus()
	line_edit.select_all()
	
	_on_h_box_resized()


## Handles text changes in the search input.
##
## Filters nodes based on the search text (currently incomplete implementation).
## [br][br]
## [param new_text] The new search text.
func _on_line_edit_text_changed(new_text: String) -> void:
	var graph_edit: MonologueGraphEdit = graph_edit_switcher.current
	var all_nodes: Array = graph_edit.get_nodes()
	
	for node: MonologueGraphNode in all_nodes:
		if node.node_type.containsn(new_text):
			continue


## Adjusts scroll container size when the hint box is resized.
func _on_h_box_resized() -> void:
	%ScrollContainer.custom_minimum_size.y = min(%HintVBox.size.y, SCROLL_CONTAINER_MAX_SIZE)

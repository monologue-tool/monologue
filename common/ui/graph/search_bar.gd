extends HBoxContainer
 
@onready var search_input: LineEdit = %SearchBarInput
 
@export var graph_edit: MonologueGraphEdit

var _results: Array[InspectableNode] = []
var _current_index: int = -1
 
 
func _ready() -> void:
	assert(graph_edit != null)
	
	search_input.text_changed.connect(_on_text_changed)
	search_input.gui_input.connect(_on_search_gui_input)
	_refresh_ui()
 
  
func _on_search_gui_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.is_pressed():
		return
	match event.keycode:
		KEY_ESCAPE:
			accept_event()
		KEY_ENTER, KEY_KP_ENTER:
			_navigate(-1 if event.shift_pressed else 1)
			accept_event()
		KEY_UP:
			_navigate(-1)
			accept_event()
		KEY_DOWN:
			_navigate(1)
			accept_event()
 
 
func _on_text_changed(text: String) -> void:
	_run_search(text)
 
 
func _run_search(query: String) -> void:
	_results.clear()
	_current_index = -1
 
	if not query.is_empty() and graph_edit:
		var q: String = query.to_lower()
		for graph_node: GraphNode in graph_edit.get_all_graph_nodes():
			var node: InspectableNode = graph_edit._node_map.get(graph_node)
			if node and _node_matches(node, q):
				_results.append(node)
 
		if not _results.is_empty():
			_current_index = 0
			_focus_current()
 
	_refresh_ui()
 
 
func _node_matches(node: InspectableNode, query_lower: String) -> bool:
	# TODO: Improve query
	
	for property: Property in node.get_properties():
		var value: Variant = property.get_value()
		if value is String and value.to_lower().contains(query_lower):
			return true
	return false
 
  
func _navigate(direction: int) -> void:
	if _results.is_empty():
		return
	_current_index = posmod(_current_index + direction, _results.size())
	_focus_current()
	_refresh_ui()
 
 
func _focus_current() -> void:
	if _current_index < 0 or _current_index >= _results.size():
		return
	var node: InspectableNode = _results[_current_index]
	if not is_instance_valid(node) or not is_instance_valid(node.graph_view):
		return
	graph_edit.scroll_to_node(node.graph_view)
 
  
func _refresh_ui() -> void:
	var has_results: bool = not _results.is_empty()
 
	if not has_results:
		pass
		# TODO: Maybe do something

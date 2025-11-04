## Consists of a TabBar which allows the user to switch between GraphEdits.
## Saving and loading of GraphEdit data is handled by MonologueEditor.
class_name GraphEditSwitcher extends VBoxContainer

var graph_edit_scene = preload("res://common/layouts/graph_edit/monologue_graph_edit.tscn")
var prompt_scene = preload("res://common/windows/prompt_window/prompt_window.tscn")
const NodeSelectionCommandResource := preload("res://logic/history/node_selection_command.gd")

@onready var inspector_panel: InspectorPanel = %Inspector
@onready var tab_bar: TabBar = %TabBar
@onready var graph_container: Control = %GraphEdits

var graph_edits: Dictionary = {}
var _selected_nodes: Dictionary = {}  # storyline_id -> InspectableNode
var _is_applying_selection: bool = false


func _init() -> void:
	StorylineManager.add_observer(self)


func _ready() -> void:
	GlobalSignal.add_listener("request_node_inspection", _on_request_node_inspection)


func _exit_tree() -> void:
	GlobalSignal.remove_listener("request_node_inspection", _on_request_node_inspection)


func refresh() -> void:
	var graph_ids: Array = []
	var doc_ids: Array = StorylineManager.get_storyline_ids()

	for graph: MonologueGraphEdit in graph_container.get_children():
		graph_ids.append(graph.storyline_id)
		graph_edits[graph.storyline_id] = graph

	var diff: Array = _array_diff(graph_ids, doc_ids)
	for id: String in diff:
		var new_graph: MonologueGraphEdit = graph_edit_scene.instantiate()
		new_graph.node_view_selected.connect(_on_node_selected.bind(id))
		new_graph.storyline_id = id
		graph_container.add_child(new_graph)
		graph_edits[id] = new_graph

	var current_graph: MonologueGraphEdit = graph_edits.get(
		StorylineManager.get_active_storyline().id
	)
	if current_graph:
		current_graph.refresh()


func refresh_graph(graph_id: String) -> void:
	var storyline: StorylineDocument = StorylineManager.get_storyline(graph_id)

	for node in storyline.nodes:
		var _graph_view


func on_storyline_change() -> void:
	refresh()


func _on_node_selected(node: InspectableNode, storyline_id: String) -> void:
	request_node_selection(node, storyline_id)


func _on_request_node_inspection(
	node: InspectableNode, storyline_id: String = "", skip_history: bool = false
) -> void:
	var target_storyline_id := storyline_id
	if target_storyline_id.is_empty() and node:
		target_storyline_id = node.storyline_id
	if target_storyline_id.is_empty():
		return
	request_node_selection(node, target_storyline_id, skip_history)


func request_node_selection(
	node: InspectableNode, storyline_id: String, skip_history: bool = false
) -> void:
	if _is_applying_selection:
		return

	var current_node: InspectableNode = _selected_nodes.get(storyline_id)
	var needs_selection_update := current_node != node
	if not needs_selection_update:
		var graph: MonologueGraphEdit = graph_edits.get(storyline_id)
		if graph and node and is_instance_valid(node.graph_view):
			needs_selection_update = not node.graph_view.selected

	if not needs_selection_update and inspector_panel.current_object == node:
		return

	if skip_history:
		_apply_selection(node, storyline_id)
		return

	var storyline: StorylineDocument = StorylineManager.get_storyline(storyline_id)
	var history: CommandManager = storyline.history if storyline else null
	if not history:
		_apply_selection(node, storyline_id)
		return

	var command := NodeSelectionCommandResource.new(
		storyline_id, current_node, node, Callable(self, "_apply_selection")
	)

	history.execute(command, UndoRedo.MERGE_ENDS)


func _apply_selection(node: InspectableNode, storyline_id: String) -> void:
	_is_applying_selection = true

	if node:
		_selected_nodes[storyline_id] = node
	else:
		_selected_nodes.erase(storyline_id)

	var graph: MonologueGraphEdit = graph_edits.get(storyline_id)
	if graph:
		if node and is_instance_valid(node.graph_view):
			graph.set_selected(node.graph_view)
		else:
			graph.clear_selection()

	if inspector_panel.current_object != node:
		inspector_panel.inspect(node)

	_is_applying_selection = false


func _array_diff(arr1: Array, arr2: Array) -> Array:
	var temp_arr2 = arr2.duplicate()

	for item in arr1:
		temp_arr2.erase(item)

	return temp_arr2

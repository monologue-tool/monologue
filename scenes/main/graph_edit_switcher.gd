## Consists of a TabBar which allows the user to switch between GraphEdits.
## Saving and loading of GraphEdit data is handled by MonologueEditor.
class_name GraphEditSwitcher extends VBoxContainer

var graph_edit_scene = preload("res://common/layouts/graph_edit/monologue_graph_edit.tscn")
var prompt_scene = preload("res://common/windows/prompt_window/prompt_window.tscn")

@onready var inspector_panel: InspectorPanel = %Inspector
@onready var tab_bar: TabBar = %TabBar
@onready var graph_container: Control = %GraphEdits

var graph_edits: Dictionary = {}


func _init() -> void:
	StorylineManager.add_observer(self)


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
		var graph_preview


func on_storyline_change() -> void:
	refresh()


func _on_node_selected(node: InspectableNode, _storyline_id: String) -> void:
	inspector_panel.inspect(node)


func _array_diff(arr1: Array, arr2: Array) -> Array:
	var temp_arr2 = arr2.duplicate()

	for item in arr1:
		temp_arr2.erase(item)

	return temp_arr2

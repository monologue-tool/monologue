## Consists of a TabBar which allows the user to switch between GraphEdits.
## Saving and loading of GraphEdit data is handled by MonologueEditor.
class_name GraphContainer extends VBoxContainer

var prompt_scene = preload("res://common/windows/prompt_window/prompt_window.tscn")

@export var inspector_panel: InspectorPanel
@onready var graph: MonologueGraphEdit = %GraphEdit

var _selected_nodes: Dictionary = {}  # storyline_id -> InspectableNode
var _is_applying_selection: bool = false


func _ready() -> void:
	GlobalSignal.add_listener("request_node_inspection", _on_request_node_inspection)
	StorylineManager.storyline_changed.connect(refresh)


func refresh() -> void:
	graph.storyline_id = StorylineManager.get_active_storyline().id
	graph.refresh()


func _on_graph_edit_node_view_selected(node: InspectableNode) -> void:
	request_node_selection(node)


func _on_request_node_inspection(
	node: InspectableNode, storyline_id: String = "", skip_history: bool = false
) -> void:
	var target_storyline_id := storyline_id
	if target_storyline_id.is_empty() and node:
		target_storyline_id = node.storyline_id
	if target_storyline_id.is_empty():
		return
	request_node_selection(node, skip_history)


func request_node_selection(node: InspectableNode, skip_history: bool = false) -> void:
	if _is_applying_selection:
		return

	var storyline: StorylineDocument = StorylineManager.get_active_storyline()
	var current_node: InspectableNode = _selected_nodes.get(storyline.id)
	var needs_selection_update := current_node != node
	if not needs_selection_update:
		if graph and node and is_instance_valid(node.graph_view):
			needs_selection_update = not node.graph_view.selected

	if not needs_selection_update and inspector_panel.current_object == node:
		return

	if skip_history:
		_apply_selection(node, storyline.id)
		return

	var history: CommandManager = storyline.history if storyline else null
	if not history:
		_apply_selection(node, storyline.id)
		return

	var command := NodeSelectionCommand.new(
		storyline.id, current_node, node, Callable(self, "_apply_selection")
	)

	history.execute(command, UndoRedo.MERGE_ENDS)


func _apply_selection(node: InspectableNode, storyline_id: String) -> void:
	_is_applying_selection = true

	if node:
		_selected_nodes[storyline_id] = node
	else:
		_selected_nodes.erase(storyline_id)

	if node and is_instance_valid(node.graph_view):
		graph.set_selected(node.graph_view)

	if inspector_panel.current_object != node:
		inspector_panel.inspect(node)

	_is_applying_selection = false

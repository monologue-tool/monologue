## Consists of a TabBar which allows the user to switch between GraphEdits.
## Saving and loading of GraphEdit data is handled by MonologueEditor.
class_name GraphContainer extends PanelContainer

var prompt_scene = preload("uid://bkreq3xdr7gxw")

@export var inspector_panel: InspectorPanel
@onready var graph: MonologueGraphEdit = %GraphEdit

var _selected_nodes: Dictionary = {}  # storyline_id -> InspectableNode
var _is_applying_selection: bool = false
var _current_lang_prop: Property = null  # tracked to disconnect on storyline switch


func _ready() -> void:
	graph.node_view_selected.connect(_on_graph_edit_node_view_selected)
	EventBus.request_node_selection.connect(_on_request_node_selection)
	StorylineManager.storyline_changed.connect(refresh)
	StorylineManager.storyline_switched.connect(_on_storyline_switched)


func refresh() -> void:
	pass


func _on_storyline_switched() -> void:
	var storyline: StorylineDocument = StorylineManager.get_active_storyline()
	graph.storyline_id = storyline.id
	graph.refresh()

	# Disconnect from the previous storyline's languages property
	if is_instance_valid(_current_lang_prop) and _current_lang_prop.value_changed.is_connected(_on_languages_changed):
		_current_lang_prop.value_changed.disconnect(_on_languages_changed)

	# Wire the new storyline's languages property so any add/delete/rename
	# (including via undo/redo) immediately refreshes the LanguageSwitcher.
	_current_lang_prop = storyline.get_property("languages")
	if _current_lang_prop:
		_current_lang_prop.value_changed.connect(_on_languages_changed)
		EventBus.load_languages.emit(storyline.get_property_value("languages"), graph)


func _on_languages_changed(_old: Variant, new_value: Variant) -> void:
	EventBus.load_languages.emit(new_value, graph)


func _on_graph_edit_node_view_selected(node: InspectableNode) -> void:
	request_node_selection(node)


func _on_request_node_selection(
	object: InspectableObject, storyline_id: String, skip_history: bool = false
) -> void:
	if object is not InspectableNode or storyline_id != graph.storyline_id:
		return
	request_node_selection(object, skip_history)


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

	EventBus.request_object_inspection.emit(node)
	_is_applying_selection = false


func _on_add_node_btn_pressed() -> void:
	EventBus.enable_picker_mode.emit("", -1, null, null, null, true)

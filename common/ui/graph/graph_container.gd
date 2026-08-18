## Consists of a TabBar which allows the user to switch between GraphEdits.
## Saving and loading of GraphEdit data is handled by MonologueEditor.
class_name GraphContainer extends PanelContainer

var prompt_scene: PackedScene = preload("uid://bkreq3xdr7gxw")

@export var inspector_panel: InspectorPanel
@onready var graph: MonologueGraphEdit = %GraphEdit
@onready var snap_button: Button = %SnapButton
@onready var grid_button: Button = %GridButton

var _selected_nodes: Dictionary = {}  # storyline_id -> Array[InspectableObject]
var _is_applying_selection: bool = false
var _current_lang_prop: Property = null  # tracked to disconnect on storyline switch


func _ready() -> void:
	graph.selection_changed.connect(_on_graph_selection_changed)
	snap_button.pressed.connect(_on_snap_button_pressed)
	grid_button.pressed.connect(_on_grid_button_pressed)
	snap_button.button_pressed = ConfigManager.get_config("snap")
	grid_button.button_pressed = ConfigManager.get_config("show_grid")
	_on_snap_button_pressed()
	_on_grid_button_pressed()

	EventBus.request_nodes_selection.connect(_on_request_nodes_selection)
	EventBus.request_storyline_inspection.connect(_on_request_storyline_inspection)
	EventBus.graph_snap.connect(_on_event_graph_snap)
	EventBus.graph_show_grid.connect(_on_event_show_grid)

	ProjectManager.project_loaded.connect(_on_project_loaded)


func _on_project_loaded() -> void:
	await get_tree().process_frame

	var storyline: StorylineDocument = ProjectManager.current_project.storylines[0]
	load_storyline(storyline)
	# Nothing else knows which storyline the graph opened on its own, and the explorer
	# has one to highlight.
	EventBus.request_storyline_inspection.emit(storyline)


func load_storyline(storyline: StorylineDocument) -> void:
	graph.storyline_id = storyline.id
	graph.connection_manager = ConnectionManager.new(storyline)
	graph.refresh()

	# Disconnect from the previous storyline's languages property
	if (
		is_instance_valid(_current_lang_prop)
		and _current_lang_prop.value_changed.is_connected(_on_languages_changed)
	):
		_current_lang_prop.value_changed.disconnect(_on_languages_changed)

	_current_lang_prop = storyline.get_property("languages")
	if _current_lang_prop:
		_current_lang_prop.value_changed.connect(_on_languages_changed)
		EventBus.load_languages.emit(storyline.get_property_value("languages"), graph)

	# Restore the previously selected nodes (and inspector) for this storyline
	var selection: Array[InspectableObject] = []
	selection.assign(_selected_nodes.get(storyline.id, []))

	var restored: Array[InspectableObject] = []
	for object: InspectableObject in selection:
		var node: InspectableNode = object as InspectableNode
		if node and is_instance_valid(node) and is_instance_valid(node.graph_view):
			graph.set_selected(node.graph_view)
			restored.append(node)

	EventBus.request_objects_inspection.emit(restored)


func _on_languages_changed(_old: Variant, new_value: Variant) -> void:
	EventBus.load_languages.emit(new_value, graph)


## Hands the whole selection to the inspector. One node is not a special case, just a
## selection of one, so there is nothing here to branch on.
func _on_graph_selection_changed(nodes: Array[InspectableObject]) -> void:
	if _is_applying_selection:
		return

	# Several nodes go straight to the inspector; a single one also records an undo
	# step, so stepping back through the graph works.
	if nodes.size() > 1:
		EventBus.request_objects_inspection.emit(nodes)
		return

	request_node_selection(nodes)


func _on_request_nodes_selection(
	nodes: Array[InspectableObject], storyline_id: String, skip_history: bool = false
) -> void:
	if storyline_id != graph.storyline_id:
		return
	request_node_selection(nodes, skip_history)


func _on_request_storyline_inspection(storyline: StorylineDocument) -> void:
	if graph.storyline_id == storyline.id:
		return

	load_storyline(storyline)


func request_node_selection(nodes: Array[InspectableObject], skip_history: bool = false) -> void:
	if _is_applying_selection:
		return

	var current_nodes: Array[InspectableObject] = []
	current_nodes.assign(_selected_nodes.get(graph.storyline_id, []))

	var needs_selection_update: bool = current_nodes != nodes
	if not needs_selection_update:
		# Same set, but the graph may have lost the highlight -- put it back.
		for object: InspectableObject in nodes:
			var node: InspectableNode = object as InspectableNode
			if node and is_instance_valid(node.graph_view) and not node.graph_view.selected:
				needs_selection_update = true
				break

	if not needs_selection_update and inspector_panel.current_objects == nodes:
		return

	var history: CommandManager = ProjectManager.current_project.command_manager
	if skip_history or not history:
		_apply_selection(nodes, graph.storyline_id)
		return

	history.execute(
		NodeSelectionCommand.new(graph.storyline_id, current_nodes, nodes, _apply_selection)
	)


func _apply_selection(nodes: Array[InspectableObject], storyline_id: String) -> void:
	_is_applying_selection = true

	if nodes.is_empty():
		_selected_nodes.erase(storyline_id)
	else:
		_selected_nodes[storyline_id] = nodes

	# set_selected() deselects everything else, so only the first call may use it; the
	# rest add to the selection.
	var is_first: bool = true
	for object: InspectableObject in nodes:
		var node: InspectableNode = object as InspectableNode
		if not node or not is_instance_valid(node.graph_view):
			continue
		if is_first:
			graph.set_selected(node.graph_view)
			is_first = false
		else:
			node.graph_view.selected = true

	EventBus.request_objects_inspection.emit(nodes)
	_is_applying_selection = false


func _on_add_node_btn_pressed() -> void:
	EventBus.enable_picker_mode.emit("", -1, null, null, null, true)


func _on_snap_button_pressed() -> void:
	graph.snapping_enabled = snap_button.button_pressed
	ConfigManager.set_config("snap", snap_button.button_pressed)


func _on_grid_button_pressed() -> void:
	graph.show_grid = grid_button.button_pressed
	ConfigManager.set_config("show_grid", grid_button.button_pressed)


func _on_event_graph_snap(enabled: bool) -> void:
	graph.snapping_enabled = enabled
	snap_button.button_pressed = enabled


func _on_event_show_grid(grid_visible: bool) -> void:
	graph.show_grid = grid_visible
	grid_button.button_pressed = grid_visible
